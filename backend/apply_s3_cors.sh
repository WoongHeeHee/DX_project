#!/bin/bash

# S3 버킷 CORS 설정 적용 스크립트

BUCKET_NAME="${S3_BUCKET_NAME:-market-explorer-photos}"
CORS_CONFIG_FILE="s3_cors_config.json"

echo "S3 버킷 CORS 설정 적용 중..."
echo "버킷 이름: $BUCKET_NAME"
echo "CORS 설정 파일: $CORS_CONFIG_FILE"

# AWS CLI로 CORS 설정 적용
aws s3api put-bucket-cors \
    --bucket "$BUCKET_NAME" \
    --cors-configuration "file://$CORS_CONFIG_FILE"

if [ $? -eq 0 ]; then
    echo "✅ CORS 설정이 성공적으로 적용되었습니다."
    echo ""
    echo "확인 명령어:"
    echo "aws s3api get-bucket-cors --bucket $BUCKET_NAME"
else
    echo "❌ CORS 설정 적용 실패"
    exit 1
fi

