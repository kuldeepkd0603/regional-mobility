
"""add driver location fields

Revision ID: 740ac39fba34
Revises: 70282ba38b92
Create Date: 2026-10-31 23:16:48.644252
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '740ac39fba34'
down_revision: Union[str, Sequence[str], None] = '70282ba38b92'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'drivers',
        sa.Column('latitude', sa.Float(), nullable=True)
    )

    op.add_column(
        'drivers',
        sa.Column('longitude', sa.Float(), nullable=True)
    )

    op.add_column(
        'drivers',
        sa.Column(
            'location_updated_at',
            sa.DateTime(timezone=True),
            nullable=True
        )
    )


def downgrade() -> None:
    op.drop_column('drivers', 'location_updated_at')
    op.drop_column('drivers', 'longitude')
    op.drop_column('drivers', 'latitude')
