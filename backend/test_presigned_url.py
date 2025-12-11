"""
Presigned URL 검증 테스트 스크립트
"""

import sys
import os

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.services.s3_service import S3Service
from app.config import settings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def test_presigned_url_generation():
    """Presigned URL 생성 및 검증 테스트"""
    print("=" * 60)
    print("Presigned URL 생성 및 검증 테스트")
    print("=" * 60)
    
    s3_service = S3Service()
    test_s3_key = "photos/test_image.jpg"  # 실제 존재하는 키로 변경 필요
    
    # 1. Presigned URL 생성
    print("\n1. Presigned URL 생성 중...")
    presigned_url = s3_service.generate_presigned_download_url(
        s3_key=test_s3_key,
        expires_in=3600,
        content_type="image/jpeg"
    )
    print(f"✅ Presigned URL 생성 완료")
    print(f"   URL (처음 100자): {presigned_url[:100]}...")
    print(f"   전체 URL: {presigned_url}")
    
    # 2. Presigned URL 검증
    print("\n2. Presigned URL 검증 중...")
    is_valid = s3_service.verify_presigned_url(presigned_url)
    if is_valid:
        print("✅ Presigned URL 검증 성공")
    else:
        print("❌ Presigned URL 검증 실패")
    
    # 3. 브라우저 테스트 안내
    print("\n3. 브라우저 테스트:")
    print(f"   위의 전체 URL을 브라우저에 붙여넣어 이미지가 열리는지 확인하세요.")
    print(f"   URL: {presigned_url}")
    
    # 4. curl 테스트 안내
    print("\n4. curl 테스트 명령어:")
    print(f"   curl -I \"{presigned_url}\"")
    print(f"   예상 응답: HTTP/1.1 200 OK, Content-Type: image/jpeg")
    
    return presigned_url


def test_region_and_endpoint():
    """Region 및 Endpoint 설정 확인"""
    print("\n" + "=" * 60)
    print("Region 및 Endpoint 설정 확인")
    print("=" * 60)
    
    print(f"AWS_REGION: {settings.AWS_REGION}")
    print(f"S3_ENDPOINT_URL: {getattr(settings, 'S3_ENDPOINT_URL', 'None')}")
    print(f"S3_BUCKET_NAME: {settings.S3_BUCKET_NAME}")
    
    if hasattr(settings, 'S3_ENDPOINT_URL') and settings.S3_ENDPOINT_URL:
        print("⚠️  MinIO 등 커스텀 엔드포인트 사용 중")
    else:
        print("✅ AWS S3 표준 엔드포인트 사용 중")


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("Presigned URL 테스트 스크립트")
    print("=" * 60)
    
    try:
        # Region 및 Endpoint 확인
        test_region_and_endpoint()
        
        # Presigned URL 생성 및 검증
        presigned_url = test_presigned_url_generation()
        
        print("\n" + "=" * 60)
        print("✅ 테스트 완료")
        print("=" * 60)
        print("\n다음 단계:")
        print("1. 브라우저에서 presigned URL 열기")
        print("2. curl로 HEAD 요청 테스트")
        print("3. OpenAI Vision API 호출 테스트")
        
    except Exception as e:
        print(f"\n❌ 테스트 실패: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

