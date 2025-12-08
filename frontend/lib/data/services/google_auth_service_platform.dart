/// 플랫폼별 Google 인증 서비스 구현을 위한 인터페이스
abstract class GoogleAuthServicePlatform {
  Future<String?> signIn();
  Future<void> signOut();
  Future<bool> isSignedIn();
  Future<dynamic> getCurrentUser();
}

