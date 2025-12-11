"""
AWS S3 서비스 래퍼
"""

import boto3
from botocore.exceptions import ClientError
from botocore.config import Config
from typing import Optional
import logging

from app.config import settings

# requests는 verify_presigned_url에서만 사용 (선택적 의존성)
try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    logging.warning("requests 라이브러리가 없습니다. presigned URL 검증 기능이 비활성화됩니다.")

logger = logging.getLogger(__name__)


class S3Service:
    """S3 서비스 클래스"""
    
    def __init__(self):
        try:
            # S3 클라이언트 설정
            config = Config(
                region_name=settings.AWS_REGION,
                signature_version='s3v4'
            )
            
            # MinIO 사용 시 endpoint_url 설정 (빈 문자열이면 None으로 처리)
            endpoint_url = getattr(settings, 'S3_ENDPOINT_URL', None)
            if endpoint_url and endpoint_url.strip() == "":
                endpoint_url = None
            
            # AWS 자격 증명 확인
            if not settings.AWS_ACCESS_KEY_ID or not settings.AWS_SECRET_ACCESS_KEY:
                logger.warning("AWS 자격 증명이 설정되지 않았습니다. S3 작업이 실패할 수 있습니다.")
            
            self.s3_client = boto3.client(
                's3',
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                config=config,
                endpoint_url=endpoint_url
            )
            
            self.bucket_name = settings.S3_BUCKET_NAME
            
            if not self.bucket_name:
                raise ValueError("S3_BUCKET_NAME이 설정되지 않았습니다.")
            
            # 버킷 존재 확인 및 생성
            self._ensure_bucket_exists()
            
            # CORS 정책 설정
            self._setup_cors_policy()
            
            logger.info(f"S3Service 초기화 완료: bucket={self.bucket_name}, region={settings.AWS_REGION}")
        except Exception as e:
            logger.error(f"S3Service 초기화 실패: {e}", exc_info=True)
            raise
    
    def _ensure_bucket_exists(self):
        """버킷이 존재하지 않으면 생성 (권한 오류는 무시하고 나중에 처리)"""
        try:
            self.s3_client.head_bucket(Bucket=self.bucket_name)
            logger.debug(f"S3 버킷 '{self.bucket_name}' 확인됨")
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                # 버킷이 존재하지 않음 - 생성 시도
                try:
                    if settings.AWS_REGION == 'us-east-1':
                        self.s3_client.create_bucket(Bucket=self.bucket_name)
                    else:
                        self.s3_client.create_bucket(
                            Bucket=self.bucket_name,
                            CreateBucketConfiguration={'LocationConstraint': settings.AWS_REGION}
                        )
                    logger.info(f"S3 버킷 '{self.bucket_name}' 생성됨")
                except ClientError as create_error:
                    logger.warning(f"S3 버킷 생성 실패 (나중에 재시도): {create_error}")
                    # 버킷 생성 실패해도 계속 진행 (나중에 업로드 시도 시 오류 발생)
            elif error_code == '403':
                # 권한 오류 - 로그만 남기고 계속 진행 (실제 업로드 시도 시 오류 발생)
                logger.warning(f"S3 버킷 접근 권한 없음 (403): {self.bucket_name}. 실제 업로드 시도 시 오류가 발생할 수 있습니다.")
            else:
                # 기타 오류 - 로그만 남기고 계속 진행
                logger.warning(f"S3 버킷 확인 실패 ({error_code}): {e}. 실제 업로드 시도 시 오류가 발생할 수 있습니다.")
    
    def _setup_cors_policy(self):
        """S3 버킷에 CORS 정책 설정"""
        try:
            cors_configuration = {
                'CORSRules': [
                    {
                        'AllowedHeaders': ['*'],
                        'AllowedMethods': ['GET', 'PUT', 'POST', 'DELETE', 'HEAD'],
                        'AllowedOrigins': [
                            'http://localhost:3000',
                            'http://localhost:8080',
                            'http://localhost:50000',
                            'http://127.0.0.1:50000',
                            'https://sijanggo.com',
                            'http://sijanggo.com',
                        ],
                        'ExposeHeaders': ['ETag'],
                        'MaxAgeSeconds': 3000
                    }
                ]
            }
            
            self.s3_client.put_bucket_cors(
                Bucket=self.bucket_name,
                CORSConfiguration=cors_configuration
            )
            logger.info(f"S3 버킷 CORS 정책 설정 완료: {self.bucket_name}")
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '403':
                logger.warning(f"S3 버킷 CORS 정책 설정 권한 없음 (403): {self.bucket_name}. 수동으로 설정이 필요할 수 있습니다.")
            else:
                logger.warning(f"S3 버킷 CORS 정책 설정 실패 ({error_code}): {e}. 수동으로 설정이 필요할 수 있습니다.")
        except Exception as e:
            logger.warning(f"S3 버킷 CORS 정책 설정 중 오류 발생: {e}. 수동으로 설정이 필요할 수 있습니다.")
    
    def generate_presigned_upload_url(
        self, 
        s3_key: str, 
        expires_in: int = 3600,
        content_type: str = "image/jpeg"
    ) -> str:
        """업로드용 presigned URL 생성"""
        try:
            # 항상 올바른 region으로 새 클라이언트 생성 (presigned URL 생성용)
            # 이렇게 하면 region 불일치 문제를 방지할 수 있음
            config = Config(
                region_name=settings.AWS_REGION,
                signature_version='s3v4'
            )
            endpoint_url = getattr(settings, 'S3_ENDPOINT_URL', None)
            if endpoint_url and endpoint_url.strip() == "":
                endpoint_url = None
            
            presigned_client = boto3.client(
                's3',
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                config=config,
                endpoint_url=endpoint_url
            )
            
            logger.debug(f"Presigned URL 생성: bucket={self.bucket_name}, key={s3_key}, region={settings.AWS_REGION}, content_type={content_type}")
            
            # Presigned URL 생성 시 서명에 포함될 헤더는 ContentType 파라미터만 지정
            # 다른 헤더(x-amz-acl, Cache-Control 등)를 추가하면 프론트엔드에서도 해당 헤더를 보내야 함
            presigned_url = presigned_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': s3_key,
                    'ContentType': content_type  # 이 값이 요청 헤더의 Content-Type과 정확히 일치해야 함
                    # 주의: 다른 헤더를 여기에 추가하면 서명에 포함되므로 프론트엔드에서도 보내야 함
                },
                ExpiresIn=expires_in
            )
            
            # Presigned URL에서 서명된 헤더 확인 (디버깅용)
            if 'X-Amz-SignedHeaders' in presigned_url:
                import urllib.parse
                parsed = urllib.parse.urlparse(presigned_url)
                query_params = urllib.parse.parse_qs(parsed.query)
                signed_headers = query_params.get('X-Amz-SignedHeaders', [])
                logger.debug(f"Presigned URL 서명된 헤더: {signed_headers}")
            
            logger.debug(f"Presigned URL 생성 완료: {presigned_url[:100]}...")
            return presigned_url
        except ClientError as e:
            logger.error(f"Presigned URL 생성 실패: {e}")
            raise
    
    def generate_presigned_download_url(
        self, 
        s3_key: str, 
        expires_in: int = 3600,
        content_type: Optional[str] = None
    ) -> str:
        """
        다운로드용 presigned URL 생성 (OpenAI Vision API 호환)
        
        OpenAI가 안정적으로 다운로드할 수 있도록:
        - ResponseContentType 명시 (필수)
        - TTL 기본 3600초 (1시간)
        - 올바른 region 설정
        
        Args:
            s3_key: S3 객체 키
            expires_in: 만료 시간 (초, 기본 3600)
            content_type: Content-Type (None이면 자동 감지)
        
        Returns:
            presigned URL
        """
        try:
            # S3 객체의 Content-Type 확인 (이미지 형식에 따라)
            if content_type is None:
                content_type = "image/jpeg"  # 기본값
                if s3_key.endswith('.png'):
                    content_type = "image/png"
                elif s3_key.endswith('.gif'):
                    content_type = "image/gif"
                elif s3_key.endswith('.webp'):
                    content_type = "image/webp"
            
            # 올바른 region으로 클라이언트 생성
            from botocore.config import Config
            config = Config(
                region_name=settings.AWS_REGION,
                signature_version='s3v4'
            )
            endpoint_url = getattr(settings, 'S3_ENDPOINT_URL', None)
            if endpoint_url and endpoint_url.strip() == "":
                endpoint_url = None
            
            presigned_client = boto3.client(
                's3',
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                config=config,
                endpoint_url=endpoint_url
            )
            
            # OpenAI Vision API가 안정적으로 다운로드할 수 있도록 ResponseContentType 명시
            presigned_url = presigned_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': s3_key,
                    'ResponseContentType': content_type  # OpenAI가 올바른 Content-Type을 받도록 명시
                },
                ExpiresIn=expires_in
            )
            
            logger.info(f"Presigned download URL 생성: key={s3_key}, content_type={content_type}, expires_in={expires_in}s, region={settings.AWS_REGION}")
            return presigned_url
        except ClientError as e:
            logger.error(f"Presigned URL 생성 실패: {e}", exc_info=True)
            raise
    
    def verify_presigned_url(self, presigned_url: str) -> bool:
        """
        presigned URL이 유효한지 HEAD 요청으로 검증
        
        Args:
            presigned_url: 검증할 presigned URL
        
        Returns:
            유효하면 True, 아니면 False
        """
        if not HAS_REQUESTS:
            logger.warning("requests 라이브러리가 없어 presigned URL 검증을 스킵합니다.")
            return True  # 검증 불가 시 True 반환 (기존 동작 유지)
        
        try:
            response = requests.head(presigned_url, timeout=10, allow_redirects=True)
            if response.status_code == 200:
                content_type = response.headers.get('Content-Type', '')
                content_length = response.headers.get('Content-Length', '0')
                logger.info(f"Presigned URL 검증 성공: Content-Type={content_type}, Content-Length={content_length} bytes")
                return True
            else:
                logger.warning(f"Presigned URL 검증 실패: status_code={response.status_code}, url={presigned_url[:100]}...")
                return False
        except requests.exceptions.Timeout:
            logger.error(f"Presigned URL 검증 타임아웃: {presigned_url[:100]}...")
            return False
        except Exception as e:
            logger.error(f"Presigned URL 검증 중 오류: {e}, url={presigned_url[:100]}...", exc_info=True)
            return False
    
    def upload_file(
        self, 
        file_path: str, 
        s3_key: str,
        content_type: Optional[str] = None
    ) -> bool:
        """파일 업로드"""
        try:
            extra_args = {}
            if content_type:
                extra_args['ContentType'] = content_type
            
            self.s3_client.upload_file(
                file_path, 
                self.bucket_name, 
                s3_key,
                ExtraArgs=extra_args
            )
            return True
        except ClientError as e:
            logger.error(f"파일 업로드 실패: {e}")
            return False
    
    def download_file(self, s3_key: str, file_path: str) -> bool:
        """파일 다운로드"""
        try:
            self.s3_client.download_file(
                self.bucket_name, 
                s3_key, 
                file_path
            )
            return True
        except ClientError as e:
            logger.error(f"파일 다운로드 실패: {e}")
            return False
    
    def download_object_to_bytes(self, s3_key: str) -> Optional[bytes]:
        """S3 객체를 메모리로 직접 다운로드 (성능 최적화)"""
        try:
            response = self.s3_client.get_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            return response['Body'].read()
        except ClientError as e:
            logger.error(f"S3 객체 다운로드 실패: {e}")
            return None
    
    def delete_object(self, s3_key: str) -> bool:
        """객체 삭제"""
        try:
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            return True
        except ClientError as e:
            logger.error(f"객체 삭제 실패: {e}")
            return False
    
    def object_exists(self, s3_key: str) -> bool:
        """객체 존재 확인"""
        try:
            self.s3_client.head_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            return True
        except ClientError:
            return False
    
    def get_object_url(self, s3_key: str) -> str:
        """객체의 공개 URL 반환 (버킷이 공개인 경우)"""
        if hasattr(settings, 'S3_ENDPOINT_URL') and settings.S3_ENDPOINT_URL:
            # MinIO 사용 시
            return f"{settings.S3_ENDPOINT_URL}/{self.bucket_name}/{s3_key}"
        else:
            # AWS S3 사용 시
            return f"https://{self.bucket_name}.s3.{settings.AWS_REGION}.amazonaws.com/{s3_key}"
