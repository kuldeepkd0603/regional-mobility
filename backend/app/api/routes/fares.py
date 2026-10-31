from fastapi import APIRouter

from app.schemas import (
    FareEstimateRequest,
    FareEstimateResponse
)

router = APIRouter(
    prefix="/fares",
    tags=["Fare Estimation"]
)

BASE_FARE_INR = 100.0
PER_KM_RATE_INR = 12.0


@router.post("/estimate", response_model=FareEstimateResponse)
def estimate_fare(data: FareEstimateRequest):

    chargeable_distance = data.distance_km

    if data.trip_type.value == "round_trip":
        chargeable_distance *= 2

    estimated_fare = (
        BASE_FARE_INR
        + chargeable_distance * PER_KM_RATE_INR
    )

    return {
        "trip_type": data.trip_type,
        "distance_km": data.distance_km,
        "chargeable_distance_km": chargeable_distance,
        "base_fare": BASE_FARE_INR,
        "per_km_rate": PER_KM_RATE_INR,
        "estimated_fare": round(estimated_fare, 2),
        "currency": "INR"
    }