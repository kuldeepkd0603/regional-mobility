from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Driver, VerificationStatus
from app.schemas import DriverLocationUpdate, NearbyDriverResponse

router = APIRouter(
    prefix="/locations",
    tags=["Driver Location Management"]
)


# 1. Update driver's live location
@router.patch("/driver/{driver_id}")
def update_driver_location(
    driver_id: int,
    location: DriverLocationUpdate,
    db: Session = Depends(get_db)
):
    driver = db.get(Driver, driver_id)

    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")

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


# 2. Find nearby available drivers
@router.get("/nearby", response_model=list[NearbyDriverResponse])
def find_nearby_drivers(
    latitude: float = Query(ge=-90, le=90),
    longitude: float = Query(ge=-180, le=180),
    radius_km: float = Query(default=10, gt=0, le=100),
    passenger_count: int = Query(default=1, ge=1, le=50),
    vehicle_type: str | None = None,
    db: Session = Depends(get_db)
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

    return [dict(row) for row in result.mappings().all()]