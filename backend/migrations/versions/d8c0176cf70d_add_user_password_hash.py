
"""add user password hash

Revision ID: d8c0176cf70d
Revises: 740ac39fba34
Create Date: 2026-10-31 23:59:11.104109
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'd8c0176cf70d'
down_revision: Union[str, Sequence[str], None] = '740ac39fba34'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'users',
        sa.Column(
            'hashed_password',
            sa.String(length=255),
            nullable=True
        )
    )


def downgrade() -> None:
    op.drop_column('users', 'hashed_password')
