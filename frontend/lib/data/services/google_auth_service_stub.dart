import 'google_auth_service_platform.dart';

/// 스텁 구현 (실제로는 사용되지 않음)
class GoogleAuthServiceWeb implements GoogleAuthServicePlatform {
  @override
  Future<String?> signIn() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<void> signOut() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<bool> isSignedIn() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<dynamic> getCurrentUser() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }
  
  void dispose() {}
}

class GoogleAuthServiceMobile implements GoogleAuthServicePlatform {
  @override
  Future<String?> signIn() async {
    throw UnimplementedError('GoogleAuthServiceMobile은 모바일/데스크톱 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<void> signOut() async {
    throw UnimplementedError('GoogleAuthServiceMobile은 모바일/데스크톱 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<bool> isSignedIn() async {
    throw UnimplementedError('GoogleAuthServiceMobile은 모바일/데스크톱 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<dynamic> getCurrentUser() async {
    throw UnimplementedError('GoogleAuthServiceMobile은 모바일/데스크톱 환경에서만 사용할 수 있습니다.');
  }
}

