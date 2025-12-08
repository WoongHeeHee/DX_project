import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../services/menu_service.dart';
import '../services/search_service.dart';
import '../services/recommendation_service.dart';
import '../services/photo_service.dart';
import '../services/google_auth_service.dart';
import '../services/user_service.dart';
import '../services/market_photo_service.dart';
import '../services/shop_service.dart';
import '../services/diary_service.dart';

/// API 서비스 레포지토리 (싱글톤)
class ApiRepository {
  static final ApiRepository _instance = ApiRepository._internal();
  factory ApiRepository() => _instance;
  ApiRepository._internal();

  late final ApiService _apiService;
  late final AuthService _authService;
  late final MarketService _marketService;
  late final MenuService _menuService;
  late final SearchService _searchService;
  late final RecommendationService _recommendationService;
  late final PhotoService _photoService;
  late final GoogleAuthService _googleAuthService;
  late final UserService _userService;
  late final MarketPhotoService _marketPhotoService;
  late final ShopService _shopService;
  late final DiaryService _diaryService;

  void initialize() {
    _apiService = ApiService();
    _authService = AuthService(_apiService);
    _marketService = MarketService(_apiService);
    _menuService = MenuService(_apiService);
    _searchService = SearchService(_apiService);
    _recommendationService = RecommendationService(_apiService);
    _photoService = PhotoService(_apiService);
    _googleAuthService = GoogleAuthService();
    _userService = UserService(_apiService);
    _marketPhotoService = MarketPhotoService(_apiService);
    _shopService = ShopService(_apiService);
    _diaryService = DiaryService(_apiService);
  }

  ApiService get apiService => _apiService;
  AuthService get authService => _authService;
  MarketService get marketService => _marketService;
  MenuService get menuService => _menuService;
  SearchService get searchService => _searchService;
  RecommendationService get recommendationService => _recommendationService;
  PhotoService get photoService => _photoService;
  GoogleAuthService get googleAuthService => _googleAuthService;
  UserService get userService => _userService;
  MarketPhotoService get marketPhotoService => _marketPhotoService;
  ShopService get shopService => _shopService;
  DiaryService get diaryService => _diaryService;
}

