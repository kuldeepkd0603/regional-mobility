
import logging
import time
from datetime import datetime, timezone

from app.db import SessionLocal
from app.models import DriverBookingRequest
from app.services.driver_dispatch import dispatch_booking_requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

logger = logging.getLogger(__name__)

POLL_INTERVAL_SECONDS = 3


def process_expired_requests():
    db = SessionLocal()

    try:
        now = datetime.now(timezone.utc)

        expired_requests = (
            db.query(DriverBookingRequest)
            .filter(
                DriverBookingRequest.status == "pending",
                DriverBookingRequest.expires_at <= now,
            )
            .with_for_update(skip_locked=True)
            .all()
        )

        if not expired_requests:
            return

        booking_ids = set()

        for request in expired_requests:
            request.status = "expired"
            request.responded_at = now
            booking_ids.add(request.booking_id)

        db.commit()

        logger.info(
            "Expired %s driver requests",
            len(expired_requests),
        )

        for booking_id in booking_ids:
            try:
                result = dispatch_booking_requests(db, booking_id)
                logger.info(
                    "Retry dispatch for booking %s: %s",
                    booking_id,
                    result,
                )
            except Exception:
                db.rollback()
                logger.exception(
                    "Retry failed for booking %s",
                    booking_id,
                )

    except Exception:
        db.rollback()
        logger.exception("Worker processing failed")

    finally:
        db.close()


def run_worker():
    logger.info("Raahi driver dispatch worker started")

    while True:
        process_expired_requests()
        time.sleep(POLL_INTERVAL_SECONDS)


if __name__ == "__main__":
    run_worker()
