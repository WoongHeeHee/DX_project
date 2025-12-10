// lib/core/widgets/google_map_widget.dart

import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps 위젯
/// 
/// 주소 또는 좌표를 받아서 지도를 표시합니다.
class GoogleMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? placeName;
  final double height;
  final Set<Marker>? markers;
  final Function(GoogleMapController)? onMapCreated;
  final double? zoom;

  const GoogleMapWidget({
    Key? key,
    this.latitude,
    this.longitude,
    this.address,
    this.placeName,
    required this.height,
    this.markers,
    this.onMapCreated,
    this.zoom,
  }) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _center;
  bool _isLoading = true;
  bool _mapsApiReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkGoogleMapsApi();
    } else {
      _initializeMap();
    }
  }

  /// 웹 환경에서 Google Maps API 로드 확인
  Future<void> _checkGoogleMapsApi() async {
    if (!kIsWeb) {
      _initializeMap();
      return;
    }

    try {
      // Google Maps API가 이미 로드되어 있는지 확인
      bool isReady = false;
      
      try {
        if (js.context.hasProperty('googleMapsApiReady')) {
          final ready = js.context['googleMapsApiReady'];
          isReady = ready == true;
        }
      } catch (e) {
        debugPrint('[GoogleMapWidget] googleMapsApiReady 확인 중 오류: $e');
      }
      
      // 직접 google 객체 확인
      if (!isReady) {
        try {
          if (js.context.hasProperty('google')) {
            final google = js.context['google'];
            if (google != null) {
              // google.maps가 존재하는지 안전하게 확인
              try {
                final maps = js.context.callMethod('eval', ['typeof google !== "undefined" && typeof google.maps !== "undefined"']);
                if (maps == true) {
                  isReady = true;
                  js.context['googleMapsApiReady'] = true;
                }
              } catch (e) {
                // eval 실패 시 직접 접근 시도
                try {
                  final mapsObj = js.context['google']['maps'];
                  if (mapsObj != null) {
                    isReady = true;
                    js.context['googleMapsApiReady'] = true;
                  }
                } catch (e2) {
                  debugPrint('[GoogleMapWidget] google.maps 접근 중 오류: $e2');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[GoogleMapWidget] Google 객체 확인 중 오류: $e');
        }
      }
      
      if (isReady) {
        debugPrint('[GoogleMapWidget] ✅ Google Maps API가 이미 준비되어 있습니다.');
        _mapsApiReady = true;
        _initializeMap();
        return;
      }

      // Google Maps API 로드 대기
      int attempts = 0;
      const maxAttempts = 30; // 최대 15초 대기 (500ms * 30)

      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // window.googleMapsApiReady 확인
        try {
          if (js.context.hasProperty('googleMapsApiReady')) {
            final ready = js.context['googleMapsApiReady'];
            if (ready == true) {
              debugPrint('[GoogleMapWidget] ✅ Google Maps API 로드 확인 완료');
              _mapsApiReady = true;
              _initializeMap();
              return;
            }
          }
        } catch (e) {
          debugPrint('[GoogleMapWidget] googleMapsApiReady 확인 중 오류: $e');
        }

        // 직접 google 객체 확인
        try {
          if (js.context.hasProperty('google')) {
            final google = js.context['google'];
            if (google != null) {
              try {
                // google.maps가 존재하는지 확인
                final mapsCheck = js.context.callMethod('eval', ['typeof google !== "undefined" && typeof google.maps !== "undefined"']);
                if (mapsCheck == true) {
                  debugPrint('[GoogleMapWidget] ✅ Google Maps API 객체 발견');
                  js.context['googleMapsApiReady'] = true;
                  _mapsApiReady = true;
                  _initializeMap();
                  return;
                }
              } catch (e) {
                // eval 실패 시 직접 접근 시도
                try {
                  final mapsObj = js.context['google']['maps'];
                  if (mapsObj != null) {
                    debugPrint('[GoogleMapWidget] ✅ Google Maps API 객체 발견 (직접 접근)');
                    js.context['googleMapsApiReady'] = true;
                    _mapsApiReady = true;
                    _initializeMap();
                    return;
                  }
                } catch (e2) {
                  // 무시하고 계속 시도
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[GoogleMapWidget] Google Maps API 확인 중 오류: $e');
        }

        attempts++;
      }

      // 타임아웃: 에러 메시지 표시
      debugPrint('[GoogleMapWidget] ❌ Google Maps API 로드 타임아웃 (${maxAttempts * 500}ms 대기)');
      setState(() {
        _mapsApiReady = false;
        _errorMessage = 'Google Maps API를 로드할 수 없습니다. 네트워크 연결을 확인해주세요.';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('[GoogleMapWidget] Google Maps API 확인 중 예외 발생: $e');
      debugPrint('[GoogleMapWidget] 스택 트레이스: $stackTrace');
      setState(() {
        _mapsApiReady = false;
        _errorMessage = 'Google Maps API 확인 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeMap() async {
    // 좌표가 직접 제공된 경우
    if (widget.latitude != null && widget.longitude != null) {
      setState(() {
        _center = LatLng(widget.latitude!, widget.longitude!);
        _isLoading = false;
      });
      return;
    }

    // 주소만 제공된 경우 - 좌표 변환 필요
    // TODO: Geocoding API를 사용하여 주소를 좌표로 변환
    // 현재는 기본값(서울) 사용
    if (widget.address != null) {
      // 임시로 서울 좌표 사용
      setState(() {
        _center = const LatLng(37.5665, 126.9780);
        _isLoading = false;
      });
    } else {
      // 좌표도 주소도 없는 경우 기본값
      setState(() {
        _center = const LatLng(37.5665, 126.9780);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹 환경에서 Google Maps API가 로드되지 않은 경우
    if (kIsWeb && !_mapsApiReady && _errorMessage != null) {
      return Container(
        height: widget.height,
        color: const Color(0xFFF7F7F8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _checkGoogleMapsApi();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 웹 환경에서 API가 아직 준비되지 않은 경우 로딩 표시
    if (kIsWeb && !_mapsApiReady) {
      return Container(
        height: widget.height,
        color: const Color(0xFFF7F7F8),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoading || _center == null) {
      return Container(
        height: widget.height,
        color: const Color(0xFFF7F7F8),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 웹 환경에서 Google Maps API 최종 확인
    if (kIsWeb) {
      try {
        // google 객체가 존재하는지 확인
        if (!js.context.hasProperty('google')) {
          debugPrint('[GoogleMapWidget] ⚠️ Google 객체가 없습니다. 대기 중...');
          return Container(
            height: widget.height,
            color: const Color(0xFFF7F7F8),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final google = js.context['google'];
        if (google == null || js.context['google']['maps'] == null) {
          debugPrint('[GoogleMapWidget] ⚠️ Google Maps 객체가 없습니다. 대기 중...');
          // 다시 확인 시도
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _checkGoogleMapsApi();
            }
          });
          return Container(
            height: widget.height,
            color: const Color(0xFFF7F7F8),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      } catch (e) {
        debugPrint('[GoogleMapWidget] Google Maps API 확인 중 오류: $e');
        return Container(
          height: widget.height,
          color: const Color(0xFFF7F7F8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '지도를 불러올 수 없습니다.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _checkGoogleMapsApi();
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        );
      }
    }

    // GoogleMap 위젯을 에러 바운더리로 감싸기
    return Builder(
      builder: (context) {
        try {
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center!,
              zoom: widget.zoom ?? 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              debugPrint('[GoogleMapWidget] ✅ 지도 생성 완료');
              if (widget.onMapCreated != null) {
                widget.onMapCreated!(controller);
              }
            },
            markers: widget.markers ?? _createDefaultMarkers(),
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          );
        } catch (e, stackTrace) {
          debugPrint('[GoogleMapWidget] ❌ GoogleMap 위젯 생성 중 오류: $e');
          debugPrint('[GoogleMapWidget] 스택 트레이스: $stackTrace');
          return Container(
            height: widget.height,
            color: const Color(0xFFF7F7F8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    '지도를 표시할 수 없습니다.\n잠시 후 다시 시도해주세요.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                        _mapsApiReady = false;
                      });
                      _checkGoogleMapsApi();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Set<Marker> _createDefaultMarkers() {
    if (_center == null) return {};
    
    return {
      Marker(
        markerId: const MarkerId('location'),
        position: _center!,
        infoWindow: InfoWindow(
          title: widget.placeName ?? '위치',
          snippet: widget.address,
        ),
      ),
    };
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

