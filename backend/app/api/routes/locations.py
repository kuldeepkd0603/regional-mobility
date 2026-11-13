
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

from app.api.routes.auth import require_roles

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


# ============================================================
# 1. DRIVER UPDATES THEIR OWN LIVE LOCATION
# ============================================================

@router.patch("/driver/{driver_id}")
def update_driver_location(
    driver_id: int,
    location: DriverLocationUpdate,
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


# ============================================================
# 2. PASSENGER TRACKS ASSIGNED DRIVER
# ============================================================

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
        raise HTTPException(
            status_code=404,
            detail="Booking not found"
        )

    # Passenger can track only their own booking.
    if (
        current_user.role == UserRole.PASSENGER
        and booking.passenger_id != current_user.id
    ):
        raise HTTPException(
            status_code=403,
            detail="You cannot track another passenger's booking"
        )

    if booking.booking_status not in [
        BookingStatus.DRIVER_ASSIGNED,
        BookingStatus.ONGOING
    ]:
        raise HTTPException(
            status_code=400,
            detail="Driver tracking is available only for assigned or ongoing trips"
        )

    if not booking.driver_id:
        raise HTTPException(
            status_code=404,
            detail="No driver assigned"
        )

    driver = db.get(Driver, booking.driver_id)

    if not driver:
        raise HTTPException(
            status_code=404,
            detail="Driver not found"
        )

    if driver.latitude is None or driver.longitude is None:
        raise HTTPException(
            status_code=404,
            detail="Driver location is not available yet"
        )

    if driver.location_updated_at is None:
        raise HTTPException(
            status_code=404,
            detail="Driver has not shared their location"
        )

    now = datetime.now(timezone.utc)
    updated_at = driver.location_updated_at

    # Handle timezone-naive datetime.
    if updated_at.tzinfo is None:
        updated_at = updated_at.replace(tzinfo=timezone.utc)

    if (now - updated_at).total_seconds() > 300:
        raise HTTPException(
            status_code=409,
            detail="Driver location is outdated"
        )

    user = db.get(User, driver.user_id)
    vehicle = db.get(Vehicle, booking.vehicle_id)

    if not user or not vehicle:
        raise HTTPException(
            status_code=404,
            detail="Driver or assigned vehicle information not found"
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


# ============================================================
# 3. FIND NEARBY AVAILABLE DRIVERS
# ============================================================

@router.get(
    "/nearby",
    response_model=list[NearbyDriverResponse]
)
def find_nearby_drivers(
    latitude: float = Query(ge=-90, le=90),
    longitude: float = Query(ge=-180, le=180),
    radius_km: float = Query(default=10, gt=0, le=100),
    passenger_count: int = Query(default=1, ge=1, le=50),
    vehicle_type: str | None = Query(default=None),

    db: Session = Depends(get_db),

    current_user: User = Depends(
        require_roles(UserRole.PASSENGER, UserRole.ADMIN)
    )
):

    # Validate that coordinates are within valid geographic ranges.
    if not (-90 <= latitude <= 90):
        raise HTTPException(
            status_code=400,
            detail="Invalid latitude"
        )

    if not (-180 <= longitude <= 180):
        raise HTTPException(
            status_code=400,
            detail="Invalid longitude"
        )

    # SQLAlchemy text() uses :parameter syntax.
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
                    extensions.ST_MakePoint(
                        d.longitude,
                        d.latitude
                    ),
                    4326
                )::extensions.geography,

                extensions.ST_SetSRID(
                    extensions.ST_MakePoint(
                        :longitude,
                        :latitude
                    ),
                    4326
                )::extensions.geography
            ) / 1000.0 AS distance_km

        FROM drivers d

        JOIN users u
            ON u.id = d.user_id

        JOIN vehicles v
            ON v.driver_id = d.id

        WHERE

            d.is_available = TRUE

            AND d.verification_status = 'VERIFIED'

            AND u.is_active = TRUE

            AND v.is_active = TRUE

            AND d.latitude IS NOT NULL

            AND d.longitude IS NOT NULL

            -- Driver location must be updated within 5 minutes.
            AND d.location_updated_at >=
                NOW() - INTERVAL '5 minutes'

            -- Vehicle must have enough seats.
            AND v.seating_capacity >= :passenger_count

            -- Optional vehicle type filter.
            AND (
                CAST(:vehicle_type AS TEXT) IS NULL
                OR LOWER(v.vehicle_type) =
                   LOWER(CAST(:vehicle_type AS TEXT))
            )

            -- Search drivers within the selected radius.
            AND extensions.ST_DWithin(

                extensions.ST_SetSRID(
                    extensions.ST_MakePoint(
                        d.longitude,
                        d.latitude
                    ),
                    4326
                )::extensions.geography,

                extensions.ST_SetSRID(
                    extensions.ST_MakePoint(
                        :longitude,
                        :latitude
                    ),
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
            "longitude": longitude,
            "latitude": latitude,
            "passenger_count": passenger_count,
            "vehicle_type": vehicle_type,
            "radius_m": radius_km * 1000,
        }
    )

    drivers = [
        dict(row)
        for row in result.mappings().all()
    ]

    return drivers

