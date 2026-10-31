
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.db import get_db
from app.models import Vehicle, Driver, VerificationStatus
from app.schemas import VehicleCreate, VehicleUpdate, VehicleResponse

router = APIRouter(
    prefix="/vehicles",
    tags=["Vehicles"]
)


# Register a vehicle
@router.post("/", response_model=VehicleResponse, status_code=201)
def create_vehicle(
    data: VehicleCreate,
    db: Session = Depends(get_db)
):
    driver = db.query(Driver).filter(
        Driver.id == data.driver_id
    ).first()

    if not driver:
        raise HTTPException(404, "Driver not found")

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


# Get all vehicles
@router.get("/", response_model=list[VehicleResponse])
def get_vehicles(db: Session = Depends(get_db)):
    return (
        db.query(Vehicle)
        .order_by(Vehicle.id.desc())
        .limit(100)
        .all()
    )


# Get a vehicle by ID
@router.get("/{vehicle_id}", response_model=VehicleResponse)
def get_vehicle(
    vehicle_id: int,
    db: Session = Depends(get_db)
):
    vehicle = db.query(Vehicle).filter(
        Vehicle.id == vehicle_id
    ).first()

    if not vehicle:
        raise HTTPException(404, "Vehicle not found")

    return vehicle


# Update vehicle
@router.patch("/{vehicle_id}", response_model=VehicleResponse)
def update_vehicle(
    vehicle_id: int,
    data: VehicleUpdate,
    db: Session = Depends(get_db)
):
    vehicle = db.query(Vehicle).filter(
        Vehicle.id == vehicle_id
    ).first()

    if not vehicle:
        raise HTTPException(404, "Vehicle not found")

    updates = data.model_dump(exclude_unset=True)

    for key, value in updates.items():
        setattr(vehicle, key, value)

    db.commit()
    db.refresh(vehicle)

    return vehicle
