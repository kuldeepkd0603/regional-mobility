
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import get_db

from app.schemas import (
    DriverLocationUpdate,
    NearbyDriverResponse,
    AssignedDriverLocationResponse,
)
from app.api.routes.auth import get_current_user, require_roles

from app.models import (
    Booking,
    BookingStatus,
    Driver,
    Vehicle,
    User,
    UserRole,
    VerificationStatus,
)

router = APIRouter(
    prefix="/locations",
    tags=["Driver Location Management"]
)


# 1. Driver updates their own live location
@router.patch("/driver/{driver_id}")
def update_driver_location(
    driver_id: int,
    location: DriverLocationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.DRIVER)
    )
):
    # Find driver using both driver ID and logged-in user ID.
    # This prevents drivers from updating someone else's location.
    driver = db.query(Driver).filter(
        Driver.id == driver_id,
        Driver.user_id == current_user.id
    ).first()

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Your driver profile was not found"
        )

    if driver.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(
            status_code=403,
            detail="Driver must be verified before updating location"
        )

    if not driver.is_available:
        raise HTTPException(
            status_code=400,
            detail="Driver must be online to update location"
        )

    driver.latitude = location.latitude
    driver.longitude = location.longitude
    driver.location_updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(driver)

    return {
        "message": "Driver location updated successfully",
        "driver_id": driver.id,
        "latitude": driver.latitude,
        "longitude": driver.longitude,
        "location_updated_at": driver.location_updated_at
    }


# 3. Passenger tracks assigned driver
@router.get(
    "/booking/{booking_id}/driver",
    response_model=AssignedDriverLocationResponse
)
def get_assigned_driver_location(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.PASSENGER, UserRole.ADMIN)
    )
):
    booking = db.get(Booking, booking_id)

    if not booking:
        raise HTTPException(404, "Booking not found")

    # Passenger can only track their own booking.
    if (
        current_user.role == UserRole.PASSENGER
        and booking.passenger_id != current_user.id
    ):
        raise HTTPException(
            403,
            "You cannot track another passenger's booking"
        )

    if booking.booking_status not in [
        BookingStatus.DRIVER_ASSIGNED,
        BookingStatus.ONGOING
    ]:
        raise HTTPException(
            400,
            "Driver tracking is available only for assigned or ongoing trips"
        )

    if not booking.driver_id:
        raise HTTPException(404, "No driver assigned")

    driver = db.get(Driver, booking.driver_id)

    if not driver:
        raise HTTPException(404, "Driver not found")

    if driver.latitude is None or driver.longitude is None:
        raise HTTPException(
            404,
            "Driver location is not available yet"
        )

    if driver.location_updated_at is None:
        raise HTTPException(
            404,
            "Driver has not shared their location"
        )

    now = datetime.now(timezone.utc)
    updated_at = driver.location_updated_at

    # Handle a naive datetime defensively.
    if updated_at.tzinfo is None:
        updated_at = updated_at.replace(tzinfo=timezone.utc)

    if (now - updated_at).total_seconds() > 300:
        raise HTTPException(
            409,
            "Driver location is outdated"
        )

    user = db.get(User, driver.user_id)
    vehicle = db.get(Vehicle, booking.vehicle_id)

    if not user or not vehicle:
        raise HTTPException(
            404,
            "Driver or assigned vehicle information not found"
        )

    return {
        "booking_id": booking.id,
        "driver_id": driver.id,
        "driver_name": user.full_name,
        "vehicle_id": vehicle.id,
        "vehicle_name": vehicle.vehicle_name,
        "vehicle_type": vehicle.vehicle_type,
        "latitude": driver.latitude,
        "longitude": driver.longitude,
        "location_updated_at": driver.location_updated_at
    }


# 2. Find nearby available drivers
# Passenger and admin access only.
@router.get(
    "/nearby",
    response_model=list[NearbyDriverResponse]
)
def find_nearby_drivers(
    latitude: float = Query(ge=-90, le=90),
    longitude: float = Query(ge=-180, le=180),
    radius_km: float = Query(default=10, gt=0, le=100),
    passenger_count: int = Query(default=1, ge=1, le=50),
    vehicle_type: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.PASSENGER, UserRole.ADMIN)
    )
):
    sql = text("""
        SELECT
            d.id AS driver_id,
            u.full_name AS driver_name,
            v.id AS vehicle_id,
            v.vehicle_name,
            v.vehicle_type,
            v.registration_number,
            v.seating_capacity,
            d.rating,
            d.latitude,
            d.longitude,

            extensions.ST_Distance(
                extensions.ST_SetSRID(
                    extensions.ST_MakePoint(d.longitude, d.latitude),
                    4326
                )::extensions.geography,

                extensions.ST_SetSRID(
                    extensions.ST_MakePoint(:longitude, :latitude),
                    4326
                )::extensions.geography
            ) / 1000.0 AS distance_km

        FROM drivers d

        JOIN users u ON u.id = d.user_id
        JOIN vehicles v ON v.driver_id = d.id

        WHERE
            d.is_available = TRUE
            AND d.verification_status = 'verified'
            AND u.is_active = TRUE
            AND v.is_active = TRUE

            AND d.latitude IS NOT NULL
            AND d.longitude IS NOT NULL

            -- Only locations updated within the last 5 minutes
            AND d.location_updated_at >=
                NOW() - INTERVAL '5 minutes'

            AND v.seating_capacity >= :passenger_count

            AND (
                :vehicle_type IS NULL
                OR LOWER(v.vehicle_type) = LOWER(:vehicle_type)
            )

            AND extensions.ST_DWithin(
                extensions.ST_SetSRID(
                    extensions.ST_MakePoint(d.longitude, d.latitude),
                    4326
                )::extensions.geography,

                extensions.ST_SetSRID(
                    extensions.ST_MakePoint(:longitude, :latitude),
                    4326
                )::extensions.geography,

                :radius_m
            )

        ORDER BY distance_km ASC
        LIMIT 50
    """)

    result = db.execute(
        sql,
        {
            "latitude": latitude,
            "longitude": longitude,
            "radius_m": radius_km * 1000,
            "passenger_count": passenger_count,
            "vehicle_type": vehicle_type
        }
    )

    return [
        dict(row)
        for row in result.mappings().all()
    ]
