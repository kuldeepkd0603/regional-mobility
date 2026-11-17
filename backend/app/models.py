
import enum
from datetime import datetime
from sqlalchemy import Float, DateTime
from datetime import datetime, timezone
from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    CheckConstraint,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Index, UniqueConstraint, func
from app.db import Base


# -------------------------
# ENUMS
# -------------------------

class UserRole(str, enum.Enum):
    PASSENGER = "passenger"
    DRIVER = "driver"
    AGENCY = "agency"
    ADMIN = "admin"


class VerificationStatus(str, enum.Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"


class BookingStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DRIVER_ASSIGNED = "driver_assigned"
    ONGOING = "ongoing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    
class AgencyOfferStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    

class TripType(str, enum.Enum):
    LOCAL = "local"
    INTERCITY = "intercity"
    ROUND_TRIP = "round_trip"
    RELIGIOUS_TOUR = "religious_tour"



# -------------------------
# USERS TABLE
# -------------------------

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    full_name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    email: Mapped[str | None] = mapped_column(String(150), unique=True, nullable=True)

    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role"),
        default=UserRole.PASSENGER,
        nullable=False,
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    driver_profile: Mapped["Driver | None"] = relationship(
        back_populates="user",
        uselist=False,
    )
    
    agency_profile: Mapped["Agency | None"] = relationship(
    back_populates="user",
    uselist=False,
)
    
    hashed_password: Mapped[str | None] = mapped_column(
    String(255),
    nullable=True
    )


# -------------------------
# AGENCIES TABLE
# -------------------------

class Agency(Base):
    __tablename__ = "agencies"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        unique=True,
        nullable=False
    )

    business_name: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    registration_number: Mapped[str | None] = mapped_column(
        String(100),
        unique=True,
        nullable=True
    )

    business_email: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True
    )

    business_address: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )

    city: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    verification_status: Mapped[VerificationStatus] = mapped_column(
        Enum(VerificationStatus, name="verification_status"),
        default=VerificationStatus.PENDING,
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    user: Mapped["User"] = relationship(
        back_populates="agency_profile"
    )

    drivers: Mapped[list["Driver"]] = relationship(
        back_populates="agency"
    )

# -------------------------
# DRIVERS TABLE
# -------------------------

class Driver(Base):
    __tablename__ = "drivers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        unique=True,
        nullable=False,
    )

    license_number: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    verification_status: Mapped[VerificationStatus] = mapped_column(
        Enum(VerificationStatus, name="verification_status"),
        default=VerificationStatus.PENDING,
        nullable=False,
    )

    rating: Mapped[float] = mapped_column(Float, default=5.0)
    is_available: Mapped[bool] = mapped_column(Boolean, default=False)

    user: Mapped["User"] = relationship(back_populates="driver_profile")
    vehicles: Mapped[list["Vehicle"]] = relationship(back_populates="driver")

    latitude: Mapped[float | None] = mapped_column(
    Float,
    nullable=True
    )

    longitude: Mapped[float | None] = mapped_column(
    Float,
    nullable=True
    )

    location_updated_at: Mapped[datetime | None] = mapped_column(
    DateTime(timezone=True),
    nullable=True
    )
    
    agency_id: Mapped[int | None] = mapped_column(
    ForeignKey("agencies.id"),
    nullable=True,
    index=True
    )

    agency: Mapped["Agency | None"] = relationship(
        back_populates="drivers"
    )
# -------------------------
# VEHICLES TABLE
# -------------------------

class Vehicle(Base):
    __tablename__ = "vehicles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    driver_id: Mapped[int] = mapped_column(
        ForeignKey("drivers.id"),
        nullable=False,
    )

    vehicle_name: Mapped[str] = mapped_column(String(100), nullable=False)
    vehicle_type: Mapped[str] = mapped_column(String(50), nullable=False)

    registration_number: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        nullable=False,
    )

    seating_capacity: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    driver: Mapped["Driver"] = relationship(back_populates="vehicles")


# -------------------------
# RIDE ROUTES TABLE
# -------------------------

class RideRoute(Base):
    __tablename__ = "ride_routes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    pickup_city: Mapped[str] = mapped_column(String(100), nullable=False)
    drop_city: Mapped[str] = mapped_column(String(100), nullable=False)

    pickup_address: Mapped[str] = mapped_column(Text, nullable=False)
    drop_address: Mapped[str] = mapped_column(Text, nullable=False)

    distance_km: Mapped[float | None] = mapped_column(Float, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    bookings: Mapped[list["Booking"]] = relationship(
        back_populates="route"
    )
    pickup_latitude: Mapped[float | None] = mapped_column(
    Float, nullable=True
    )

    pickup_longitude: Mapped[float | None] = mapped_column(
        Float, nullable=True
    )

# -------------------------
# BOOKINGS TABLE
# -------------------------

class Booking(Base):
    __tablename__ = "bookings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    passenger_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
    )

    driver_id: Mapped[int | None] = mapped_column(
        ForeignKey("drivers.id"),
        nullable=True,
    )

    vehicle_id: Mapped[int | None] = mapped_column(
        ForeignKey("vehicles.id"),
        nullable=True,
    )

    preferred_vehicle_type: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    route_id: Mapped[int] = mapped_column(
        ForeignKey("ride_routes.id"),
        nullable=False,
    )


    route_id: Mapped[int] = mapped_column(
        ForeignKey("ride_routes.id"),
        nullable=False,
    )

    booking_status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, name="booking_status"),
        default=BookingStatus.PENDING,
        nullable=False,
    )

    estimated_fare: Mapped[float] = mapped_column(Float, nullable=False)
    final_fare: Mapped[float | None] = mapped_column(Float, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    
    
    
    trip_type: Mapped[TripType] = mapped_column(
    Enum(
        TripType,
        name="trip_type",
        values_callable=lambda enum_cls: [
            item.value for item in enum_cls
        ],
    ),
    default=TripType.LOCAL,
    server_default="local",
    nullable=False,
)

    scheduled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    return_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    passenger_count: Mapped[int] = mapped_column(
        Integer,
        default=1,
        server_default="1",
        nullable=False,
    )

    special_instructions: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )
   
    started_at: Mapped[datetime | None] = mapped_column(
    DateTime(timezone=True),
    nullable=True
    )

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    actual_distance_km: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )
    
    route: Mapped["RideRoute"] = relationship(
        back_populates="bookings"
    )
    
    

# -------------------------
# NOTIFICATIONS 

# -------------------------

class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    booking_id: Mapped[int | None] = mapped_column(
        ForeignKey("bookings.id"),
        nullable=True
    )

    title: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    message: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )

    notification_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    is_read: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        server_default="false",
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )


# -------------------------
# AGENCY BOOKING OFFERS
# -------------------------

class AgencyBookingOffer(Base):
    __tablename__ = "agency_booking_offers"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    booking_id: Mapped[int] = mapped_column(
        ForeignKey("bookings.id"),
        nullable=False,
        index=True
    )

    agency_id: Mapped[int] = mapped_column(
        ForeignKey("agencies.id"),
        nullable=False,
        index=True
    )

    status: Mapped[AgencyOfferStatus] = mapped_column(
        Enum(
            AgencyOfferStatus,
            name="agency_offer_status",
            values_callable=lambda enum_cls: [
                item.value for item in enum_cls
            ]
        ),
        default=AgencyOfferStatus.PENDING,
        nullable=False
    )

    offered_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    responded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
    
    

class DriverBookingRequest(Base):
    __tablename__ = "driver_booking_requests"

    __table_args__ = (
        UniqueConstraint(
            "booking_id",
            "driver_id",
            name="uq_booking_driver_request"
        ),
        Index(
            "ix_driver_booking_request_expiry",
            "status",
            "expires_at"
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    booking_id = Column(
        Integer,
        ForeignKey("bookings.id"),
        nullable=False
    )

    driver_id = Column(
        Integer,
        ForeignKey("drivers.id"),
        nullable=False
    )

    status = Column(
        String(20),
        nullable=False,
        default="pending"
    )

    offered_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now()
    )

    expires_at = Column(
        DateTime(timezone=True),
        nullable=False
    )

    responded_at = Column(
        DateTime(timezone=True),
        nullable=True
    )


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    token: Mapped[str] = mapped_column(
        String(500),
        unique=True,
        nullable=False
    )

    platform: Mapped[str] = mapped_column(
        String(20),
        default="android",
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )


class DriverReview(Base):
    __tablename__ = "driver_reviews"

    __table_args__ = (
        UniqueConstraint("booking_id", name="uq_driver_review_booking"),
        CheckConstraint(
            "rating >= 1 AND rating <= 5",
            name="ck_driver_review_rating"
        ),
    )

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    booking_id: Mapped[int] = mapped_column(
        ForeignKey("bookings.id"),
        nullable=False,
        index=True
    )

    passenger_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    driver_id: Mapped[int] = mapped_column(
        ForeignKey("drivers.id"),
        nullable=False,
        index=True
    )

    rating: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    review: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )