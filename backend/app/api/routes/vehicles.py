
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.db import get_db
from app.models import (
    Vehicle,
    Driver,
    User,
    Agency,
    UserRole,
    VerificationStatus,
)
from app.schemas import (
    VehicleCreate,
    VehicleUpdate,
    VehicleResponse,
)
from app.api.routes.auth import get_current_user, require_roles


router = APIRouter(
    prefix="/vehicles",
    tags=["Vehicles"]
)


def get_verified_agency(db: Session, user_id: int):
    agency = db.query(Agency).filter(
        Agency.user_id == user_id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency profile not found")

    if agency.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(
            403,
            "Agency must be verified before managing vehicles"
        )

    return agency


# Register a vehicle
@router.post("/", response_model=VehicleResponse, status_code=201)
def create_vehicle(
    data: VehicleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.DRIVER, UserRole.AGENCY, UserRole.ADMIN)
    )
):
    driver = db.query(Driver).filter(
        Driver.id == data.driver_id
    ).first()

    if not driver:
        raise HTTPException(404, "Driver not found")

    # Driver can register only under their own profile.
    if current_user.role == UserRole.DRIVER:
        if driver.user_id != current_user.id:
            raise HTTPException(
                403,
                "You can only register vehicles under your own profile"
            )

    # Agency can register vehicles only for its own drivers.
    elif current_user.role == UserRole.AGENCY:
        agency = get_verified_agency(db, current_user.id)

        if driver.agency_id != agency.id:
            raise HTTPException(
                403,
                "You can only register vehicles for your agency drivers"
            )

    driver_user = db.query(User).filter(
        User.id == driver.user_id
    ).first()

    if not driver_user or not driver_user.is_active:
        raise HTTPException(403, "Driver account is inactive")

    if driver.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(
            403,
            "Only verified drivers can register vehicles"
        )

    vehicle = Vehicle(**data.model_dump())

    try:
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        return vehicle

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409,
            "Vehicle registration number already exists"
        )


# Admin: all vehicles | Agency: its own vehicles
@router.get("/", response_model=list[VehicleResponse])
def get_vehicles(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN, UserRole.AGENCY)
    )
):
    query = db.query(Vehicle)

    if current_user.role == UserRole.AGENCY:
        agency = get_verified_agency(db, current_user.id)

        query = query.join(
            Driver,
            Vehicle.driver_id == Driver.id
        ).filter(
            Driver.agency_id == agency.id
        )

    return query.order_by(
        Vehicle.id.desc()
    ).limit(100).all()


# Get vehicle details: Owner driver, agency or admin
@router.get("/{vehicle_id}", response_model=VehicleResponse)
def get_vehicle(
    vehicle_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    vehicle = db.query(Vehicle).filter(
        Vehicle.id == vehicle_id
    ).first()

    if not vehicle:
        raise HTTPException(404, "Vehicle not found")

    driver = db.query(Driver).filter(
        Driver.id == vehicle.driver_id
    ).first()

    if current_user.role == UserRole.ADMIN:
        return vehicle

    if current_user.role == UserRole.DRIVER:
        if not driver or driver.user_id != current_user.id:
            raise HTTPException(
                403,
                "You can only view your own vehicles"
            )

    elif current_user.role == UserRole.AGENCY:
        agency = get_verified_agency(db, current_user.id)

        if not driver or driver.agency_id != agency.id:
            raise HTTPException(
                403,
                "You can only view your agency vehicles"
            )

    else:
        raise HTTPException(
            403,
            "You do not have permission to view this vehicle"
        )

    return vehicle


# Update vehicle: Owner driver, agency or admin
@router.patch("/{vehicle_id}", response_model=VehicleResponse)
def update_vehicle(
    vehicle_id: int,
    data: VehicleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.DRIVER, UserRole.AGENCY, UserRole.ADMIN)
    )
):
    vehicle = db.query(Vehicle).filter(
        Vehicle.id == vehicle_id
    ).first()

    if not vehicle:
        raise HTTPException(404, "Vehicle not found")

    driver = db.query(Driver).filter(
        Driver.id == vehicle.driver_id
    ).first()

    if current_user.role == UserRole.DRIVER:
        if not driver or driver.user_id != current_user.id:
            raise HTTPException(
                403,
                "You can only update your own vehicles"
            )

        if driver.verification_status != VerificationStatus.VERIFIED:
            raise HTTPException(
                403,
                "Only verified drivers can update vehicles"
            )

    elif current_user.role == UserRole.AGENCY:
        agency = get_verified_agency(db, current_user.id)

        if not driver or driver.agency_id != agency.id:
            raise HTTPException(
                403,
                "You can only update your agency vehicles"
            )

    updates = data.model_dump(exclude_unset=True)

    # Prevent changing a vehicle's driver through this endpoint.
    if "driver_id" in updates:
        raise HTTPException(
            400,
            "Vehicle driver cannot be changed through this endpoint"
        )

    for key, value in updates.items():
        setattr(vehicle, key, value)

    try:
        db.commit()
        db.refresh(vehicle)
        return vehicle

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409,
            "Vehicle update conflicts with existing data"
        )
