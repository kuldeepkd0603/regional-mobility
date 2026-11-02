
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.notifications import create_notification
from app.db import get_db
from app.models import (
    Booking,
    Driver,
    Vehicle,
    RideRoute,
    BookingStatus,
    User,
    UserRole,
)
from app.schemas import TripResponse, TripCompletionRequest
from app.api.routes.auth import get_current_user, require_roles

router = APIRouter(
    prefix="/trips",
    tags=["Trip Management"]
)

VEHICLE_RATES = {
    "dzire": {"base_fare": 100, "per_km": 12},
    "eeco": {"base_fare": 100, "per_km": 11},
    "ertiga": {"base_fare": 150, "per_km": 15},
    "innova": {"base_fare": 200, "per_km": 18},
    "urbania": {"base_fare": 500, "per_km": 25},
}


# Helper: Build trip response
def build_trip_response(booking, route):
    return {
        "id": booking.id,
        "passenger_id": booking.passenger_id,
        "driver_id": booking.driver_id,
        "vehicle_id": booking.vehicle_id,
        "route_id": booking.route_id,
        "booking_status": booking.booking_status,
        "trip_type": booking.trip_type,
        "estimated_fare": booking.estimated_fare,
        "final_fare": booking.final_fare,
        "scheduled_at": booking.scheduled_at,
        "passenger_count": booking.passenger_count,
        "created_at": booking.created_at,
        "pickup_city": route.pickup_city,
        "drop_city": route.drop_city,
        "pickup_address": route.pickup_address,
        "drop_address": route.drop_address,
        "distance_km": route.distance_km,
    }


# 1. Get trips assigned to a driver
# Driver can view only own trips. Admin can view any driver's trips.
@router.get("/driver/{driver_id}", response_model=list[TripResponse])
def get_driver_trips(
    driver_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    driver = db.get(Driver, driver_id)

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    if current_user.role == UserRole.DRIVER:
        if driver.user_id != current_user.id:
            raise HTTPException(
                status_code=403,
                detail="You can only view your own trips"
            )

    elif current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to view driver trips"
        )

    results = (
        db.query(Booking, RideRoute)
        .join(RideRoute, Booking.route_id == RideRoute.id)
        .filter(
            Booking.driver_id == driver_id,
            Booking.booking_status.in_([
                BookingStatus.DRIVER_ASSIGNED,
                BookingStatus.ONGOING,
                BookingStatus.COMPLETED
            ])
        )
        .order_by(Booking.scheduled_at.asc())
        .all()
    )

    return [
        build_trip_response(booking, route)
        for booking, route in results
    ]


# 5. Passenger trip history
@router.get("/passenger/my-history", response_model=list[TripResponse])
def get_passenger_trip_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.PASSENGER)
    )
):
    results = (
        db.query(Booking, RideRoute)
        .join(RideRoute, Booking.route_id == RideRoute.id)
        .filter(
            Booking.passenger_id == current_user.id
        )
        .order_by(Booking.created_at.desc())
        .all()
    )

    return [
        build_trip_response(booking, route)
        for booking, route in results
    ]

# 2. Get individual trip details
# Passenger sees own trip, assigned driver sees their trip,
# admin can see any trip.
@router.get("/{booking_id}", response_model=TripResponse)
def get_trip_details(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = (
        db.query(Booking, RideRoute)
        .join(RideRoute, Booking.route_id == RideRoute.id)
        .filter(Booking.id == booking_id)
        .first()
    )

    if not result:
        raise HTTPException(
            status_code=404,
            detail="Trip not found"
        )

    booking, route = result

    is_passenger = booking.passenger_id == current_user.id

    is_assigned_driver = False

    if current_user.role == UserRole.DRIVER:
        driver = db.query(Driver).filter(
            Driver.user_id == current_user.id
        ).first()

        if driver:
            is_assigned_driver = booking.driver_id == driver.id

    is_admin = current_user.role == UserRole.ADMIN

    if not (is_passenger or is_assigned_driver or is_admin):
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to view this trip"
        )

    return build_trip_response(booking, route)


# 3. Start a trip
# Only the driver assigned to the booking can start it.

@router.patch("/{booking_id}/start")
def start_trip(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.DRIVER))
):
    driver = db.query(Driver).filter(
        Driver.user_id == current_user.id
    ).first()

    if not driver:
        raise HTTPException(404, "Driver profile not found")

    booking = db.execute(
        select(Booking)
        .where(Booking.id == booking_id)
        .with_for_update()
    ).scalar_one_or_none()

    if not booking:
        raise HTTPException(404, "Trip not found")

    if booking.driver_id != driver.id:
        raise HTTPException(403, "This trip is not assigned to you")

    if booking.booking_status != BookingStatus.DRIVER_ASSIGNED:
        raise HTTPException(
            400,
            "Only assigned trips can be started"
        )

    booking.booking_status = BookingStatus.ONGOING
    booking.started_at = datetime.now(timezone.utc)

    # Notify passenger
    create_notification(
        db=db,
        user_id=booking.passenger_id,
        title="Your Trip Has Started",
        message=f"Your trip #{booking.id} has started.",
        notification_type="trip_started",
        booking_id=booking.id
    )

    db.commit()
    db.refresh(booking)

    return {
        "message": "Trip started successfully",
        "booking_id": booking.id,
        "status": booking.booking_status.value,
        "started_at": booking.started_at
    }

# 4. Complete a trip
# Only the assigned driver can complete their ongoing trip.

@router.patch("/{booking_id}/complete")
def complete_trip(
    booking_id: int,
    data: TripCompletionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.DRIVER))
):
    driver = db.query(Driver).filter(
        Driver.user_id == current_user.id
    ).first()

    if not driver:
        raise HTTPException(404, "Driver profile not found")

    booking = db.execute(
        select(Booking)
        .where(Booking.id == booking_id)
        .with_for_update()
    ).scalar_one_or_none()

    if not booking:
        raise HTTPException(404, "Trip not found")

    if booking.driver_id != driver.id:
        raise HTTPException(403, "This trip is not assigned to you")

    if booking.booking_status != BookingStatus.ONGOING:
        raise HTTPException(
            400,
            "Only ongoing trips can be completed"
        )

    vehicle = db.get(Vehicle, booking.vehicle_id)

    if not vehicle:
        raise HTTPException(409, "Assigned vehicle not found")

    vehicle_type = vehicle.vehicle_type.lower()

    rates = VEHICLE_RATES.get(vehicle_type)

    if not rates:
        raise HTTPException(
            409,
            f"Fare configuration missing for {vehicle.vehicle_type}"
        )

    actual_distance = data.actual_distance_km

    final_fare = (
        rates["base_fare"]
        + actual_distance * rates["per_km"]
    )

    booking.actual_distance_km = actual_distance
    booking.final_fare = round(final_fare, 2)
    booking.completed_at = datetime.now(timezone.utc)
    booking.booking_status = BookingStatus.COMPLETED
    # Notify passenger
    create_notification(
        db=db,
        user_id=booking.passenger_id,
        title="Trip Completed",
        message=(
            f"Your trip #{booking.id} is completed. "
            f"Final fare: ₹{booking.final_fare}"
        ),
        notification_type="trip_completed",
        booking_id=booking.id
    )
    db.commit()
    db.refresh(booking)

    return {
        "message": "Trip completed successfully",
        "booking_id": booking.id,
        "status": booking.booking_status.value,
        "actual_distance_km": booking.actual_distance_km,
        "estimated_fare": booking.estimated_fare,
        "final_fare": booking.final_fare,
        "completed_at": booking.completed_at,
        "currency": "INR"
    }


