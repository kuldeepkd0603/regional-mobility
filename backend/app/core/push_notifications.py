
import firebase_admin
from firebase_admin import credentials, messaging
from pathlib import Path


def initialize_firebase():
    try:
        return firebase_admin.get_app()
    except ValueError:
        backend_dir = Path(__file__).resolve().parents[2]

        service_account = (
            backend_dir
            / "secrets"
            / "firebase-service-account.json"
        )

        if not service_account.exists():
            raise FileNotFoundError(
                f"Firebase service account not found: {service_account}"
            )

        cred = credentials.Certificate(str(service_account))

        return firebase_admin.initialize_app(cred)


def send_push_notification(
    fid: str,
    title: str,
    body: str,
    data: dict | None = None
):
    initialize_firebase()

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        data={
            str(key): str(value)
            for key, value in (data or {}).items()
        },
        fid=fid
    )

    return messaging.send(message)
