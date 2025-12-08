import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../data/services/auth_service.dart';
import '../data/models/auth_models.dart';
import '../models/enums.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  String? _accessToken;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService);

  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isOnboardingCompleted => _user?.onboardingCompleted ?? false;

  // Google 로그인
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tokenResponse = await _authService.googleLogin();
      _accessToken = tokenResponse.accessToken;
      final userResponse = await _authService.getCurrentUser();
      // UserResponse를 UserModel로 변환
      _user = UserModel(
        id: userResponse.id,
        email: userResponse.email,
        displayName: userResponse.displayName,
        koreanName: userResponse.koreanName,
        country: userResponse.country,
        birthYyyyMm: userResponse.birthYyyyMm,
        spiceLevel: userResponse.spiceLevel,
        locale: UserLocale.fromString(userResponse.locale),
        createdAt: DateTime.now(), // TODO: 서버에서 받아오도록 수정 필요
        onboardingCompleted: false, // TODO: 서버에서 받아오도록 수정 필요
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _accessToken = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 정보 업데이트
  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // 현재 사용자 정보 새로고침
  Future<void> refreshUser() async {
    try {
      final userResponse = await _authService.getCurrentUser();
      // UserResponse를 UserModel로 변환
      _user = UserModel(
        id: userResponse.id,
        email: userResponse.email,
        displayName: userResponse.displayName,
        koreanName: userResponse.koreanName,
        country: userResponse.country,
        birthYyyyMm: userResponse.birthYyyyMm,
        spiceLevel: userResponse.spiceLevel,
        locale: UserLocale.fromString(userResponse.locale),
        createdAt: DateTime.now(), // TODO: 서버에서 받아오도록 수정 필요
        onboardingCompleted: false, // TODO: 서버에서 받아오도록 수정 필요
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

