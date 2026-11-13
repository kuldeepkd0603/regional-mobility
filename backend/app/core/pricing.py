# Shared Pricing Configuration
# All prices are in INR.

VEHICLE_RATES = {
    "dzire": {"base_fare": 100.0, "per_km": 12.0},
    "eeco": {"base_fare": 100.0, "per_km": 11.0},
    "ertiga": {"base_fare": 150.0, "per_km": 15.0},
    "innova": {"base_fare": 200.0, "per_km": 18.0},
    "urbania": {"base_fare": 500.0, "per_km": 25.0},
}

TRIP_MULTIPLIERS = {
    "local": 1.0,
    "intercity": 1.0,
    "round_trip": 2.0,
    "religious_tour": 1.0,
}


def get_vehicle_rate(vehicle_type: str) -> dict:
    vehicle_type = vehicle_type.lower()

    rates = VEHICLE_RATES.get(vehicle_type)

    if rates is None:
        raise ValueError(
            f"Unsupported vehicle type: {vehicle_type}"
        )

    return rates


def calculate_estimated_fare(
    vehicle_type: str,
    distance_km: float,
    trip_type: str,
) -> dict:

    rates = get_vehicle_rate(vehicle_type)

    multiplier = TRIP_MULTIPLIERS.get(trip_type)

    if multiplier is None:
        raise ValueError(f"Unsupported trip type: {trip_type}")

    chargeable_distance = distance_km * multiplier

    estimated_fare = (
        rates["base_fare"]
        + chargeable_distance * rates["per_km"]
    )

    return {
        "base_fare": rates["base_fare"],
        "per_km_rate": rates["per_km"],
        "chargeable_distance_km": chargeable_distance,
        "estimated_fare": round(estimated_fare, 2),
    }


def calculate_final_fare(
    vehicle_type: str,
    actual_distance_km: float,
) -> float:

    rates = get_vehicle_rate(vehicle_type)

    final_fare = (
        rates["base_fare"]
        + actual_distance_km * rates["per_km"]
    )

    return round(final_fare, 2)