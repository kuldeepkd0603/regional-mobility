
from fastapi import APIRouter, HTTPException

from app.schemas import (
    FareEstimateRequest,
    FareEstimateResponse
)

router = APIRouter(
    prefix="/fares",
    tags=["Fare Estimation"]
)

# Initial fare configuration (INR)
VEHICLE_RATES = {
    "dzire": {"base_fare": 100, "per_km": 12},
    "eeco": {"base_fare": 100, "per_km": 11},
    "ertiga": {"base_fare": 150, "per_km": 15},
    "innova": {"base_fare": 200, "per_km": 18},
    "urbania": {"base_fare": 500, "per_km": 25},
}

TRIP_MULTIPLIERS = {
    "local": 1.0,
    "intercity": 1.0,
    "round_trip": 2.0,
    "religious_tour": 1.0,
}


@router.post("/estimate", response_model=FareEstimateResponse)
def estimate_fare(data: FareEstimateRequest):

    vehicle_type = data.vehicle_type.lower()
    trip_type = data.trip_type.value

    if vehicle_type not in VEHICLE_RATES:
        raise HTTPException(
            status_code=400,
            detail="Unsupported vehicle type"
        )

    if trip_type not in TRIP_MULTIPLIERS:
        raise HTTPException(
            status_code=400,
            detail="Unsupported trip type"
        )

    rates = VEHICLE_RATES[vehicle_type]

    chargeable_distance = (
        data.distance_km * TRIP_MULTIPLIERS[trip_type]
    )

    estimated_fare = (
        rates["base_fare"]
        + chargeable_distance * rates["per_km"]
    )

    return {
        "trip_type": data.trip_type,
        "distance_km": data.distance_km,
        "chargeable_distance_km": chargeable_distance,
        "base_fare": rates["base_fare"],
        "per_km_rate": rates["per_km"],
        "estimated_fare": round(estimated_fare, 2),
        "currency": "INR"
    }
