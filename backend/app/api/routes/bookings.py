
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.db import get_db
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
)

from app.schemas import (
    BookingCreate,
    BookingResponse,
    BookingAssignment,
    BookingStatusUpdate,
)

router = APIRouter(
    prefix="/bookings",
    tags=["Bookings"]
)


# TEMPORARY DEVELOPMENT PRICING.
# Replace these values with your approved business pricing.
BASE_FARE_INR = 100.0
PER_KM_RATE_INR = 12.0


def calculate_fare(distance_km: float, trip_type: TripType) -> float:
    distance = distance_km

    if trip_type == TripType.ROUND_TRIP:
        distance *= 2

    fare = BASE_FARE_INR + (distance * PER_KM_RATE_INR)

    return round(fare, 2)


# CREATE BOOKING
@router.post("/", response_model=BookingResponse, status_code=201)
def create_booking(
    data: BookingCreate,
    db: Session = Depends(get_db)
):
    passenger = db.query(User).filter(
        User.id == data.passenger_id,
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
            passenger_id=data.passenger_id,
            route_id=route.id,
            trip_type=data.trip_type,
            scheduled_at=data.scheduled_at,
            return_at=data.return_at,
            passenger_count=data.passenger_count,
            special_instructions=data.special_instructions,
            estimated_fare=calculate_fare(
                data.distance_km,
                data.trip_type
            ),
            booking_status=BookingStatus.PENDING,
        )

        db.add(booking)
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


# GET ALL BOOKINGS
@router.get("/", response_model=list[BookingResponse])
def get_bookings(
    passenger_id: int | None = Query(default=None),
    driver_id: int | None = Query(default=None),
    db: Session = Depends(get_db)
):
    query = db.query(Booking)

    if passenger_id is not None:
        query = query.filter(
            Booking.passenger_id == passenger_id
        )

    if driver_id is not None:
        query = query.filter(
            Booking.driver_id == driver_id
        )

    return query.order_by(
        Booking.id.desc()
    ).limit(100).all()


# GET BOOKING BY ID
@router.get("/{booking_id}", response_model=BookingResponse)
def get_booking(
    booking_id: int,
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(
        Booking.id == booking_id
    ).first()

    if not booking:
        raise HTTPException(404, "Booking not found")

    return booking


# ASSIGN DRIVER AND VEHICLE
@router.patch("/{booking_id}/assign", response_model=BookingResponse)
def assign_driver(
    booking_id: int,
    data: BookingAssignment,
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(
        Booking.id == booking_id
    ).with_for_update().first()

    if not booking:
        raise HTTPException(404, "Booking not found")

    if booking.booking_status != BookingStatus.PENDING:
        raise HTTPException(
            409,
            "Only pending bookings can be assigned"
        )

    driver = db.query(Driver).filter(
        Driver.id == data.driver_id
    ).first()

    if not driver:
        raise HTTPException(404, "Driver not found")

    if driver.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(403, "Driver is not verified")

    if not driver.is_available:
        raise HTTPException(409, "Driver is not available")

    vehicle = db.query(Vehicle).filter(
        Vehicle.id == data.vehicle_id,
        Vehicle.driver_id == driver.id,
        Vehicle.is_active.is_(True),
    ).first()

    if not vehicle:
        raise HTTPException(
            400,
            "Vehicle is not active or does not belong to this driver"
        )

    if vehicle.seating_capacity < booking.passenger_count:
        raise HTTPException(
            400,
            "Vehicle does not have enough passenger capacity"
        )

    booking.driver_id = driver.id
    booking.vehicle_id = vehicle.id
    booking.booking_status = BookingStatus.DRIVER_ASSIGNED

    db.commit()
    db.refresh(booking)

    return booking


# UPDATE BOOKING STATUS
@router.patch("/{booking_id}/status", response_model=BookingResponse)
def update_booking_status(
    booking_id: int,
    data: BookingStatusUpdate,
    db: Session = Depends(get_db)
):
    booking = db.query(Booking).filter(
        Booking.id == booking_id
    ).with_for_update().first()

    if not booking:
        raise HTTPException(404, "Booking not found")

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
            409,
            f"Cannot change booking from "
            f"{booking.booking_status.value} to "
            f"{data.booking_status.value}"
        )

    booking.booking_status = data.booking_status

    db.commit()
    db.refresh(booking)

    return booking
