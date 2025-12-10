# Google Maps API 활용 가이드

이 문서는 Flutter 프로젝트에서 Google Maps API를 활용하는 방법을 정리한 가이드입니다.

## 목차
1. [API 키 설정](#api-키-설정)
2. [플랫폼별 설정](#플랫폼별-설정)
3. [Flutter에서 사용하기](#flutter에서-사용하기)
4. [주요 기능](#주요-기능)
5. [참고 자료](#참고-자료)

---

## API 키 설정

### 1. Google Cloud Console에서 API 키 발급

1. [Google Cloud Console](https://console.cloud.google.com/)에 접속
2. 프로젝트 생성 또는 기존 프로젝트 선택
3. **API 및 서비스** > **사용자 인증 정보**로 이동
4. **사용자 인증 정보 만들기** > **API 키** 선택
5. API 키 생성 후 복사하여 보관

### 2. 필요한 API 활성화

**API 및 서비스** > **라이브러리**에서 다음 API를 활성화해야 합니다:

- **Maps JavaScript API** (웹용)
- **Maps SDK for Android** (Android용)
- **Maps SDK for iOS** (iOS용)

### 3. API 키 제한 설정 (권장)

보안을 위해 API 키에 제한을 설정하는 것을 권장합니다:

- **애플리케이션 제한사항**: 
  - 웹: HTTP 리퍼러(웹사이트) 제한
  - Android: 패키지 이름 및 SHA-1 인증서 지문
  - iOS: 번들 ID
- **API 제한사항**: Maps API만 사용하도록 제한

---

## 플랫폼별 설정

### 웹 (Web)

#### 1. index.html에 스크립트 추가

`frontend/web/index.html` 파일에 Google Maps API 스크립트를 추가합니다:

```html
<!-- Google Maps API 스크립트 -->
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&libraries=places"></script>
```

**참고**: 
- `YOUR_API_KEY`를 실제 API 키로 교체
- `libraries=places`는 장소 검색 기능을 사용할 경우 추가
- 현재 프로젝트에서는 `frontend/web/index.html`에 이미 추가되어 있음

#### 2. 환경 변수로 관리 (선택사항)

`window.ENV` 객체에 API 키를 추가할 수 있습니다:

```html
<script>
  window.ENV = {
    API_BASE_URL: 'http://localhost:8000',
    GOOGLE_CLIENT_ID: 'your-google-client-id',
    GOOGLE_MAPS_API_KEY: 'your-google-maps-api-key', // 추가
  };
</script>
```

### Android

#### 1. AndroidManifest.xml 설정

`frontend/android/app/src/main/AndroidManifest.xml`에 API 키를 추가합니다:

```xml
<manifest>
  <application>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_API_KEY"/>
  </application>
</manifest>
```

#### 2. build.gradle 설정

`frontend/android/app/build.gradle.kts`에 Google Maps 의존성 추가:

```kotlin
dependencies {
    implementation("com.google.android.gms:play-services-maps:18.2.0")
}
```

### iOS

#### 1. AppDelegate.swift 설정

`frontend/ios/Runner/AppDelegate.swift`에서 API 키를 설정합니다:

```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**참고**: 현재 프로젝트에서는 이미 설정되어 있음

#### 2. Podfile 설정

`frontend/ios/Podfile`에 Google Maps SDK 추가:

```ruby
pod 'GoogleMaps'
pod 'Google-Maps-iOS-Utils'
```

---

## Flutter에서 사용하기

### 1. 패키지 설치

`pubspec.yaml`에 `google_maps_flutter` 패키지를 추가합니다:

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
```

설치:
```bash
flutter pub get
```

### 2. 기본 지도 위젯 생성

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;

  const MapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController mapController;
  late LatLng center;

  @override
  void initState() {
    super.initState();
    center = LatLng(widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 15.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
      },
      markers: {
        Marker(
          markerId: MarkerId('location'),
          position: center,
          infoWindow: InfoWindow(
            title: widget.placeName ?? '위치',
            snippet: widget.address,
          ),
        ),
      },
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
```

### 3. 주소로 지도 표시하기

주소를 좌표로 변환하려면 Geocoding API를 사용하거나, 백엔드 API를 통해 좌표를 받아올 수 있습니다.

```dart
// 주소를 좌표로 변환하는 예제 (백엔드 API 사용)
Future<LatLng?> getCoordinatesFromAddress(String address) async {
  // 백엔드 API 호출 또는 Geocoding API 사용
  // 예시: API 서비스를 통해 좌표 받아오기
  try {
    final response = await apiService.get('/geocode', params: {'address': address});
    if (response.data != null) {
      return LatLng(
        response.data['lat'],
        response.data['lng'],
      );
    }
  } catch (e) {
    print('좌표 변환 실패: $e');
  }
  return null;
}
```

### 4. 현재 프로젝트에 적용

현재 프로젝트의 `market_map_detail_screen.dart`와 `store_list_screen.dart`에서 빈 공간으로 대체된 지도 영역에 위의 `MapWidget`을 사용할 수 있습니다.

```dart
// market_map_detail_screen.dart 예시
Container(
  width: double.infinity,
  height: double.infinity,
  child: MapWidget(
    latitude: widget.market.lat ?? 37.5665, // 기본값: 서울
    longitude: widget.market.lng ?? 126.9780,
    address: widget.market.address,
    placeName: widget.market.name,
  ),
),
```

---

## 주요 기능

### 1. 마커 추가

```dart
Set<Marker> markers = {
  Marker(
    markerId: MarkerId('marker1'),
    position: LatLng(37.5665, 126.9780),
    infoWindow: InfoWindow(
      title: '마커 제목',
      snippet: '마커 설명',
    ),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  ),
};
```

### 2. 여러 마커 표시

```dart
Set<Marker> createMarkers(List<StoreModel> stores) {
  return stores.map((store) {
    return Marker(
      markerId: MarkerId(store.id),
      position: LatLng(store.lat, store.lng),
      infoWindow: InfoWindow(
        title: store.name,
        snippet: store.address,
      ),
    );
  }).toSet();
}
```

### 3. 지도 스타일 커스터마이징

```dart
GoogleMap(
  mapType: MapType.normal, // normal, satellite, terrain, hybrid
  style: '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      }
    ]
  ''',
  // ...
)
```

### 4. 지도 이동 및 줌 제어

```dart
void _moveToLocation(LatLng location) {
  mapController.animateCamera(
    CameraUpdate.newLatLngZoom(location, 15.0),
  );
}
```

### 5. 현재 위치 표시

```dart
GoogleMap(
  myLocationEnabled: true,
  myLocationButtonEnabled: true,
  // ...
)
```

---

## 환경 변수 관리

### AppConfig에 추가

`frontend/lib/config/app_config.dart`에 Google Maps API 키 getter를 추가할 수 있습니다:

```dart
// Google Maps API
statiuc String get googleMapsApiKey {
  // 웹 환경: window.ENV를 먼저 확인
  if (kIsWeb) {
    final webApiKey = WebEnvHelper.getGoogleMapsApiKey();
    if (webApiKey != nll && webApiKey.isNotEmpty) {
      return webApiKey;
    }
  }
  
  // dotenv에서 확인
  try {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey.contains('your-google-maps-api-key')) {
      return '';
    }
    return apiKey;
  } catch (e) {
    return '';
  }
}
```

---

## 참고 자료

### 공식 문서
- [Google Maps Platform 문서](https://developers.google.com/maps/documentation)
- [Flutter Google Maps 플러그인](https://pub.dev/packages/google_maps_flutter)
- [Maps JavaScript API 가이드](https://developers.google.com/maps/documentation/javascript/overview)

### 유용한 리소스
- [Google Maps Platform 가격](https://developers.google.com/maps/billing-and-pricing/pricing)
- [API 키 보안 모범 사례](https://developers.google.com/maps/api-security-best-practices)
- [지도 스타일 커스터마이징](https://mapstyle.withgoogle.com/)

### 현재 프로젝트 관련 파일
- `frontend/web/index.html`: 웹용 스크립트 설정
- `frontend/ios/Runner/AppDelegate.swift`: iOS용 API 키 설정
- `frontend/lib/features/map/market_map_detail_screen.dart`: 지도 화면
- `frontend/lib/features/map/store_list_screen.dart`: 가게 리스트 화면

---

## 주의사항

1. **API 키 보안**: API 키를 Git에 커밋하지 마세요. 환경 변수나 설정 파일로 관리하세요.
2. **사용량 제한**: Google Maps API는 사용량에 따라 과금됩니다. 무료 할당량을 확인하세요.
3. **플랫폼별 설정**: 웹, Android, iOS 각각 다른 설정이 필요합니다.
4. **좌표 변환**: 주소를 좌표로 변환하려면 Geocoding API가 필요합니다.

---

## 다음 단계

1. `google_maps_flutter` 패키지 설치
2. `MapWidget` 클래스 생성
3. `market_map_detail_screen.dart`와 `store_list_screen.dart`에 적용
4. 마커 및 추가 기능 구현
5. 테스트 및 최적화

