
from app.models import Notification


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

    return notification
