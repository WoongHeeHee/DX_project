/// 카카오 맵 API 설정
/// 
/// 프론트엔드에서 사용하는 카카오 맵 API 키의 단일 관리 지점입니다.
/// 모든 플랫폼(Web/iOS/Android)에서 이 파일의 jsKey를 사용합니다.
class KakaoConfig {
  /// 카카오 JavaScript API 키
  /// 
  /// 카카오 개발자 콘솔(https://developers.kakao.com)에서 발급받은
  /// JavaScript 키입니다. WebView를 통해 카카오 맵 JavaScript API를 사용합니다.
  /// 
  /// 주의사항:
  /// - 카카오 개발자 콘솔에서 플랫폼 설정에 웹 도메인을 등록해야 합니다
  /// - WebView를 통한 사용도 가능하지만, 도메인 제한이 있을 수 있습니다
  static const String jsKey = "3c2cfc4a8b18371d95cd012ed72c9fde";
}