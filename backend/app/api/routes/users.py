
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import User, UserRole
from app.schemas import UserResponse
from app.api.routes.auth import get_current_user, require_roles


router = APIRouter(
    prefix="/users",
    tags=["Users"]
)


# Get one user: Own profile or admin access
@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user = db.query(User).filter(
        User.id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    if (
        current_user.id != user_id
        and current_user.role != UserRole.ADMIN
    ):
        raise HTTPException(
            status_code=403,
            detail="You can only view your own profile"
        )

    return user


# Admin only: Get all users
@router.get("/", response_model=list[UserResponse])
def get_all_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN)
    )
):
    return (
        db.query(User)
        .order_by(User.id.desc())
        .limit(100)
        .all()
    )
