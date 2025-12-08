#!/bin/bash

# 시장 탐방 API cURL 테스트 명령어 모음
# 사용법: ./curl_examples.sh

BASE_URL="http://localhost:8000"
ACCESS_TOKEN=""  # Google 인증 후 받은 토큰을 여기에 설정

echo "🍜 시장 탐방 API 테스트 시작"
echo "================================"

# 헬스체크
echo "📋 1. 헬스체크"
curl -X GET "$BASE_URL/health" \
  -H "Content-Type: application/json" | jq .
echo -e "\n"

# 시장 목록 조회
echo "🏪 2. 시장 목록 조회"
curl -X GET "$BASE_URL/markets/" \
  -H "Content-Type: application/json" | jq .
echo -e "\n"

# 근처 가게 검색 (광장시장 좌표)
echo "📍 3. 근처 가게 검색"
curl -X POST "$BASE_URL/shops/nearby" \
  -H "Content-Type: application/json" \
  -d '{
    "lat": 37.5703,
    "lng": 126.9998,
    "radius_meters": 100
  }' | jq .
echo -e "\n"

# 사진 업로드 초기화 (비회원)
echo "📸 4. 사진 업로드 초기화 (비회원)"
curl -X POST "$BASE_URL/uploads/photo-init" \
  -H "Content-Type: application/json" \
  -d '{
    "lat": 37.5703,
    "lng": 126.9998,
    "taken_at": "2024-01-01T12:00:00Z",
    "is_member": false
  }' | jq .
echo -e "\n"

# 메뉴 텍스트 검색
echo "🔍 5. 메뉴 텍스트 검색"
curl -X GET "$BASE_URL/search/menu-items?q=김치&limit=5" \
  -H "Content-Type: application/json" | jq .
echo -e "\n"

# 인기 메뉴 조회
echo "⭐ 6. 인기 메뉴 조회"
curl -X GET "$BASE_URL/search/popular-menus?limit=5" \
  -H "Content-Type: application/json" | jq .
echo -e "\n"

# 트렌딩 키워드 조회
echo "📈 7. 트렌딩 키워드 조회"
curl -X GET "$BASE_URL/search/trending-keywords?limit=5" \
  -H "Content-Type: application/json" | jq .
echo -e "\n"

# 인증이 필요한 API들 (ACCESS_TOKEN이 설정된 경우에만 실행)
if [ -n "$ACCESS_TOKEN" ]; then
  echo "🔐 인증이 필요한 API 테스트"
  echo "=============================="
  
  # 현재 사용자 정보
  echo "👤 8. 현재 사용자 정보"
  curl -X GET "$BASE_URL/auth/me" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 사용자 프로필 조회
  echo "👤 9. 사용자 프로필 조회"
  curl -X GET "$BASE_URL/users/profile" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 개인화 추천
  echo "💡 10. 개인화 추천"
  curl -X GET "$BASE_URL/recommendations/?limit=5" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 트렌딩 메뉴 추천
  echo "📈 11. 트렌딩 메뉴 추천"
  curl -X GET "$BASE_URL/recommendations/trending?limit=5" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 초보자 추천
  echo "🔰 12. 초보자 추천"
  curl -X GET "$BASE_URL/recommendations/for-beginners?limit=5" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 내 사진 목록
  echo "📷 13. 내 사진 목록"
  curl -X GET "$BASE_URL/uploads/my-photos?limit=5" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 내 다이어리 목록
  echo "📔 14. 내 다이어리 목록"
  curl -X GET "$BASE_URL/diary/my?limit=5" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 내 좋아요 목록
  echo "❤️ 15. 내 좋아요 목록"
  curl -X GET "$BASE_URL/diary/my-likes?limit=5" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
  # 내 핀 목록
  echo "📌 16. 내 핀 목록"
  curl -X GET "$BASE_URL/diary/my-pins?limit=5" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq .
  echo -e "\n"
  
else
  echo "⚠️  ACCESS_TOKEN이 설정되지 않아 인증이 필요한 API는 테스트하지 않습니다."
  echo "   Google 인증 후 받은 토큰을 ACCESS_TOKEN 변수에 설정하세요."
fi

echo "✅ API 테스트 완료!"

# 사용 예시:
# 1. 스크립트에 실행 권한 부여: chmod +x curl_examples.sh
# 2. 실행: ./curl_examples.sh
# 3. 인증 토큰과 함께 실행: ACCESS_TOKEN="your_token_here" ./curl_examples.sh
