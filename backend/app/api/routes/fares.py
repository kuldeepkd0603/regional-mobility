
from fastapi import APIRouter, HTTPException
from app.core.pricing import calculate_estimated_fare
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

    try:
        result = calculate_estimated_fare(
            vehicle_type=data.vehicle_type,
            distance_km=data.distance_km,
            trip_type=data.trip_type.value,
        )

    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail=str(error)
        )

    return {
        "trip_type": data.trip_type,
        "distance_km": data.distance_km,
        "chargeable_distance_km": result["chargeable_distance_km"],
        "base_fare": result["base_fare"],
        "per_km_rate": result["per_km_rate"],
        "estimated_fare": result["estimated_fare"],
        "currency": "INR",
    }