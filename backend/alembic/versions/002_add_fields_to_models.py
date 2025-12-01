"""add fields to models

Revision ID: 002
Revises: 001
Create Date: 2024-12-20 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # users 테이블에 onboarding_completed 추가
    op.add_column('users', sa.Column('onboarding_completed', sa.Boolean(), nullable=True, server_default='false'))
    
    # shops 테이블에 필드 추가
    op.add_column('shops', sa.Column('rep_image_url', sa.String(length=500), nullable=True))
    op.add_column('shops', sa.Column('open_time', sa.String(length=5), nullable=True))
    op.add_column('shops', sa.Column('close_time', sa.String(length=5), nullable=True))
    op.add_column('shops', sa.Column('closed_days', postgresql.JSONB(astext_type=sa.Text()), nullable=True))
    
    # menu_items 테이블에 category 추가
    op.add_column('menu_items', sa.Column('category', sa.String(length=50), nullable=True))
    
    # photos 테이블에 필드 추가
    op.add_column('photos', sa.Column('shop_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('photos', sa.Column('photo_type', sa.String(length=20), nullable=True))
    
    # photos 테이블에 shop_id 외래키 추가
    op.create_foreign_key(
        'fk_photos_shop_id',
        'photos', 'shops',
        ['shop_id'], ['id'],
        ondelete='SET NULL'
    )


def downgrade() -> None:
    # 외래키 제거
    op.drop_constraint('fk_photos_shop_id', 'photos', type_='foreignkey')
    
    # photos 테이블 필드 제거
    op.drop_column('photos', 'photo_type')
    op.drop_column('photos', 'shop_id')
    
    # menu_items 테이블 필드 제거
    op.drop_column('menu_items', 'category')
    
    # shops 테이블 필드 제거
    op.drop_column('shops', 'closed_days')
    op.drop_column('shops', 'close_time')
    op.drop_column('shops', 'open_time')
    op.drop_column('shops', 'rep_image_url')
    
    # users 테이블 필드 제거
    op.drop_column('users', 'onboarding_completed')

