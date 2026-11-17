
from datetime import datetime, timedelta, timezone
from math import radians, sin, cos, asin, sqrt

from sqlalchemy.orm import Session

from app.models import (
    Booking,
    BookingStatus,
    Driver,
    DriverBookingRequest,
    RideRoute,
    Vehicle,
    VerificationStatus,
)
from app.core.notifications import create_notification


SEARCH_RADIUS_KM = 10
BATCH_SIZE = 3
REQUEST_TIMEOUT_SECONDS = 30
LOCATION_MAX_AGE_MINUTES = 5


def calculate_distance_km(lat1, lon1, lat2, lon2):
    """Calculate distance between two GPS coordinates."""
    lat1, lon1, lat2, lon2 = map(
        radians, [lat1, lon1, lat2, lon2]
    )

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = (
        sin(dlat / 2) ** 2
        + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    )

    return 6371 * 2 * asin(sqrt(a))


def dispatch_booking_requests(
    db: Session,
    booking_id: int,
):
    now = datetime.now(timezone.utc)

    # Lock booking to prevent simultaneous dispatch operations.
    booking = (
        db.query(Booking)
        .filter(Booking.id == booking_id)
        .with_for_update()
        .first()
    )

    if not booking:
        raise ValueError("Booking not found")

    if (
        booking.booking_status != BookingStatus.PENDING
        or booking.driver_id is not None
    ):
        return {"message": "Booking is not available for dispatch", "sent": 0}

    route = db.query(RideRoute).filter(
        RideRoute.id == booking.route_id
    ).first()

    if (
        not route
        or route.pickup_latitude is None
        or route.pickup_longitude is None
    ):
        raise ValueError("Booking pickup coordinates are missing")

    # Do not send another batch while earlier requests are pending.
    pending_count = db.query(DriverBookingRequest).filter(
        DriverBookingRequest.booking_id == booking.id,
        DriverBookingRequest.status == "pending",
        DriverBookingRequest.expires_at > now,
    ).count()

    if pending_count:
        return {
            "message": "Existing driver requests are still pending",
            "sent": 0,
        }

    # Exclude drivers who have already received this booking.
    previous_requests = db.query(
        DriverBookingRequest.driver_id
    ).filter(
        DriverBookingRequest.booking_id == booking.id
    ).all()

    excluded_driver_ids = {row[0] for row in previous_requests}

    # Find verified, online drivers with active vehicles.
    candidates = (
        db.query(Driver, Vehicle)
        .join(Vehicle, Vehicle.driver_id == Driver.id)
        .filter(
            Driver.is_available.is_(True),
            Driver.verification_status == VerificationStatus.VERIFIED,
            Driver.latitude.isnot(None),
            Driver.longitude.isnot(None),
            Vehicle.is_active.is_(True),
            Vehicle.seating_capacity >= booking.passenger_count,
        )
        .all()
    )

    eligible = []

    for driver, vehicle in candidates:
        if driver.id in excluded_driver_ids:
            continue

        # Ignore drivers whose GPS location is missing or stale.
        updated_at = driver.location_updated_at

        if updated_at is None:
            continue

        if updated_at.tzinfo is None:
            updated_at = updated_at.replace(tzinfo=timezone.utc)

        if updated_at < now - timedelta(
            minutes=LOCATION_MAX_AGE_MINUTES
        ):
            continue

        # Respect the passenger's preferred vehicle type.
        if booking.preferred_vehicle_type:
            if (
                vehicle.vehicle_type.lower()
                != booking.preferred_vehicle_type.lower()
            ):
                continue

        distance = calculate_distance_km(
            route.pickup_latitude,
            route.pickup_longitude,
            driver.latitude,
            driver.longitude,
        )

        if distance <= SEARCH_RADIUS_KM:
            eligible.append((distance, driver, vehicle))

    # Nearest drivers first.
    eligible.sort(key=lambda item: item[0])

    selected = eligible[:BATCH_SIZE]
    created_requests = []

    for distance, driver, vehicle in selected:
        request = DriverBookingRequest(
            booking_id=booking.id,
            driver_id=driver.id,
            status="pending",
            offered_at=now,
            expires_at=now + timedelta(
                seconds=REQUEST_TIMEOUT_SECONDS
            ),
        )

        db.add(request)

        create_notification(
            db=db,
            user_id=driver.user_id,
            title="New Ride Request",
            message=(
                f"You have a new ride request from "
                f"{route.pickup_city} to {route.drop_city}. "
                f"Please respond within 30 seconds."
            ),
            notification_type="booking_request",
            booking_id=booking.id,
        )

        created_requests.append({
            "driver_id": driver.id,
            "distance_km": round(distance, 2),
            "request_expires_at": request.expires_at.isoformat(),
        })

    db.commit()

    return {
        "message": (
            "Driver requests sent"
            if created_requests
            else "No eligible drivers found"
        ),
        "booking_id": booking.id,
        "sent": len(created_requests),
        "requests": created_requests,
    }
