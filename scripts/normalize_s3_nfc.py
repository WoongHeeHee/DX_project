"""
S3 객체 키를 NFD → NFC로 정규화하는 스크립트.

- DRY_RUN 플래그로 실제 복사/삭제 여부를 제어합니다.
- list_objects_v2 paginator로 전체 객체를 순회합니다.
- NFD로 추정되는 키를 발견하면 NFC 키로 copy 후 원본 delete 합니다.
"""

import boto3
import unicodedata
from botocore.exceptions import ClientError

# 안전을 위해 기본값은 Dry Run
DRY_RUN = True
BUCKET = "market-explorer-photos"


def normalize_key(key: str) -> str:
    """키를 NFC로 정규화하여 반환"""
    return unicodedata.normalize("NFC", key)


def destination_exists(s3, bucket: str, key: str) -> bool:
    """대상 키가 이미 존재하는지 확인"""
    try:
        s3.head_object(Bucket=bucket, Key=key)
        return True
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code")
        if code in ("404", "NoSuchKey", "NotFound"):
            return False
        raise


def main():
    session = boto3.Session()
    creds = session.get_credentials()
    if not creds:
        print("[ERROR] AWS 자격 증명이 설정되어 있지 않습니다.")
        print("        환경변수나 ~/.aws/credentials 를 확인해 주세요.")
        return

    s3 = session.client("s3")
    paginator = s3.get_paginator("list_objects_v2")

    total = 0
    needs_rename = 0
    renamed = 0
    skipped_exists = 0
    errors = 0

    print(f"[INFO] Bucket: {BUCKET}")
    print(f"[INFO] DRY_RUN = {DRY_RUN}")

    for page in paginator.paginate(Bucket=BUCKET):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            total += 1

            nfc_key = normalize_key(key)
            if nfc_key == key:
                continue

            needs_rename += 1

            # 대상 키가 이미 존재하면 덮어쓰지 않고 건너뜁니다.
            if destination_exists(s3, BUCKET, nfc_key):
                print(f"[SKIP] 대상 키가 이미 존재하여 건너뜀: {key} -> {nfc_key}")
                skipped_exists += 1
                continue

            if DRY_RUN:
                print(f"[DRY RUN] Would rename: {key} -> {nfc_key}")
                continue

            try:
                s3.copy_object(
                    Bucket=BUCKET,
                    CopySource={"Bucket": BUCKET, "Key": key},
                    Key=nfc_key,
                    MetadataDirective="COPY",
                )
                s3.delete_object(Bucket=BUCKET, Key=key)
                renamed += 1
                print(f"[RENAMED] {key} -> {nfc_key}")
            except Exception as e:  # noqa: BLE001
                errors += 1
                print(f"[ERROR] {key} -> {nfc_key}: {e}")

    print("---------- Summary ----------")
    print(f"Total objects scanned : {total}")
    print(f"Needs normalization   : {needs_rename}")
    print(f"Renamed (executed)    : {renamed}")
    print(f"Skipped (dest exists) : {skipped_exists}")
    print(f"Errors                : {errors}")
    print(f"DRY_RUN               : {DRY_RUN}")


if __name__ == "__main__":
    main()

