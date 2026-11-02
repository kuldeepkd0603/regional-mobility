
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func
from app.db import get_db
from app.models import (
    User,
    UserRole,
    Agency,
    Driver,
    Vehicle,
    Booking,
    BookingStatus,
    VerificationStatus,)
from app.schemas import (
    AgencyRegistrationCreate,
    AgencyResponse,
    AgencyVerificationUpdate,
)
from app.core.security import hash_password
from app.api.routes.auth import get_current_user, require_roles

from app.models import Driver
from app.schemas import DriverRegistrationCreate
from datetime import datetime, timezone
from app.models import AgencyBookingOffer, AgencyOfferStatus
from app.schemas import AgencyOfferResponse
from app.schemas import AgencyOfferRespond
from app.core.notifications import create_notification
from app.models import (
    Booking,
    BookingStatus,
    Vehicle,
)

from app.schemas import BookingAssignment

from app.api.routes.bookings import check_schedule_conflicts
router = APIRouter(
    prefix="/agencies",
    tags=["Agency Management"]
)


# 1. Agency registration
@router.post(
    "/register",
    response_model=AgencyResponse,
    status_code=201
)
def register_agency(
    data: AgencyRegistrationCreate,
    db: Session = Depends(get_db)
):
    new_user = User(
        full_name=data.full_name,
        phone=data.phone,
        email=data.email,
        role=UserRole.AGENCY,
        hashed_password=hash_password(data.password),
        is_active=True
    )

    try:
        db.add(new_user)
        db.flush()

        new_agency = Agency(
            user_id=new_user.id,
            business_name=data.business_name,
            registration_number=data.registration_number or None,
            business_email=data.business_email,
            business_address=data.business_address,
            city=data.city,
            verification_status=VerificationStatus.PENDING
        )

        db.add(new_agency)
        db.commit()
        db.refresh(new_agency)

        return new_agency

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Phone, email or registration number already exists"
        )


# 2. Agency views own profile
@router.get(
    "/me",
    response_model=AgencyResponse
)
def get_my_agency(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.AGENCY)
    )
):
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(
            status_code=404,
            detail="Agency profile not found"
        )

    return agency


# 3. Admin views all agencies
@router.get(
    "/",
    response_model=list[AgencyResponse]
)
def get_all_agencies(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN)
    )
):
    return (
        db.query(Agency)
        .order_by(Agency.id.desc())
        .limit(100)
        .all()
    )


# 4. Admin approves or rejects agency
@router.patch(
    "/{agency_id}/verification",
    response_model=AgencyResponse
)
def update_agency_verification(
    agency_id: int,
    data: AgencyVerificationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN)
    )
):
    agency = db.query(Agency).filter(
        Agency.id == agency_id
    ).first()

    if not agency:
        raise HTTPException(
            status_code=404,
            detail="Agency not found"
        )

    agency.verification_status = data.verification_status

    db.commit()
    db.refresh(agency)

    return agency

@router.post("/drivers", status_code=201)
def add_agency_driver(
    data: DriverRegistrationCreate,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles(UserRole.AGENCY))
):
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency profile not found")

    if agency.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(403, "Agency must be verified before adding drivers")

    existing_user = db.query(User).filter(
        User.phone == data.phone
    ).first()

    if existing_user:
        raise HTTPException(409, "Phone number is already registered")

    existing_license = db.query(Driver).filter(
        Driver.license_number == data.license_number
    ).first()

    if existing_license:
        raise HTTPException(409, "Driving license is already registered")

    try:
        new_user = User(
            full_name=data.full_name,
            phone=data.phone,
            email=data.email,
            role=UserRole.DRIVER,
            hashed_password=hash_password(data.password),
            is_active=True
        )

        db.add(new_user)
        db.flush()

        new_driver = Driver(
            user_id=new_user.id,
            license_number=data.license_number,
            agency_id=agency.id,
            verification_status=VerificationStatus.PENDING,
            is_available=False
        )

        db.add(new_driver)
        db.commit()
        db.refresh(new_driver)

        return {
            "message": "Driver registered successfully",
            "driver_id": new_driver.id,
            "agency_id": agency.id,
            "verification_status": new_driver.verification_status
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Driver details already exist")


@router.get("/drivers")
def get_agency_drivers(
    db: Session = Depends(get_db),
    current_user=Depends(require_roles(UserRole.AGENCY))
):
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency profile not found")

    drivers = db.query(Driver).filter(
        Driver.agency_id == agency.id
    ).all()

    return drivers


@router.get("/drivers/{driver_id}")
def get_agency_driver(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles(UserRole.AGENCY))
):
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency profile not found")

    driver = db.query(Driver).filter(
        Driver.id == driver_id,
        Driver.agency_id == agency.id
    ).first()

    if not driver:
        raise HTTPException(404, "Driver not found in your agency")

    return driver



@router.get("/dashboard")
def get_agency_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.AGENCY)
    )
):
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency profile not found")

    # Driver statistics
    driver_query = db.query(Driver).filter(
        Driver.agency_id == agency.id
    )

    total_drivers = driver_query.count()

    verified_drivers = driver_query.filter(
        Driver.verification_status == VerificationStatus.VERIFIED
    ).count()

    pending_drivers = driver_query.filter(
        Driver.verification_status == VerificationStatus.PENDING
    ).count()

    rejected_drivers = driver_query.filter(
        Driver.verification_status == VerificationStatus.REJECTED
    ).count()

    # Vehicle statistics
    vehicle_query = db.query(Vehicle).join(
        Driver,
        Vehicle.driver_id == Driver.id
    ).filter(
        Driver.agency_id == agency.id
    )

    total_vehicles = vehicle_query.count()

    active_vehicles = vehicle_query.filter(
        Vehicle.is_active.is_(True)
    ).count()

    # Booking statistics: bookings assigned to this agency's drivers
    booking_query = db.query(Booking).join(
        Driver,
        Booking.driver_id == Driver.id
    ).filter(
        Driver.agency_id == agency.id
    )

    total_bookings = booking_query.count()

    pending_bookings = booking_query.filter(
        Booking.booking_status == BookingStatus.PENDING
    ).count()

    ongoing_bookings = booking_query.filter(
        Booking.booking_status == BookingStatus.ONGOING
    ).count()

    completed_bookings = booking_query.filter(
        Booking.booking_status == BookingStatus.COMPLETED
    ).count()

    cancelled_bookings = booking_query.filter(
        Booking.booking_status == BookingStatus.CANCELLED
    ).count()

    # Earnings from completed trips
    total_earnings = (
        booking_query.filter(
            Booking.booking_status == BookingStatus.COMPLETED
        ).with_entities(
            func.coalesce(func.sum(Booking.final_fare), 0)
        ).scalar()
    )

    return {
        "agency": {
            "id": agency.id,
            "business_name": agency.business_name,
            "city": agency.city,
            "verification_status": agency.verification_status.value
        },
        "drivers": {
            "total": total_drivers,
            "verified": verified_drivers,
            "pending": pending_drivers,
            "rejected": rejected_drivers
        },
        "vehicles": {
            "total": total_vehicles,
            "active": active_vehicles
        },
        "bookings": {
            "total": total_bookings,
            "pending": pending_bookings,
            "ongoing": ongoing_bookings,
            "completed": completed_bookings,
            "cancelled": cancelled_bookings
        },
        "earnings": {
            "total": float(total_earnings or 0),
            "currency": "INR"
        }
    }


# =====================================
# AGENCY VIEWS RECEIVED BOOKING OFFERS
# =====================================

@router.get(
    "/offers",
    response_model=list[AgencyOfferResponse]
)
def get_agency_offers(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.AGENCY)
    )
):
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(
            404,
            "Agency profile not found"
        )

    offers = (
        db.query(AgencyBookingOffer)
        .filter(
            AgencyBookingOffer.agency_id == agency.id
        )
        .order_by(
            AgencyBookingOffer.offered_at.desc()
        )
        .limit(100)
        .all()
    )

    return offers


# =====================================
# AGENCY ACCEPTS OR REJECTS AN OFFER
# =====================================

@router.patch(
    "/offers/{offer_id}/respond",
    response_model=AgencyOfferResponse
)
def respond_to_agency_offer(
    offer_id: int,
    data: AgencyOfferRespond,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.AGENCY)
    )
):
    # Find agency
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency not found")

    if agency.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(
            403,
            "Only verified agencies can respond to offers"
        )

    # Only ACCEPTED or REJECTED are valid responses
    if data.status not in (
        AgencyOfferStatus.ACCEPTED,
        AgencyOfferStatus.REJECTED
    ):
        raise HTTPException(
            400,
            "You can only accept or reject an offer"
        )

    # Lock offer
    offer = (
        db.query(AgencyBookingOffer)
        .filter(
            AgencyBookingOffer.id == offer_id,
            AgencyBookingOffer.agency_id == agency.id
        )
        .with_for_update()
        .first()
    )

    if not offer:
        raise HTTPException(
            404,
            "Offer not found for your agency"
        )

    if offer.status != AgencyOfferStatus.PENDING:
        raise HTTPException(
            409,
            "This offer has already been responded to"
        )

    booking = db.query(Booking).filter(
        Booking.id == offer.booking_id
    ).first()

    if not booking or booking.booking_status != BookingStatus.PENDING:
        raise HTTPException(
            409,
            "This booking is no longer available"
        )

    try:
        offer.status = data.status
        offer.responded_at = datetime.now(timezone.utc)

        # Notify active administrators
        admins = db.query(User).filter(
            User.role == UserRole.ADMIN,
            User.is_active.is_(True)
        ).all()

        for admin in admins:
            create_notification(
                db=db,
                user_id=admin.id,
                title="Agency Booking Response",
                message=(
                    f"Agency {agency.business_name} "
                    f"{data.status.value} offer for booking "
                    f"#{booking.id}"
                ),
                notification_type="agency_offer_response",
                booking_id=booking.id
            )

        db.commit()
        db.refresh(offer)

        return offer

    except Exception:
        db.rollback()
        raise


# =====================================
# AGENCY ASSIGNS DRIVER AND VEHICLE
# =====================================

@router.post("/offers/{offer_id}/assign")
def agency_assign_driver(
    offer_id: int,
    data: BookingAssignment,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.AGENCY)
    )
):
    # Find agency
    agency = db.query(Agency).filter(
        Agency.user_id == current_user.id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency not found")

    if agency.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(403, "Agency is not verified")

    # Lock accepted offer
    offer = (
        db.query(AgencyBookingOffer)
        .filter(
            AgencyBookingOffer.id == offer_id,
            AgencyBookingOffer.agency_id == agency.id
        )
        .with_for_update()
        .first()
    )

    if not offer:
        raise HTTPException(404, "Agency offer not found")

    if offer.status != AgencyOfferStatus.ACCEPTED:
        raise HTTPException(
            409,
            "Only accepted offers can be assigned"
        )

    # Lock booking
    booking = (
        db.query(Booking)
        .filter(Booking.id == offer.booking_id)
        .with_for_update()
        .first()
    )

    if not booking:
        raise HTTPException(404, "Booking not found")

    if booking.booking_status != BookingStatus.PENDING:
        raise HTTPException(
            409,
            "Booking is no longer available for assignment"
        )

    if not booking.scheduled_at:
        raise HTTPException(
            409,
            "Booking pickup date and time are required"
        )

    # Find driver belonging to this agency
    driver = (
        db.query(Driver)
        .filter(
            Driver.id == data.driver_id,
            Driver.agency_id == agency.id
        )
        .with_for_update()
        .first()
    )

    if not driver:
        raise HTTPException(
            404,
            "Driver does not belong to your agency"
        )

    driver_user = db.get(User, driver.user_id)

    if not driver_user or not driver_user.is_active:
        raise HTTPException(403, "Driver account is inactive")

    if driver.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(403, "Driver is not verified")

    if not driver.is_available:
        raise HTTPException(409, "Driver is unavailable")

    # Find active vehicle belonging to this driver
    vehicle = (
        db.query(Vehicle)
        .filter(
            Vehicle.id == data.vehicle_id,
            Vehicle.driver_id == driver.id,
            Vehicle.is_active.is_(True)
        )
        .with_for_update()
        .first()
    )

    if not vehicle:
        raise HTTPException(
            400,
            "Vehicle is inactive or does not belong to this driver"
        )

    if vehicle.seating_capacity < booking.passenger_count:
        raise HTTPException(
            400,
            "Vehicle does not have enough passenger capacity"
        )

    # Check existing schedule conflicts
    check_schedule_conflicts(
        db=db,
        booking=booking,
        driver_id=driver.id,
        vehicle_id=vehicle.id
    )

    # Assign driver and vehicle
    booking.driver_id = driver.id
    booking.vehicle_id = vehicle.id
    booking.booking_status = BookingStatus.DRIVER_ASSIGNED

    # Notify passenger
    create_notification(
        db=db,
        user_id=booking.passenger_id,
        title="Driver Assigned",
        message=(
            f"Your booking #{booking.id} has been assigned "
            f"to driver {driver_user.full_name}"
        ),
        notification_type="driver_assigned",
        booking_id=booking.id
    )

    # Notify driver
    create_notification(
        db=db,
        user_id=driver.user_id,
        title="New Trip Assigned",
        message=f"You have been assigned booking #{booking.id}",
        notification_type="trip_assigned",
        booking_id=booking.id
    )

    try:
        db.commit()
        db.refresh(booking)

        return {
            "message": "Driver assigned successfully",
            "booking_id": booking.id,
            "offer_id": offer.id,
            "driver_id": driver.id,
            "vehicle_id": vehicle.id,
            "booking_status": booking.booking_status.value
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409,
            "Booking assignment conflict"
        )
