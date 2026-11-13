from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import (
    Booking,
    BookingStatus,
    Driver,
    DriverReview,
    User,
    UserRole,
)
from app.schemas import (
    DriverReviewCreate,
    DriverReviewResponse,
)
from app.api.routes.auth import get_current_user, require_roles


router = APIRouter(
    prefix="/reviews",
    tags=["Driver Reviews"]
)


# Passenger submits a review after completing a trip
@router.post("/", response_model=DriverReviewResponse, status_code=201)
def create_driver_review(
    data: DriverReviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.PASSENGER)
    )
):
    booking = db.query(Booking).filter(
        Booking.id == data.booking_id
    ).first()

    if not booking:
        raise HTTPException(404, "Booking not found")

    if booking.passenger_id != current_user.id:
        raise HTTPException(
            403,
            "You can only review your own bookings"
        )

    if booking.booking_status != BookingStatus.COMPLETED:
        raise HTTPException(
            400,
            "You can review only completed trips"
        )

    if not booking.driver_id:
        raise HTTPException(
            400,
            "No driver is assigned to this booking"
        )

    existing_review = db.query(DriverReview).filter(
        DriverReview.booking_id == booking.id
    ).first()

    if existing_review:
        raise HTTPException(
            409,
            "You have already reviewed this trip"
        )

    driver = db.query(Driver).filter(
        Driver.id == booking.driver_id
    ).first()

    if not driver:
        raise HTTPException(404, "Driver not found")

    new_review = DriverReview(
        booking_id=booking.id,
        passenger_id=current_user.id,
        driver_id=driver.id,
        rating=data.rating,
        review=data.review.strip() if data.review else None,
        created_at=datetime.now(timezone.utc)
    )

    try:
        db.add(new_review)
        db.flush()

        average_rating = db.query(
            func.avg(DriverReview.rating)
        ).filter(
            DriverReview.driver_id == driver.id
        ).scalar()

        driver.rating = round(float(average_rating), 2)

        db.commit()
        db.refresh(new_review)

        return new_review

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409,
            "This booking has already been reviewed"
        )


# Driver views their received reviews
@router.get(
    "/driver/my-reviews",
    response_model=list[DriverReviewResponse]
)
def get_my_driver_reviews(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.DRIVER)
    )
):
    driver = db.query(Driver).filter(
        Driver.user_id == current_user.id
    ).first()

    if not driver:
        raise HTTPException(
            404,
            "Driver profile not found"
        )

    return (
        db.query(DriverReview)
        .filter(DriverReview.driver_id == driver.id)
        .order_by(DriverReview.created_at.desc())
        .all()
    )


# Passenger checks whether they have reviewed a booking
@router.get(
    "/booking/{booking_id}",
    response_model=DriverReviewResponse | None
)
def get_booking_review(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.PASSENGER)
    )
):
    booking = db.query(Booking).filter(
        Booking.id == booking_id
    ).first()

    if not booking:
        raise HTTPException(404, "Booking not found")

    if booking.passenger_id != current_user.id:
        raise HTTPException(
            403,
            "You can only view reviews for your own bookings"
        )

    return db.query(DriverReview).filter(
        DriverReview.booking_id == booking_id
    ).first()