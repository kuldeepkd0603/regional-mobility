
from fastapi import FastAPI

from app.api.routes.users import router as users_router
from app.api.routes.drivers import router as drivers_router
from app.api.routes.vehicles import router as vehicles_router
from app.api.routes.bookings import router as bookings_router
from app.api.routes import trips
from app.api.routes import locations
from app.api.routes import fares
from app.api.routes import auth
from app.api.routes import notifications
from app.api.routes import agencies
app = FastAPI(
    title="Regional Mobility Platform",
    description="Taxi booking and mobility marketplace API",
    version="1.0.0"
)

app.include_router(users_router)
app.include_router(drivers_router)
app.include_router(vehicles_router)
app.include_router(bookings_router)
app.include_router(trips.router)
app.include_router(locations.router)
app.include_router(fares.router)
app.include_router(auth.router)
app.include_router(notifications.router)
app.include_router(agencies.router)
@app.get("/")
def root():
    return {
        "message": "Regional Mobility API is running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }
