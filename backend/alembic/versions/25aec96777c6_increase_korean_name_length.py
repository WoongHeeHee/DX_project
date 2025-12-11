"""increase_korean_name_length

Revision ID: 25aec96777c6
Revises: 001
Create Date: 2025-12-12 02:57:46.950683

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '25aec96777c6'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # korean_name 필드 길이를 50에서 100으로 증가
    op.alter_column('users', 'korean_name',
                    existing_type=sa.String(length=50),
                    type_=sa.String(length=100),
                    existing_nullable=True)


def downgrade() -> None:
    # korean_name 필드 길이를 100에서 50으로 되돌림
    op.alter_column('users', 'korean_name',
                    existing_type=sa.String(length=100),
                    type_=sa.String(length=50),
                    existing_nullable=True)
