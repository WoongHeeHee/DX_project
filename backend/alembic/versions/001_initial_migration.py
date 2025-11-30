"""Initial migration

Revision ID: 001
Revises: 
Create Date: 2024-01-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2

# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # PostGIS 확장 활성화
    op.execute('CREATE EXTENSION IF NOT EXISTS postgis')
    
    # users 테이블
    op.create_table('users',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('google_id', sa.String(length=255), nullable=True),
        sa.Column('display_name', sa.String(length=100), nullable=False),
        sa.Column('korean_name', sa.String(length=50), nullable=True),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('country', sa.String(length=2), nullable=True),
        sa.Column('birth_yyyy_mm', sa.String(length=7), nullable=True),
        sa.Column('spice_level', sa.Integer(), nullable=True),
        sa.Column('adventure', sa.Enum('CONSERVATIVE', 'MODERATE', 'ADVENTUROUS', name='adventurelevel'), nullable=True),
        sa.Column('korean_experience', sa.Enum('FIRST_TIME', 'SOME_EXPERIENCE', 'FREQUENT_VISITOR', 'LIVING_IN_KOREA', name='koreanexperience'), nullable=True),
        sa.Column('locale', sa.String(length=5), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('google_id')
    )
    
    # markets 테이블
    op.create_table('markets',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('name_en', sa.String(length=100), nullable=True),
        sa.Column('name_zh', sa.String(length=100), nullable=True),
        sa.Column('name_ja', sa.String(length=100), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('silhouette_url', sa.String(length=500), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    
    # shops 테이블
    op.create_table('shops',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('market_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('name_en', sa.String(length=100), nullable=True),
        sa.Column('name_zh', sa.String(length=100), nullable=True),
        sa.Column('name_ja', sa.String(length=100), nullable=True),
        sa.Column('lat', sa.Float(), nullable=False),
        sa.Column('lng', sa.Float(), nullable=False),
        sa.Column('geom', geoalchemy2.types.Geography(geometry_type='POINT'), nullable=False),
        sa.Column('address', sa.String(length=200), nullable=True),
        sa.Column('last_reported_open_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['market_id'], ['markets.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # menu_items 테이블
    op.create_table('menu_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('market_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('name_en', sa.String(length=100), nullable=True),
        sa.Column('name_zh', sa.String(length=100), nullable=True),
        sa.Column('name_ja', sa.String(length=100), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('rep_image_url', sa.String(length=500), nullable=True),
        sa.Column('tags', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('spice_level', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['market_id'], ['markets.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # shop_menu 테이블
    op.create_table('shop_menu',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('shop_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('menu_item_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('price', sa.Integer(), nullable=True),
        sa.Column('available', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['menu_item_id'], ['menu_items.id'], ),
        sa.ForeignKeyConstraint(['shop_id'], ['shops.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # photos 테이블
    op.create_table('photos',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('uploader_user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('upload_token', sa.String(length=255), nullable=True),
        sa.Column('s3_key', sa.String(length=500), nullable=False),
        sa.Column('thumbnail_s3_key', sa.String(length=500), nullable=True),
        sa.Column('lat', sa.Float(), nullable=False),
        sa.Column('lng', sa.Float(), nullable=False),
        sa.Column('taken_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('processed', sa.Boolean(), nullable=True),
        sa.Column('parsed_items', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['uploader_user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # likes 테이블
    op.create_table('likes',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('menu_item_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['menu_item_id'], ['menu_items.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # pins 테이블
    op.create_table('pins',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('shop_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('menu_item_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['menu_item_id'], ['menu_items.id'], ),
        sa.ForeignKeyConstraint(['shop_id'], ['shops.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # diaries 테이블
    op.create_table('diaries',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('market_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('content', sa.Text(), nullable=True),
        sa.Column('photo_ids', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('keywords', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['market_id'], ['markets.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # keyword_reviews 테이블
    op.create_table('keyword_reviews',
        sa.Column('market_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('keyword', sa.String(length=50), nullable=False),
        sa.Column('count', sa.Integer(), nullable=True),
        sa.Column('last_updated', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['market_id'], ['markets.id'], ),
        sa.PrimaryKeyConstraint('market_id', 'keyword')
    )
    
    # events 테이블
    op.create_table('events',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('action_type', sa.Enum('PHOTO_UPLOAD', 'LIKE', 'PIN', 'DIARY_CREATE', 'SHOP_VISIT', name='actiontype'), nullable=False),
        sa.Column('target_type', sa.Enum('MENU_ITEM', 'SHOP', 'PHOTO', 'DIARY', name='targettype'), nullable=False),
        sa.Column('target_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('timestamp', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # 인덱스 생성
    op.create_index('idx_shops_geom', 'shops', ['geom'], postgresql_using='gist')
    op.create_index('idx_photos_lat_lng', 'photos', ['lat', 'lng'])
    op.create_index('idx_events_user_timestamp', 'events', ['user_id', 'timestamp'])
    op.create_index('idx_likes_user_menu', 'likes', ['user_id', 'menu_item_id'])


def downgrade() -> None:
    op.drop_table('events')
    op.drop_table('keyword_reviews')
    op.drop_table('diaries')
    op.drop_table('pins')
    op.drop_table('likes')
    op.drop_table('photos')
    op.drop_table('shop_menu')
    op.drop_table('menu_items')
    op.drop_table('shops')
    op.drop_table('markets')
    op.drop_table('users')
    
    # Enum 타입 삭제
    op.execute('DROP TYPE IF EXISTS actiontype')
    op.execute('DROP TYPE IF EXISTS targettype')
    op.execute('DROP TYPE IF EXISTS adventurelevel')
    op.execute('DROP TYPE IF EXISTS koreanexperience')
