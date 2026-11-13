
import os

import httpx
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

load_dotenv()

router = APIRouter(prefix="/routes", tags=["Google Routes"])

GOOGLE_ROUTES_URL = (
    "https://routes.googleapis.com/directions/v2:computeRoutes"
)


class DistanceRequest(BaseModel):
    pickup_latitude: float = Field(ge=-90, le=90)
    pickup_longitude: float = Field(ge=-180, le=180)
    drop_latitude: float = Field(ge=-90, le=90)
    drop_longitude: float = Field(ge=-180, le=180)


@router.post("/distance")
async def calculate_route_distance(request: DistanceRequest):
    api_key = os.getenv("GOOGLE_MAPS_API_KEY")

    if not api_key:
        raise HTTPException(
            status_code=500,
            detail="Google Routes API key is not configured",
        )

    payload = {
        "origin": {
            "location": {
                "latLng": {
                    "latitude": request.pickup_latitude,
                    "longitude": request.pickup_longitude,
                }
            }
        },
        "destination": {
            "location": {
                "latLng": {
                    "latitude": request.drop_latitude,
                    "longitude": request.drop_longitude,
                }
            }
        },
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE",
        "computeAlternativeRoutes": False,
    }

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": api_key,
        "X-Goog-FieldMask": (
            "routes.distanceMeters,"
            "routes.duration,"
            "routes.polyline.encodedPolyline"
        ),
    }

    try:
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.post(
                GOOGLE_ROUTES_URL,
                json=payload,
                headers=headers,
            )

        if response.status_code != 200:
            print("Google API Status:", response.status_code)
            print("Google API Response:", response.text)

            raise HTTPException(
                status_code=502,
                detail={
                    "google_status": response.status_code,
                    "google_error": response.json(),
                },
            )

        data = response.json()
        routes = data.get("routes", [])

        if not routes:
            raise HTTPException(
                status_code=404,
                detail="No driving route found between these locations",
            )

        route = routes[0]
        distance_meters = route["distanceMeters"]
        distance_km = round(distance_meters / 1000, 2)

        duration_text = route.get("duration", "0s")
        duration_seconds = int(duration_text.removesuffix("s"))

        return {
            "distance_meters": distance_meters,
            "distance_km": distance_km,
            "duration": duration_text,
            "duration_seconds": duration_seconds,
            "polyline": route.get("polyline", {}).get(
                "encodedPolyline"
            ),
        }

    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="Google Routes API request timed out",
        )
    except httpx.RequestError:
        raise HTTPException(
            status_code=502,
            detail="Unable to connect to Google Routes API",
        )
