// lib/core/widgets/kakao_map_widget.dart

import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:webview_flutter/webview_flutter.dart";
import "../../core/theme/app_colors.dart";

/// 카카오 지도 위젯
class KakaoMapWidget extends StatefulWidget {
  final String address;
  final String placeName;
  final double? latitude;
  final double? longitude;
  final double height;
  final String? apiKey; // 카카오 JavaScript API 키

  const KakaoMapWidget({
    super.key,
    required this.address,
    required this.placeName,
    this.latitude,
    this.longitude,
    this.height = 180,
    this.apiKey,
  });

  @override
  State<KakaoMapWidget> createState() => _KakaoMapWidgetState();
}

class _KakaoMapWidgetState extends State<KakaoMapWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _initializeWebView() {
    final apiKey = widget.apiKey ?? dotenv.env["KAKAO_MAP_API_KEY"] ?? "";

    // API 키 확인 (디버깅용)
    if (apiKey.isEmpty) {
      debugPrint("⚠️ 카카오 지도 API 키가 없습니다!");
    } else {
      debugPrint("✅ 카카오 지도 API 키 로드됨: ${apiKey.substring(0, 8)}...");
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint("📍 지도 페이지 로드 시작: $url");
          },
          onPageFinished: (String url) {
            debugPrint("✅ 지도 페이지 로드 완료: $url");
            // JavaScript 실행하여 스크립트 로드 상태 확인
            _controller.runJavaScript("""
              (function() {
                var scripts = document.querySelectorAll('script[src*="dapi.kakao.com"]');
                DebugHandler.postMessage("스크립트 태그 개수: " + scripts.length);
                if (scripts.length > 0) {
                  DebugHandler.postMessage("스크립트 src: " + scripts[0].src);
                }
                DebugHandler.postMessage("kakao 객체 존재: " + (typeof kakao !== 'undefined'));
                DebugHandler.postMessage("kakao.maps 존재: " + (typeof kakao !== 'undefined' && typeof kakao.maps !== 'undefined'));
              })();
            """);
            // 위젯이 아직 마운트되어 있고 dispose되지 않았을 때만 setState 호출
            if (mounted && !_isDisposed) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("❌ 웹뷰 리소스 에러: ${error.description}");
            debugPrint("❌ 에러 코드: ${error.errorCode}");
            debugPrint("❌ 에러 URL: ${error.url}");
            debugPrint("❌ 에러 타입: ${error.errorType}");
            if (mounted && !_isDisposed) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        "ErrorHandler",
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("❌ JavaScript 에러: ${message.message}");
        },
      )
      ..addJavaScriptChannel(
        "DebugHandler",
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("🔍 JavaScript 디버그: ${message.message}");
        },
      )
      ..loadRequest(
        Uri.dataFromString(
          _buildMapHtml(),
          mimeType: "text/html",
          encoding: Encoding.getByName("utf-8"),
        ),
      );
  }

  String _buildMapHtml() {
    // 카카오 지도 API 키 (env 파일에서 읽어오기)
    final apiKey =
        widget.apiKey ??
        dotenv.env["KAKAO_MAP_API_KEY"] ??
        ""; // env 파일에서 KAKAO_MAP_API_KEY 읽기

    // API 키 검증
    if (apiKey.isEmpty) {
      debugPrint("⚠️ 카카오 지도 API 키가 비어있습니다!");
    } else {
      debugPrint(
        "✅ 카카오 지도 API 키 확인됨: ${apiKey.length > 8 ? apiKey.substring(0, 8) : apiKey}...",
      );
    }

    // 좌표가 제공된 경우 사용, 없으면 주소로 검색
    final lat = widget.latitude ?? 37.5700; // 기본값: 광장시장 근처
    final lng = widget.longitude ?? 127.0015;

    // 주소 이스케이프 처리
    final escapedAddress = widget.address
        .replaceAll("'", "\\'")
        .replaceAll("\"", "\\\"");
    final escapedPlaceName = widget.placeName
        .replaceAll("'", "\\'")
        .replaceAll("\"", "\\\"");

    return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>카카오 지도</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
        }
        #map {
            width: 100%;
            height: 100%;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        window.onerror = function(msg, url, line) {
            ErrorHandler.postMessage("에러: " + msg + " (" + url + ":" + line + ")");
            return false;
        };
        
        function initMap() {
            try {
                var container = document.getElementById('map');
                if (!container) {
                    ErrorHandler.postMessage("지도 컨테이너를 찾을 수 없습니다.");
                    return;
                }
                
                var options = {
                    center: new kakao.maps.LatLng($lat, $lng),
                    level: 3
                };
                
                var map = new kakao.maps.Map(container, options);
                
                // 마커 생성
                var markerPosition = new kakao.maps.LatLng($lat, $lng);
                var marker = new kakao.maps.Marker({
                    position: markerPosition
                });
                marker.setMap(map);
                
                // 주소로 좌표 검색 (주소가 제공된 경우)
                var geocoder = new kakao.maps.services.Geocoder();
                geocoder.addressSearch('$escapedAddress', function(result, status) {
                    if (status === kakao.maps.services.Status.OK) {
                        var coords = new kakao.maps.LatLng(result[0].y, result[0].x);
                        map.setCenter(coords);
                        marker.setPosition(coords);
                        
                        // 인포윈도우 생성
                        var infowindow = new kakao.maps.InfoWindow({
                            content: '<div style="padding:5px;font-size:12px;">$escapedPlaceName</div>'
                        });
                        infowindow.open(map, marker);
                    } else {
                        ErrorHandler.postMessage("주소 검색 실패: " + status);
                        // 주소 검색 실패 시 기본 위치에 인포윈도우 표시
                        var infowindow = new kakao.maps.InfoWindow({
                            content: '<div style="padding:5px;font-size:12px;">$escapedPlaceName</div>'
                        });
                        infowindow.open(map, marker);
                    }
                });
            } catch (e) {
                ErrorHandler.postMessage("지도 초기화 에러: " + e.toString());
            }
        }
        
        // 카카오 지도 SDK를 동적으로 로드
        function loadKakaoMapSDK() {
            var apiKey = '$apiKey';
            DebugHandler.postMessage("SDK 로드 시작 - API 키: " + (apiKey ? apiKey.substring(0, 8) + "..." : "없음"));
            
            // API 키가 비어있으면 에러 메시지 표시
            if (!apiKey || apiKey === '') {
                ErrorHandler.postMessage("카카오 지도 API 키가 설정되지 않았습니다. env 파일을 확인해주세요.");
                return;
            }
            
            // 이미 로드되어 있는지 확인
            if (typeof kakao !== 'undefined' && typeof kakao.maps !== 'undefined') {
                DebugHandler.postMessage("kakao 객체가 이미 존재합니다. 지도 초기화 시작...");
                kakao.maps.load(function() {
                    initMap();
                });
                return;
            }
            
            // 이미 스크립트가 추가되어 있는지 확인
            var existingScript = document.querySelector('script[src*="dapi.kakao.com"]');
            if (existingScript) {
                DebugHandler.postMessage("스크립트 태그가 이미 존재합니다. 로드 완료 대기...");
                var checkCount = 0;
                var maxChecks = 100;
                var checkInterval = setInterval(function() {
                    checkCount++;
                    if (typeof kakao !== 'undefined' && typeof kakao.maps !== 'undefined') {
                        clearInterval(checkInterval);
                        DebugHandler.postMessage("kakao 객체 발견! 지도 초기화 시작...");
                        kakao.maps.load(function() {
                            initMap();
                        });
                    } else if (checkCount >= maxChecks) {
                        clearInterval(checkInterval);
                        ErrorHandler.postMessage("카카오 지도 SDK 로드 타임아웃 (10초)");
                    }
                }, 100);
                return;
            }
            
            // 스크립트 동적 생성 및 로드
            DebugHandler.postMessage("스크립트 태그 생성 중...");
            var script = document.createElement('script');
            script.type = 'text/javascript';
            script.async = true;
            script.src = 'https://dapi.kakao.com/v2/maps/sdk.js?appkey=' + apiKey + '&autoload=false';
            
            var loadTimeout = setTimeout(function() {
                ErrorHandler.postMessage("카카오 지도 SDK 스크립트 로드 타임아웃 (10초)");
            }, 10000);
            
            script.onload = function() {
                clearTimeout(loadTimeout);
                DebugHandler.postMessage("스크립트 onload 이벤트 발생");
                setTimeout(function() {
                    if (typeof kakao !== 'undefined' && typeof kakao.maps !== 'undefined') {
                        DebugHandler.postMessage("kakao 객체 확인됨! kakao.maps.load() 호출");
                        kakao.maps.load(function() {
                            DebugHandler.postMessage("kakao.maps.load() 완료, initMap() 호출");
                            initMap();
                        });
                    } else {
                        ErrorHandler.postMessage("스크립트 로드 후 kakao 객체를 찾을 수 없습니다.");
                        DebugHandler.postMessage("kakao 타입: " + typeof kakao);
                    }
                }, 200);
            };
            
            script.onerror = function(error) {
                clearTimeout(loadTimeout);
                var errorMsg = "카카오 지도 SDK 스크립트 로드 실패";
                if (error) {
                    if (error.message) errorMsg += ": " + error.message;
                    if (error.filename) errorMsg += " (파일: " + error.filename + ")";
                    if (error.lineno) errorMsg += " (라인: " + error.lineno + ")";
                    DebugHandler.postMessage("에러 상세: " + JSON.stringify(error));
                }
                ErrorHandler.postMessage(errorMsg);
                DebugHandler.postMessage("스크립트 로드 에러 발생 - src: " + script.src);
                
                // 대안 1: XMLHttpRequest를 사용하여 스크립트 로드 시도
                DebugHandler.postMessage("XMLHttpRequest를 사용한 대안 로드 시도...");
                try {
                    var xhr = new XMLHttpRequest();
                    xhr.open('GET', script.src, true);
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === 4) {
                            if (xhr.status === 200) {
                                DebugHandler.postMessage("XMLHttpRequest로 스크립트 다운로드 성공, eval 실행...");
                                try {
                                    eval(xhr.responseText);
                                    // eval 후 kakao 객체 확인
                                    setTimeout(function() {
                                        if (typeof kakao !== 'undefined' && typeof kakao.maps !== 'undefined') {
                                            DebugHandler.postMessage("XMLHttpRequest 방식으로 kakao 객체 확인됨!");
                                            kakao.maps.load(function() {
                                                initMap();
                                            });
                                        } else {
                                            DebugHandler.postMessage("XMLHttpRequest 방식으로도 kakao 객체를 찾을 수 없습니다.");
                                            ErrorHandler.postMessage("XMLHttpRequest 방식으로도 kakao 객체를 찾을 수 없습니다.");
                                        }
                                    }, 500);
                                } catch (evalErr) {
                                    ErrorHandler.postMessage("eval 실행 에러: " + evalErr.toString());
                                    DebugHandler.postMessage("eval 에러 상세: " + evalErr.toString());
                                }
                            } else {
                                ErrorHandler.postMessage("XMLHttpRequest 실패: HTTP " + xhr.status);
                                DebugHandler.postMessage("XMLHttpRequest 상태: " + xhr.status + " " + xhr.statusText);
                                
                                // 대안 2: fetch 시도 (XMLHttpRequest가 실패한 경우)
                                if (typeof fetch !== 'undefined') {
                                    DebugHandler.postMessage("fetch를 사용한 대안 로드 시도...");
                                    fetch(script.src)
                                        .then(function(response) {
                                            if (!response.ok) {
                                                throw new Error("HTTP " + response.status + ": " + response.statusText);
                                            }
                                            return response.text();
                                        })
                                        .then(function(scriptText) {
                                            DebugHandler.postMessage("fetch로 스크립트 다운로드 성공, eval 실행...");
                                            eval(scriptText);
                                            setTimeout(function() {
                                                if (typeof kakao !== 'undefined' && typeof kakao.maps !== 'undefined') {
                                                    DebugHandler.postMessage("fetch 방식으로 kakao 객체 확인됨!");
                                                    kakao.maps.load(function() {
                                                        initMap();
                                                    });
                                                } else {
                                                    ErrorHandler.postMessage("fetch 방식으로도 kakao 객체를 찾을 수 없습니다.");
                                                }
                                            }, 500);
                                        })
                                        .catch(function(err) {
                                            ErrorHandler.postMessage("fetch 방식도 실패: " + err.toString());
                                            DebugHandler.postMessage("fetch 에러 상세: " + err.toString());
                                        });
                                }
                            }
                        }
                    };
                    xhr.onerror = function() {
                        ErrorHandler.postMessage("XMLHttpRequest 네트워크 에러");
                        DebugHandler.postMessage("XMLHttpRequest 네트워크 에러 발생");
                    };
                    xhr.send();
                } catch (xhrErr) {
                    ErrorHandler.postMessage("XMLHttpRequest 초기화 실패: " + xhrErr.toString());
                    DebugHandler.postMessage("XMLHttpRequest 에러: " + xhrErr.toString());
                }
            };
            
            DebugHandler.postMessage("스크립트를 head에 추가 중...");
            document.head.appendChild(script);
            DebugHandler.postMessage("스크립트 추가 완료, src: " + script.src);
        }
        
        // 스크립트 로드 에러 감지
        window.addEventListener('error', function(e) {
            DebugHandler.postMessage("전역 에러 감지: " + (e.filename || "알 수 없는 파일") + " - " + (e.message || "알 수 없는 에러"));
            if (e.filename && e.filename.indexOf('dapi.kakao.com') !== -1) {
                ErrorHandler.postMessage("카카오 지도 SDK 스크립트 로드 실패: " + (e.message || "알 수 없는 에러"));
            }
        }, true);
        
        // 스크립트 로드 완료 감지
        document.addEventListener('DOMContentLoaded', function() {
            DebugHandler.postMessage("DOM 로드 완료");
            var scripts = document.querySelectorAll('script[src*="dapi.kakao.com"]');
            DebugHandler.postMessage("카카오 지도 스크립트 태그 개수: " + scripts.length);
            if (scripts.length > 0) {
                scripts[0].addEventListener('load', function() {
                    DebugHandler.postMessage("카카오 지도 스크립트 로드 완료");
                });
                scripts[0].addEventListener('error', function(e) {
                    ErrorHandler.postMessage("카카오 지도 스크립트 로드 에러 발생");
                });
            }
        });
        
        // DOM 로드 완료 후 SDK 로드 시작
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function() {
                DebugHandler.postMessage("DOMContentLoaded 이벤트 발생");
                setTimeout(loadKakaoMapSDK, 100);
            });
        } else {
            DebugHandler.postMessage("DOM이 이미 로드됨, 즉시 SDK 로드 시작");
            setTimeout(loadKakaoMapSDK, 100);
        }
    </script>
</body>
</html>
""";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: AppColors.imagePlaceholder,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
