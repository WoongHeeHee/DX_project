"""마이그레이션 실행 스크립트"""
import sys
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, str(Path(__file__).parent))

from alembic.config import Config
from alembic import command
from app.config import settings

def main():
    """마이그레이션 실행"""
    alembic_ini_path = Path(__file__).parent / "alembic.ini"
    
    if not alembic_ini_path.exists():
        print(f"오류: alembic.ini 파일을 찾을 수 없습니다: {alembic_ini_path}")
        sys.exit(1)
    
    alembic_cfg = Config(str(alembic_ini_path))
    alembic_cfg.set_main_option("sqlalchemy.url", settings.DATABASE_URL)
    
    print(f"데이터베이스 URL: {settings.DATABASE_URL.split('@')[1] if '@' in settings.DATABASE_URL else '설정됨'}")
    print("마이그레이션 실행 중...")
    
    try:
        command.upgrade(alembic_cfg, "head")
        print("마이그레이션 완료!")
    except Exception as e:
        print(f"마이그레이션 실패: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

