import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import 'google_auth_service_platform.dart';

/// Web 전용 Google 인증 서비스 (Google Identity Services 기반)
class GoogleAuthServiceWeb implements GoogleAuthServicePlatform {
  final _idTokenController = StreamController<String?>.broadcast();
  Stream<String?> get onIdToken => _idTokenController.stream;
  
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  
  GoogleAuthServiceWeb() {
    _initializeMessageListener();
  }
  
  /// window.onMessage 리스너 초기화
  void _initializeMessageListener() {
    if (!kIsWeb) {
      return;
    }
    
    // dart:html을 사용하여 window.onMessage 리스너 등록
    _messageSubscription = html.window.onMessage.listen((event) {
      if (event.data is Map) {
        final data = event.data as Map<String, dynamic>;
        
        if (data['type'] == 'GOOGLE_SIGN_IN') {
          final idToken = data['idToken'] as String?;
          if (idToken != null && idToken.isNotEmpty) {
            debugPrint('Google 로그인: id_token 수신 완료');
            _idTokenController.add(idToken);
          }
        } else if (data['type'] == 'GOOGLE_SIGN_IN_ERROR') {
          final error = data['error'] as String?;
          debugPrint('Google 로그인 오류: $error');
          _idTokenController.add(null);
        }
      }
    });
  }
  
  /// Google 로그인 (id_token 반환)
  /// 전체 페이지 리디렉션 방식: 리디렉션만 수행하고 즉시 null 반환
  /// 실제 id_token 처리는 /auth/callback 경로의 AuthCallbackScreen에서 수행됨
  @override
  Future<String?> signIn() async {
    if (!kIsWeb) {
      throw Exception('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
    }
    
    final clientId = AppConfig.googleClientId;
    if (clientId.isEmpty) {
      throw Exception('Google Client ID가 설정되지 않았습니다. index.html의 window.ENV.GOOGLE_CLIENT_ID를 확인해주세요.');
    }
    
    // GIS가 초기화될 때까지 대기
    await _waitForGISInitialization();
    
    try {
      // JavaScript 함수 호출하여 전체 페이지 리디렉션 수행
      js.context.callMethod('eval', ['window.triggerGoogleSignIn()']);
      
      debugPrint('Google 로그인: 전체 페이지 리디렉션 시작');
      
      // 전체 페이지 리디렉션이 발생하므로 이 메서드는 완료되지 않음
      // 리디렉션 후 /auth/callback 경로에서 AuthCallbackScreen이 처리함
      // 여기서는 null을 반환하여 리디렉션이 발생했음을 나타냄
      return null;
    } catch (e, stackTrace) {
      debugPrint('Google 로그인 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      throw Exception('Google 로그인 실패: $e');
    }
  }
  
  /// GIS 초기화 대기
  Future<void> _waitForGISInitialization() async {
    int attempts = 0;
    const maxAttempts = 20; // 최대 10초 대기
    
    while (attempts < maxAttempts) {
      try {
        final isInitialized = js.context.callMethod('eval', [
          'typeof window.triggerGoogleSignIn === "function"'
        ]) as bool?;
        
        if (isInitialized == true) {
          debugPrint('Google Identity Services 초기화 확인 완료');
          return;
        }
      } catch (e) {
        debugPrint('GIS 초기화 확인 중 오류: $e');
      }
      
      attempts++;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    throw Exception('Google Identity Services 초기화가 완료되지 않았습니다. index.html을 확인해주세요.');
  }
  
  /// 로그아웃
  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      return;
    }
    
    // GIS에서는 로그아웃이 자동으로 처리됨
    debugPrint('Google 로그아웃: 웹 환경에서는 자동 처리됨');
  }
  
  /// 현재 로그인된 사용자 확인
  @override
  Future<bool> isSignedIn() async {
    // 웹 환경에서는 항상 false 반환 (GIS는 상태 관리하지 않음)
    return false;
  }
  
  /// 현재 사용자 정보 가져오기
  @override
  Future<dynamic> getCurrentUser() async {
    // 웹 환경에서는 지원하지 않음
    return null;
  }
  
  void dispose() {
    _messageSubscription?.cancel();
    _idTokenController.close();
  }
}

/// Mobile 스텁 (웹 환경에서는 사용되지 않음)
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
