
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
from sqlalchemy import or_
from app.db import get_db
from app.core.notifications import create_notification

from app.models import (
    User,
    UserRole,
    Driver,
    Vehicle,
    RideRoute,
    Booking,
    BookingStatus,
    TripType,
    VerificationStatus,
    Agency,
    AgencyBookingOffer,
    AgencyOfferStatus,
)

from app.schemas import (
    BookingCreate,
    BookingResponse,
    BookingAssignment,
    BookingStatusUpdate,
    AgencyOfferCreate,
    AgencyOfferResponse,
)

from app.api.routes.auth import (
    get_current_user,
    require_roles,
)


router = APIRouter(
    prefix="/bookings",
    tags=["Bookings"]
)


# TEMPORARY DEVELOPMENT PRICING
BASE_FARE_INR = 100.0
PER_KM_RATE_INR = 12.0


def calculate_fare(
    distance_km: float,
    trip_type: TripType
) -> float:

    distance = distance_km

    if trip_type == TripType.ROUND_TRIP:
        distance *= 2

    fare = BASE_FARE_INR + (
        distance * PER_KM_RATE_INR
    )

    return round(fare, 2)



# =====================================
# BOOKING SCHEDULE MANAGEMENT
# =====================================

INDIA_TIMEZONE = ZoneInfo("Asia/Kolkata")

BUFFER_MINUTES = 60

AVERAGE_SPEED_KMPH = {
    TripType.LOCAL: 25,
    TripType.INTERCITY: 40,
    TripType.RELIGIOUS_TOUR: 30,
}

ACTIVE_BOOKING_STATUSES = [
    BookingStatus.ACCEPTED,
    BookingStatus.DRIVER_ASSIGNED,
    BookingStatus.ONGOING,
]


def normalize_datetime(value: datetime) -> datetime:
    """
    Treat timezone-naive booking times as India local time.
    Store timezone-aware values.
    """
    if value.tzinfo is None or value.utcoffset() is None:
        return value.replace(tzinfo=INDIA_TIMEZONE)

    return value


def get_booking_window(booking, route):
    """
    Calculate the occupied time window for a booking.

    Round trips use return_at.
    One-way trips use estimated duration plus buffer.
    Ongoing trips block further assignments until completed.
    """

    if not booking.scheduled_at:
        raise HTTPException(
            status_code=409,
            detail="Booking pickup date and time are required for assignment"
        )

    start_time = normalize_datetime(booking.scheduled_at)

    # An ongoing trip is treated as busy until it is completed.
    if booking.booking_status == BookingStatus.ONGOING:
        return (
            start_time,
            datetime.max.replace(tzinfo=timezone.utc)
        )

    # Round-trip booking
    if booking.trip_type == TripType.ROUND_TRIP:

        if not booking.return_at:
            raise HTTPException(
                status_code=409,
                detail="Round-trip booking is missing its return time"
            )

        end_time = normalize_datetime(booking.return_at)

        if end_time <= start_time:
            raise HTTPException(
                status_code=409,
                detail="Invalid round-trip schedule"
            )

        return start_time, end_time

    # One-way booking duration estimation
    if not route or not route.distance_km or route.distance_km <= 0:
        raise HTTPException(
            status_code=409,
            detail="Valid route distance is required for scheduling"
        )

    average_speed = AVERAGE_SPEED_KMPH.get(booking.trip_type)

    if not average_speed:
        raise HTTPException(
            status_code=409,
            detail="Unable to estimate this trip duration"
        )

    estimated_hours = route.distance_km / average_speed

    duration = (
        timedelta(hours=estimated_hours)
        + timedelta(minutes=BUFFER_MINUTES)
    )

    end_time = start_time + duration

    return start_time, end_time


def check_schedule_conflicts(
    db: Session,
    booking: Booking,
    driver_id: int,
    vehicle_id: int
):
    """
    Reject overlapping bookings for the same driver or vehicle.
    """

    new_route = db.get(RideRoute, booking.route_id)

    new_start, new_end = get_booking_window(
        booking,
        new_route
    )

    existing_bookings = (
        db.query(Booking)
        .filter(
            Booking.id != booking.id,
            Booking.booking_status.in_(
                ACTIVE_BOOKING_STATUSES
            ),
            or_(
                Booking.driver_id == driver_id,
                Booking.vehicle_id == vehicle_id
            )
        )
        .with_for_update()
        .all()
    )

    for existing in existing_bookings:

        existing_route = db.get(
            RideRoute,
            existing.route_id
        )

        existing_start, existing_end = get_booking_window(
            existing,
            existing_route
        )

        # Standard interval overlap check
        if (
            existing_start < new_end
            and existing_end > new_start
        ):

            if existing.driver_id == driver_id:
                detail = (
                    f"Driver already has an overlapping booking "
                    f"(Booking ID: {existing.id})"
                )
            else:
                detail = (
                    f"Vehicle already has an overlapping booking "
                    f"(Booking ID: {existing.id})"
                )

            raise HTTPException(
                status_code=409,
                detail=detail
            )


# =====================================
# 1. CREATE BOOKING
# =====================================

@router.post(
    "/",
    response_model=BookingResponse,
    status_code=201
)
def create_booking(
    data: BookingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    # Only passengers can create bookings
    if current_user.role != UserRole.PASSENGER:
        raise HTTPException(
            status_code=403,
            detail="Only passengers can create bookings"
        )

    # Prevent creating bookings for another passenger
    if data.passenger_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You cannot create a booking for another passenger"
        )

    passenger = db.query(User).filter(
        User.id == current_user.id,
        User.role == UserRole.PASSENGER,
        User.is_active.is_(True)
    ).first()

    if not passenger:
        raise HTTPException(
            status_code=404,
            detail="Active passenger not found"
        )

    try:

        route = RideRoute(
            pickup_city=data.pickup_city,
            drop_city=data.drop_city,
            pickup_address=data.pickup_address,
            drop_address=data.drop_address,
            distance_km=data.distance_km,
        )

        db.add(route)
        db.flush()

        booking = Booking(
            passenger_id=current_user.id,
            route_id=route.id,
            trip_type=data.trip_type,
            scheduled_at=normalize_datetime(data.scheduled_at),
            return_at=(
                normalize_datetime(data.return_at)
                if data.return_at
                else None
            ),
            passenger_count=data.passenger_count,
            special_instructions=data.special_instructions,
            estimated_fare=calculate_fare(
                data.distance_km,
                data.trip_type
            ),
            booking_status=BookingStatus.PENDING,
        )

        db.add(booking)
        db.flush()

        # Notify all active administrators
        admins = db.query(User).filter(
            User.role == UserRole.ADMIN,
            User.is_active.is_(True)
        ).all()

        for admin in admins:
            create_notification(
                db=db,
                user_id=admin.id,
                title="New Booking Received",
                message=(
                    f"New booking #{booking.id} "
                    f"from {data.pickup_city} to {data.drop_city}"
                ),
                notification_type="new_booking",
                booking_id=booking.id
            )

        db.commit()
        db.refresh(booking)

        return booking

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Unable to create booking due to a database conflict"
        )

    except Exception:
        db.rollback()
        raise


# =====================================
# 2. GET BOOKINGS
# =====================================

@router.get(
    "/",
    response_model=list[BookingResponse]
)
def get_bookings(
    passenger_id: int | None = Query(default=None),
    driver_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    query = db.query(Booking)

    # Passenger can only see their own bookings
    if current_user.role == UserRole.PASSENGER:

        if passenger_id is not None and passenger_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot access another passenger's bookings"
            )

        if driver_id is not None:
            raise HTTPException(
                status_code=403,
                detail="Passenger cannot filter bookings by driver"
            )

        query = query.filter(
            Booking.passenger_id == current_user.id
        )

    # Driver can only see assigned bookings
    elif current_user.role == UserRole.DRIVER:

        if passenger_id is not None or driver_id is not None:
            raise HTTPException(
                status_code=403,
                detail="Drivers cannot use these booking filters"
            )

        driver = db.query(Driver).filter(
            Driver.user_id == current_user.id
        ).first()

        if not driver:
            raise HTTPException(
                status_code=404,
                detail="Driver profile not found"
            )

        query = query.filter(
            Booking.driver_id == driver.id
        )

    # Admin can view all bookings
    elif current_user.role == UserRole.ADMIN:

        if passenger_id is not None:
            query = query.filter(
                Booking.passenger_id == passenger_id
            )

        if driver_id is not None:
            query = query.filter(
                Booking.driver_id == driver_id
            )
            
        # Agency can view bookings assigned to its own drivers
    elif current_user.role == UserRole.AGENCY:

        if passenger_id is not None or driver_id is not None:
            raise HTTPException(
                status_code=403,
                detail="Agency cannot use these booking filters"
            )

        query = query.join(
            Driver,
            Booking.driver_id == Driver.id
        ).filter(
            Driver.agency_id == (
                db.query(Agency.id)
                .filter(Agency.user_id == current_user.id)
                .scalar_subquery()
            )
        )
        
        # Agency can view only its own drivers' bookings
    elif current_user.role == UserRole.AGENCY:

        driver = db.query(Driver).filter(
            Driver.id == booking.driver_id,
            Driver.agency_id == (
                db.query(Agency.id)
                .filter(Agency.user_id == current_user.id)
                .scalar_subquery()
            )
        ).first()

        if not driver:
            raise HTTPException(
                status_code=403,
                detail="This booking does not belong to your agency"
            )

    else:
        raise HTTPException(
            status_code=403,
            detail="You are not authorized to view bookings"
        )
        

    return query.order_by(
        Booking.id.desc()
    ).limit(100).all()


# =====================================
# 3. GET BOOKING BY ID
# =====================================

@router.get(
    "/{booking_id}",
    response_model=BookingResponse
)
def get_booking(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    booking = db.query(Booking).filter(
        Booking.id == booking_id
    ).first()

    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Booking not found"
        )

    # Passenger access check
    if current_user.role == UserRole.PASSENGER:

        if booking.passenger_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot access this booking"
            )

    # Driver access check
    elif current_user.role == UserRole.DRIVER:

        driver = db.query(Driver).filter(
            Driver.user_id == current_user.id
        ).first()

        if not driver or booking.driver_id != driver.id:
            raise HTTPException(
                status_code=403,
                detail="This booking is not assigned to you"
            )

    elif current_user.role != UserRole.ADMIN:

        raise HTTPException(
            status_code=403,
            detail="Access denied"
        )

    return booking


# =====================================
# 4. ASSIGN DRIVER AND VEHICLE
# ADMIN ONLY
# =====================================



@router.patch(
    "/{booking_id}/assign",
    response_model=BookingResponse
)
def assign_driver(
    booking_id: int,
    data: BookingAssignment,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN)
    )
):
    # Lock booking
    booking = (
        db.query(Booking)
        .filter(Booking.id == booking_id)
        .with_for_update()
        .first()
    )

    if not booking:
        raise HTTPException(404, "Booking not found")

    if booking.booking_status != BookingStatus.PENDING:
        raise HTTPException(
            409,
            "Only pending bookings can be assigned"
        )

    if not booking.scheduled_at:
        raise HTTPException(
            409,
            "Booking pickup date and time are required"
        )

    # Lock driver
    driver = (
        db.query(Driver)
        .filter(Driver.id == data.driver_id)
        .with_for_update()
        .first()
    )

    if not driver:
        raise HTTPException(404, "Driver not found")

    driver_user = db.get(User, driver.user_id)

    if not driver_user or not driver_user.is_active:
        raise HTTPException(403, "Driver account is inactive")

    if driver.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(403, "Driver is not verified")

    if not driver.is_available:
        raise HTTPException(
            409,
            "Driver is offline or unavailable"
        )

    # Lock vehicle
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

    # Check schedule conflicts
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
        return booking

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409,
            "Booking assignment conflict"
        )

# =====================================
# 5. UPDATE BOOKING STATUS
# =====================================

@router.patch(
    "/{booking_id}/status",
    response_model=BookingResponse
)
def update_booking_status(
    booking_id: int,
    data: BookingStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    booking = db.query(Booking).filter(
        Booking.id == booking_id
    ).with_for_update().first()

    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Booking not found"
        )

    # PASSENGER PERMISSIONS
    if current_user.role == UserRole.PASSENGER:

        if booking.passenger_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="You cannot update this booking"
            )

        if data.booking_status != BookingStatus.CANCELLED:
            raise HTTPException(
                status_code=403,
                detail="Passengers can only cancel bookings"
            )

        if booking.booking_status != BookingStatus.PENDING:
            raise HTTPException(
                status_code=400,
                detail="Passenger can only cancel pending bookings"
            )

    # DRIVER PERMISSIONS
    elif current_user.role == UserRole.DRIVER:

        driver = db.query(Driver).filter(
            Driver.user_id == current_user.id
        ).first()

        if not driver or booking.driver_id != driver.id:
            raise HTTPException(
                status_code=403,
                detail="This booking is not assigned to you"
            )

        allowed_driver_actions = {
            BookingStatus.ONGOING,
            BookingStatus.COMPLETED,
            BookingStatus.CANCELLED,
        }

        if data.booking_status not in allowed_driver_actions:
            raise HTTPException(
                status_code=403,
                detail="Driver is not allowed to perform this action"
            )

    # ADMIN PERMISSIONS
    elif current_user.role != UserRole.ADMIN:

        raise HTTPException(
            status_code=403,
            detail="You are not authorized to update bookings"
        )

    # VALIDATE BOOKING STATUS TRANSITIONS
    allowed_transitions = {

        BookingStatus.PENDING: {
            BookingStatus.CANCELLED,
        },

        BookingStatus.DRIVER_ASSIGNED: {
            BookingStatus.ONGOING,
            BookingStatus.CANCELLED,
        },

        BookingStatus.ONGOING: {
            BookingStatus.COMPLETED,
        },

    }

    if data.booking_status not in allowed_transitions.get(
        booking.booking_status, set()
    ):
        raise HTTPException(
            status_code=409,
            detail=(
                f"Cannot change booking from "
                f"{booking.booking_status.value} to "
                f"{data.booking_status.value}"
            )
        )

    booking.booking_status = data.booking_status

    # Send notification when booking is cancelled
    if data.booking_status == BookingStatus.CANCELLED:

        # If driver cancels, notify passenger
        if current_user.role == UserRole.DRIVER:
            create_notification(
                db=db,
                user_id=booking.passenger_id,
                title="Booking Cancelled",
                message=f"Driver has cancelled booking #{booking.id}.",
                notification_type="booking_cancelled",
                booking_id=booking.id
            )

        # If admin cancels, notify passenger and assigned driver
        elif current_user.role == UserRole.ADMIN:

            create_notification(
                db=db,
                user_id=booking.passenger_id,
                title="Booking Cancelled",
                message=f"Your booking #{booking.id} has been cancelled.",
                notification_type="booking_cancelled",
                booking_id=booking.id
            )

            if booking.driver_id:
                driver = db.get(Driver, booking.driver_id)

                if driver:
                    create_notification(
                        db=db,
                        user_id=driver.user_id,
                        title="Booking Cancelled",
                        message=f"Booking #{booking.id} has been cancelled.",
                        notification_type="booking_cancelled",
                        booking_id=booking.id
                    )

    db.commit()
    db.refresh(booking)

    return booking


# =====================================
# ADMIN OFFERS BOOKING TO AN AGENCY
# =====================================

@router.post(
    "/{booking_id}/offer",
    response_model=AgencyOfferResponse,
    status_code=201
)
def offer_booking_to_agency(
    booking_id: int,
    data: AgencyOfferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN)
    )
):
    # Find and lock booking
    booking = (
        db.query(Booking)
        .filter(Booking.id == booking_id)
        .with_for_update()
        .first()
    )

    if not booking:
        raise HTTPException(404, "Booking not found")

    if booking.booking_status != BookingStatus.PENDING:
        raise HTTPException(
            409,
            "Only pending bookings can be offered to agencies"
        )

    if booking.driver_id is not None:
        raise HTTPException(
            409,
            "Booking already has an assigned driver"
        )

    # Find agency
    agency = db.query(Agency).filter(
        Agency.id == data.agency_id
    ).first()

    if not agency:
        raise HTTPException(404, "Agency not found")

    if agency.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(
            403,
            "Only verified agencies can receive booking offers"
        )

    agency_user = db.query(User).filter(
        User.id == agency.user_id,
        User.is_active.is_(True)
    ).first()

    if not agency_user:
        raise HTTPException(
            403,
            "Agency account is inactive"
        )

    # Prevent another active offer for this booking
    existing_offer = db.query(AgencyBookingOffer).filter(
        AgencyBookingOffer.booking_id == booking_id,
        AgencyBookingOffer.status.in_([
            AgencyOfferStatus.PENDING,
            AgencyOfferStatus.ACCEPTED
        ])
    ).first()

    if existing_offer:
        raise HTTPException(
            409,
            "This booking already has an active agency offer"
        )

    # Create offer
    offer = AgencyBookingOffer(
        booking_id=booking.id,
        agency_id=agency.id,
        status=AgencyOfferStatus.PENDING
    )

    try:
        db.add(offer)
        db.flush()

        # Notify agency
        create_notification(
            db=db,
            user_id=agency_user.id,
            title="New Booking Offer",
            message=(
                f"Booking #{booking.id} is available for your agency. "
                f"Route: {booking.route_id}"
            ),
            notification_type="agency_booking_offer",
            booking_id=booking.id
        )

        db.commit()
        db.refresh(offer)

        return offer

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409,
            "Unable to create agency booking offer"
        )
