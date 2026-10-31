
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.db import get_db
from app.models import (
    User,
    Driver,
    UserRole,
    VerificationStatus,
)
from app.schemas import (
    DriverRegistrationCreate,
    DriverResponse,
    DriverAvailabilityUpdate,
)

router = APIRouter(
    prefix="/drivers",
    tags=["Drivers"]
)


# Register a new driver
@router.post("/register", response_model=DriverResponse, status_code=201)
def register_driver(
    data: DriverRegistrationCreate,
    db: Session = Depends(get_db)
):
    new_user = User(
        full_name=data.full_name,
        phone=data.phone,
        email=data.email,
        role=UserRole.DRIVER,
        is_active=True
    )

    try:
        db.add(new_user)
        db.flush()  # Get the new user ID without committing

        new_driver = Driver(
            user_id=new_user.id,
            license_number=data.license_number,
            verification_status=VerificationStatus.PENDING,
            rating=5.0,
            is_available=False
        )

        db.add(new_driver)
        db.commit()
        db.refresh(new_driver)

        return new_driver

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Phone, email or licence number already exists"
        )


# Get all drivers
@router.get("/", response_model=list[DriverResponse])
def get_all_drivers(db: Session = Depends(get_db)):
    return (
        db.query(Driver)
        .order_by(Driver.id.desc())
        .limit(100)
        .all()
    )


# Get one driver
@router.get("/{driver_id}", response_model=DriverResponse)
def get_driver(
    driver_id: int,
    db: Session = Depends(get_db)
):
    driver = db.query(Driver).filter(
        Driver.id == driver_id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    return driver


# Update driver availability
@router.patch("/{driver_id}/availability")
def update_availability(
    driver_id: int,
    data: DriverAvailabilityUpdate,
    db: Session = Depends(get_db)
):
    driver = db.query(Driver).filter(
        Driver.id == driver_id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    if (
        data.is_available
        and driver.verification_status != VerificationStatus.VERIFIED
    ):
        raise HTTPException(
            status_code=403,
            detail="Driver must be verified before going online"
        )

    driver.is_available = data.is_available

    db.commit()
    db.refresh(driver)

    return {
        "message": "Driver availability updated",
        "is_available": driver.is_available
    }
