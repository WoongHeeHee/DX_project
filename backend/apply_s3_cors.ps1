# S3 버킷 CORS 설정 적용 스크립트 (PowerShell)

$BUCKET_NAME = if ($env:S3_BUCKET_NAME) { $env:S3_BUCKET_NAME } else { "market-explorer-photos" }
$CORS_CONFIG_FILE = "s3_cors_config.json"

Write-Host "S3 버킷 CORS 설정 적용 중..."
Write-Host "버킷 이름: $BUCKET_NAME"
Write-Host "CORS 설정 파일: $CORS_CONFIG_FILE"

# AWS CLI로 CORS 설정 적용
$corsConfig = Get-Content $CORS_CONFIG_FILE -Raw | ConvertFrom-Json

aws s3api put-bucket-cors `
    --bucket "$BUCKET_NAME" `
    --cors-configuration "file://$CORS_CONFIG_FILE"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ CORS 설정이 성공적으로 적용되었습니다." -ForegroundColor Green
    Write-Host ""
    Write-Host "확인 명령어:"
    Write-Host "aws s3api get-bucket-cors --bucket $BUCKET_NAME"
} else {
    Write-Host "❌ CORS 설정 적용 실패" -ForegroundColor Red
    exit 1
}

