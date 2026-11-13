
import logging

from app.models import Notification, DeviceToken
from app.core.push_notifications import send_push_notification

logger = logging.getLogger(__name__)


def create_notification(
    db,
    user_id: int,
    title: str,
    message: str,
    notification_type: str,
    booking_id: int | None = None
):
    notification = Notification(
        user_id=user_id,
        booking_id=booking_id,
        title=title,
        message=message,
        notification_type=notification_type,
        is_read=False
    )

    db.add(notification)

    # Send push notification to all registered devices.
    try:
        devices = db.query(DeviceToken).filter(
            DeviceToken.user_id == user_id
        ).all()

        for device in devices:
            try:
                send_push_notification(
                    fid=device.token,
                    title=title,
                    body=message,
                    data={
                        "notification_type": notification_type,
                        "booking_id": str(booking_id or "")
                    }
                )
            except Exception:
                logger.exception(
                    "Push notification failed for device %s",
                    device.id
                )

    except Exception:
        logger.exception(
            "Unable to retrieve registered devices for user %s",
            user_id
        )

    return notification
