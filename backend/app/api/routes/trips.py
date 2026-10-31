from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.db import get_db
from app.models import Booking, Driver, RideRoute, BookingStatus
from app.schemas import TripResponse

router = APIRouter(
    prefix="/trips",
    tags=["Trip Management"]
)


# 1. Get all trips assigned to a driver
@router.get("/driver/{driver_id}", response_model=list[TripResponse])
def get_driver_trips(
    driver_id: int,
    db: Session = Depends(get_db)
):
    driver = db.get(Driver, driver_id)

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
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

    trips = []

    for booking, route in results:
        trip = {
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
            "distance_km": route.distance_km
        }

        trips.append(trip)

    return trips


# 2. Get individual trip details
@router.get("/{booking_id}", response_model=TripResponse)
def get_trip_details(
    booking_id: int,
    db: Session = Depends(get_db)
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
        "distance_km": route.distance_km
    }


# 3. Start a trip
@router.patch("/{booking_id}/start")
def start_trip(
    booking_id: int,
    driver_id: int,
    db: Session = Depends(get_db)
):
    booking = db.execute(
        select(Booking)
        .where(Booking.id == booking_id)
        .with_for_update()
    ).scalar_one_or_none()

    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Trip not found"
        )

    if booking.driver_id != driver_id:
        raise HTTPException(
            status_code=403,
            detail="This trip is not assigned to this driver"
        )

    if booking.booking_status != BookingStatus.DRIVER_ASSIGNED:
        raise HTTPException(
            status_code=400,
            detail="Only assigned trips can be started"
        )

    booking.booking_status = BookingStatus.ONGOING

    db.commit()

    return {
        "message": "Trip started successfully",
        "booking_id": booking.id,
        "status": booking.booking_status.value
    }


# 4. Complete a trip
@router.patch("/{booking_id}/complete")
def complete_trip(
    booking_id: int,
    driver_id: int,
    db: Session = Depends(get_db)
):
    booking = db.execute(
        select(Booking)
        .where(Booking.id == booking_id)
        .with_for_update()
    ).scalar_one_or_none()

    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Trip not found"
        )

    if booking.driver_id != driver_id:
        raise HTTPException(
            status_code=403,
            detail="This trip is not assigned to this driver"
        )

    if booking.booking_status != BookingStatus.ONGOING:
        raise HTTPException(
            status_code=400,
            detail="Only ongoing trips can be completed"
        )

    booking.booking_status = BookingStatus.COMPLETED

    db.commit()

    return {
        "message": "Trip completed successfully",
        "booking_id": booking.id,
        "status": booking.booking_status.value
    }