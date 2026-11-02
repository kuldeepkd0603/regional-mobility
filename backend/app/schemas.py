
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field, EmailStr
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field, model_validator
from app.models import TripType, BookingStatus
from app.models import TripType, BookingStatus, VerificationStatus
from app.models import AgencyOfferStatus


class UserCreate(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    phone: str = Field(min_length=10, max_length=20)
    email: EmailStr | None = None


class UserResponse(BaseModel):
    id: int
    full_name: str
    phone: str
    email: str | None
    role: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
    
    

from pydantic import BaseModel, ConfigDict, Field, EmailStr


class DriverRegistrationCreate(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    phone: str = Field(min_length=10, max_length=15)
    email: EmailStr | None = None
    password: str = Field(min_length=8, max_length=128)
    license_number: str = Field(min_length=5, max_length=50)


class DriverResponse(BaseModel):
    id: int
    user_id: int
    license_number: str
    verification_status: str
    rating: float
    is_available: bool

    model_config = ConfigDict(from_attributes=True)


class DriverAvailabilityUpdate(BaseModel):
    is_available: bool

class DriverVerificationUpdate(BaseModel):
    verification_status: VerificationStatus


from pydantic import BaseModel, ConfigDict, Field


class VehicleCreate(BaseModel):
    driver_id: int
    vehicle_name: str = Field(min_length=2, max_length=100)
    vehicle_type: str = Field(min_length=2, max_length=50)
    registration_number: str = Field(min_length=5, max_length=20)
    seating_capacity: int = Field(ge=1, le=50)


class VehicleUpdate(BaseModel):
    vehicle_name: str | None = Field(default=None, max_length=100)
    vehicle_type: str | None = Field(default=None, max_length=50)
    seating_capacity: int | None = Field(default=None, ge=1, le=50)
    is_active: bool | None = None


class VehicleResponse(BaseModel):
    id: int
    driver_id: int
    vehicle_name: str
    vehicle_type: str
    registration_number: str
    seating_capacity: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class BookingCreate(BaseModel):
    passenger_id: int

    trip_type: TripType

    pickup_city: str = Field(min_length=2, max_length=100)
    drop_city: str = Field(min_length=2, max_length=100)

    pickup_address: str = Field(min_length=3)
    drop_address: str = Field(min_length=3)

    distance_km: float = Field(gt=0, le=2000)

    scheduled_at: datetime
    return_at: datetime | None = None

    passenger_count: int = Field(default=1, ge=1, le=50)
    special_instructions: str | None = None

    @model_validator(mode="after")
    def validate_return_trip(self):
        if self.trip_type == TripType.ROUND_TRIP:
            if self.return_at is None:
                raise ValueError(
                    "Return date and time are required for round trips"
                )

            if self.return_at <= self.scheduled_at:
                raise ValueError(
                    "Return time must be after pickup time"
                )

        elif self.return_at is not None:
            raise ValueError(
                "Return time is only allowed for round trips"
            )

        return self


class BookingResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: int | None
    vehicle_id: int | None
    route_id: int

    booking_status: BookingStatus
    trip_type: TripType

    estimated_fare: float
    final_fare: float | None

    scheduled_at: datetime | None
    return_at: datetime | None
    passenger_count: int
    special_instructions: str | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class BookingAssignment(BaseModel):
    driver_id: int
    vehicle_id: int



class BookingStatusUpdate(BaseModel):
    booking_status: BookingStatus
    
    
from pydantic import BaseModel, ConfigDict
from datetime import datetime



class TripResponse(BaseModel):
    id: int
    passenger_id: int
    driver_id: int | None
    vehicle_id: int | None
    route_id: int

    booking_status: BookingStatus
    trip_type: TripType

    estimated_fare: float
    final_fare: float | None

    scheduled_at: datetime | None
    started_at: datetime | None
    completed_at: datetime | None
    actual_distance_km: float | None

    passenger_count: int
    created_at: datetime

    pickup_city: str
    drop_city: str
    pickup_address: str
    drop_address: str
    distance_km: float

    model_config = ConfigDict(from_attributes=True)


class TripCompletionRequest(BaseModel):
    actual_distance_km: float = Field(
        gt=0,
        le=3000
    )

    
from pydantic import BaseModel, Field


class DriverLocationUpdate(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class NearbyDriverResponse(BaseModel):
    driver_id: int
    driver_name: str
    vehicle_id: int
    vehicle_name: str
    vehicle_type: str
    registration_number: str
    seating_capacity: int
    rating: float
    latitude: float
    longitude: float
    distance_km: float
    
    

from pydantic import BaseModel, Field
from app.models import TripType


class FareEstimateRequest(BaseModel):
    trip_type: TripType

    vehicle_type: str = Field(
        min_length=2,
        max_length=50
    )

    distance_km: float = Field(
        gt=0,
        le=2000
    )

    passenger_count: int = Field(
        default=1,
        ge=1,
        le=50
    )


class FareEstimateResponse(BaseModel):
    trip_type: TripType
    distance_km: float
    chargeable_distance_km: float
    base_fare: float
    per_km_rate: float
    estimated_fare: float
    currency: str = "INR"

    
    
    
from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=150)
    phone: str = Field(min_length=10, max_length=15)
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    role: str
    
    

class AssignedDriverLocationResponse(BaseModel):
    booking_id: int
    driver_id: int
    driver_name: str
    vehicle_id: int
    vehicle_name: str
    vehicle_type: str
    latitude: float
    longitude: float
    location_updated_at: datetime



class NotificationResponse(BaseModel):
    id: int
    user_id: int
    booking_id: int | None
    title: str
    message: str
    notification_type: str
    is_read: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)



class AgencyRegistrationCreate(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    phone: str = Field(min_length=10, max_length=15)
    email: EmailStr | None = None
    password: str = Field(min_length=8, max_length=128)

    business_name: str = Field(min_length=2, max_length=150)
    registration_number: str | None = Field(
        default=None,
        max_length=100
    )
    business_email: EmailStr | None = None
    business_address: str = Field(min_length=5)
    city: str = Field(min_length=2, max_length=100)


class AgencyResponse(BaseModel):
    id: int
    user_id: int
    business_name: str
    registration_number: str | None
    business_email: str | None
    business_address: str
    city: str
    verification_status: VerificationStatus
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AgencyVerificationUpdate(BaseModel):
    verification_status: VerificationStatus



class AgencyOfferCreate(BaseModel):
    agency_id: int = Field(gt=0)


class AgencyOfferResponse(BaseModel):
    id: int
    booking_id: int
    agency_id: int
    status: AgencyOfferStatus
    offered_at: datetime
    responded_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)

class AgencyOfferRespond(BaseModel):
    status: AgencyOfferStatus