
from datetime import datetime, timedelta, time, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db import get_db
from app.models import Booking, Driver, User, BookingStatus, UserRole
from app.api.routes.auth import require_roles

router = APIRouter(
    prefix="/earnings",
    tags=["Driver Earnings"]
)


@router.get("/driver/me")
def get_driver_earnings(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.DRIVER))
):
    driver = db.query(Driver).filter(
        Driver.user_id == current_user.id
    ).first()

    if not driver:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Driver profile not found")

    now = datetime.now(timezone.utc)
    today_start = datetime.combine(now.date(), time.min).replace(tzinfo=timezone.utc)
    week_start = today_start - timedelta(days=now.weekday())
    month_start = today_start.replace(day=1)

    completed_query = db.query(Booking).filter(
        Booking.driver_id == driver.id,
        Booking.booking_status == BookingStatus.COMPLETED,
        Booking.final_fare.isnot(None),
        Booking.completed_at.isnot(None)
    )

    def summary(start_date=None):
        query = completed_query
        if start_date:
            query = query.filter(Booking.completed_at >= start_date)

        result = query.with_entities(
            func.coalesce(func.sum(Booking.final_fare), 0),
            func.count(Booking.id)
        ).first()

        total = float(result[0] or 0)
        count = int(result[1] or 0)

        return {
            "total_earnings": round(total, 2),
            "completed_trips": count,
            "average_per_trip": round(total / count, 2) if count else 0
        }

    trips = completed_query.order_by(
        Booking.completed_at.desc()
    ).limit(100).all()

    history = [
        {
            "booking_id": trip.id,
            "final_fare": float(trip.final_fare),
            "estimated_fare": float(trip.estimated_fare),
            "actual_distance_km": trip.actual_distance_km,
            "completed_at": trip.completed_at,
            "trip_type": trip.trip_type.value
            if hasattr(trip.trip_type, "value")
            else str(trip.trip_type)
        }
        for trip in trips
    ]

    return {
        "driver_id": driver.id,
        "currency": "INR",
        "today": summary(today_start),
        "this_week": summary(week_start),
        "this_month": summary(month_start),
        "lifetime": summary(),
        "recent_earnings": history
    }
