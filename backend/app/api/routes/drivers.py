
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
    DriverVerificationUpdate,
)
from app.core.security import hash_password
from app.api.routes.auth import get_current_user, require_roles
from app.core.notifications import create_notification

router = APIRouter(
    prefix="/drivers",
    tags=["Drivers"]
)


# Register a new driver (public registration)
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
        hashed_password=hash_password(data.password),
        is_active=True
    )

    try:
        db.add(new_user)
        db.flush()

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


# Admin only: view all drivers
@router.get("/", response_model=list[DriverResponse])
def get_all_drivers(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN)
    )
):
    return (
        db.query(Driver)
        .order_by(Driver.id.desc())
        .limit(100)
        .all()
    )


# Driver can view own profile; admin can view any profile
@router.get("/{driver_id}", response_model=DriverResponse)
def get_driver(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
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
        current_user.role != UserRole.ADMIN
        and (
            current_user.role != UserRole.DRIVER
            or driver.user_id != current_user.id
        )
    ):
        raise HTTPException(
            status_code=403,
            detail="You can only view your own driver profile"
        )

    return driver


# Driver can update only their own availability
@router.patch("/{driver_id}/availability")
def update_availability(
    driver_id: int,
    data: DriverAvailabilityUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.DRIVER)
    )
):
    driver = db.query(Driver).filter(
        Driver.id == driver_id,
        Driver.user_id == current_user.id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Your driver profile was not found"
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


# Admin only: approve or reject driver
@router.patch("/{driver_id}/verification", response_model=DriverResponse)
def update_driver_verification(
    driver_id: int,
    data: DriverVerificationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN)
    )
):
    driver = db.query(Driver).filter(
        Driver.id == driver_id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    
    driver.verification_status = data.verification_status

    # Pending or rejected drivers must remain offline
    if data.verification_status != VerificationStatus.VERIFIED:
        driver.is_available = False

    if data.verification_status == VerificationStatus.VERIFIED:
        create_notification(
            db=db,
            user_id=driver.user_id,
            title="Driver Account Approved",
            message="Your driver account has been verified. You can now go online.",
            notification_type="driver_approved"
        )

    elif data.verification_status == VerificationStatus.REJECTED:
        create_notification(
            db=db,
            user_id=driver.user_id,
            title="Driver Verification Rejected",
            message="Your driver verification was rejected. Please contact support.",
            notification_type="driver_rejected"
        )

    db.commit()
    db.refresh(driver)

    return driver
