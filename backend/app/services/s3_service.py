"""
AWS S3 서비스 래퍼
"""

import boto3
from botocore.exceptions import ClientError
from botocore.config import Config
from typing import Optional
import logging

from app.config import settings

logger = logging.getLogger(__name__)


class S3Service:
    """S3 서비스 클래스"""
    
    def __init__(self):
        # S3 클라이언트 설정
        config = Config(
            region_name=settings.AWS_REGION,
            signature_version='s3v4'
        )
        
        # MinIO 사용 시 endpoint_url 설정
        endpoint_url = getattr(settings, 'S3_ENDPOINT_URL', None)
        
        self.s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            config=config,
            endpoint_url=endpoint_url
        )
        
        self.bucket_name = settings.S3_BUCKET_NAME
        
        # 버킷 존재 확인 및 생성
        self._ensure_bucket_exists()
    
    def _ensure_bucket_exists(self):
        """버킷이 존재하지 않으면 생성"""
        try:
            self.s3_client.head_bucket(Bucket=self.bucket_name)
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                # 버킷이 존재하지 않음 - 생성
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
                    logger.error(f"S3 버킷 생성 실패: {create_error}")
                    raise
            else:
                logger.error(f"S3 버킷 확인 실패: {e}")
                raise
    
    def generate_presigned_upload_url(
        self, 
        s3_key: str, 
        expires_in: int = 3600,
        content_type: str = "image/jpeg"
    ) -> str:
        """업로드용 presigned URL 생성"""
        try:
            presigned_url = self.s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': s3_key,
                    'ContentType': content_type
                },
                ExpiresIn=expires_in
            )
            return presigned_url
        except ClientError as e:
            logger.error(f"Presigned URL 생성 실패: {e}")
            raise
    
    def generate_presigned_download_url(
        self, 
        s3_key: str, 
        expires_in: int = 3600
    ) -> str:
        """다운로드용 presigned URL 생성"""
        try:
            presigned_url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': s3_key
                },
                ExpiresIn=expires_in
            )
            return presigned_url
        except ClientError as e:
            logger.error(f"Presigned URL 생성 실패: {e}")
            raise
    
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
