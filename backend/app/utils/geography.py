"""
지리 좌표 관련 유틸리티 함수
PostGIS 없이 lat/lng 기반으로 거리 계산
"""

from math import radians, cos, sin, asin, sqrt


def haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    하버사인 공식을 사용하여 두 지점 간의 거리를 계산 (미터 단위)
    
    Args:
        lat1: 첫 번째 지점의 위도
        lng1: 첫 번째 지점의 경도
        lat2: 두 번째 지점의 위도
        lng2: 두 번째 지점의 경도
    
    Returns:
        두 지점 간의 거리 (미터)
    """
    # 지구 반지름 (미터)
    R = 6371000
    
    # 라디안으로 변환
    lat1, lng1, lat2, lng2 = map(radians, [lat1, lng1, lat2, lng2])
    
    # 위도와 경도의 차이
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    
    # 하버사인 공식
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
    c = 2 * asin(sqrt(a))
    
    # 거리 반환 (미터)
    return R * c


def get_bounding_box(lat: float, lng: float, radius_meters: float) -> tuple:
    """
    주어진 중심점과 반경으로 사각형 경계 상자(bounding box) 계산
    반경 검색 시 먼저 이 범위로 필터링하여 성능 향상
    
    Args:
        lat: 중심점 위도
        lng: 중심점 경도
        radius_meters: 반경 (미터)
    
    Returns:
        (min_lat, max_lat, min_lng, max_lng) 튜플
    """
    # 대략적인 위도/경도 차이 (미터당)
    # 위도: 약 111,000m = 1도
    # 경도: 위도에 따라 다름 (cos(위도) * 111,000m)
    lat_degree_per_meter = 1 / 111000
    lng_degree_per_meter = 1 / (111000 * cos(radians(lat)))
    
    lat_range = radius_meters * lat_degree_per_meter
    lng_range = radius_meters * lng_degree_per_meter
    
    return (
        lat - lat_range,  # min_lat
        lat + lat_range,  # max_lat
        lng - lng_range,  # min_lng
        lng + lng_range   # max_lng
    )

