
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Notification, User
from app.schemas import NotificationResponse
from app.api.routes.auth import get_current_user

from pydantic import BaseModel
from typing import Literal
from app.models import DeviceToken
router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"]
)

class DeviceTokenRequest(BaseModel):
    token: str
    platform: Literal["android", "ios"] = "android"
# 1. Get logged-in user's notifications
@router.get("/", response_model=list[NotificationResponse])
def get_notifications(
    unread_only: bool = False,
    limit: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Notification).filter(
        Notification.user_id == current_user.id
    )

    if unread_only:
        query = query.filter(Notification.is_read == False)

    return (
        query
        .order_by(Notification.created_at.desc())
        .limit(limit)
        .all()
    )


# 2. Mark one notification as read
@router.patch("/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()

    if not notification:
        raise HTTPException(
            status_code=404,
            detail="Notification not found"
        )

    notification.is_read = True

    db.commit()

    return {
        "message": "Notification marked as read",
        "notification_id": notification.id,
        "is_read": True
    }


# 3. Mark all notifications as read
@router.patch("/read-all")
def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    updated_count = (
        db.query(Notification)
        .filter(
            Notification.user_id == current_user.id,
            Notification.is_read == False
        )
        .update(
            {Notification.is_read: True},
            synchronize_session=False
        )
    )

    db.commit()

    return {
        "message": "All notifications marked as read",
        "updated_count": updated_count
    }
@router.post("/device-token")
def register_device_token(
    data: DeviceTokenRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    device = db.query(DeviceToken).filter(
        DeviceToken.token == data.token
    ).first()

    if device:
        device.user_id = current_user.id
        device.platform = data.platform
    else:
        device = DeviceToken(
            user_id=current_user.id,
            token=data.token,
            platform=data.platform
        )
        db.add(device)

    db.commit()

    return {
        "message": "Device token registered successfully"
    }


@router.delete("/device-token")
def remove_device_token(
    token: str = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    device = db.query(DeviceToken).filter(
        DeviceToken.token == token,
        DeviceToken.user_id == current_user.id
    ).first()

    if device:
        db.delete(device)
        db.commit()

    return {
        "message": "Device token removed successfully"
    }