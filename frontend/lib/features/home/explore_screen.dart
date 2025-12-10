// lib/features/home/explore_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/widgets/custom_dropdown.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../core/widgets/drag_only_scroll_behavior.dart";
import "../../widgets/bottom_navigation_bar.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/models/market_models.dart" as api_models;
import "../../data/models/menu_models.dart";
import "constants/must_try_items.dart";
import "models/filter_model.dart";
import "models/market_model.dart";
import "models/food_model.dart";
import "models/trend_banner_model.dart";

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _apiRepository = ApiRepository();
  String selectedCategory = "Meals";
  String selectedRegion = "서울"; // 기본값은 서울
  int currentFoodPage = 0; // Korean Street Food 페이지네이션 인덱스
  int currentTrendBannerIndex = 0; // Now Trend 배너 인덱스
  late PageController _trendBannerController;
  bool _isLoading = false;
  String? _koreanName;
  String _userLocale = 'ko';

  // API로 가져온 데이터
  List<TrendBannerModel> _trendBanners = [];
  // List<MenuItemModel> _recommendations = []; // TODO: 추후 사용 예정
  List<MarketModel> _markets = [];
  Map<String, List<MenuItemModel>> _foodsByCategory = {};
  List<MenuItemModel> _nationalAgeMenus = [];
  List<MenuItemModel> _savedBasedMenus = [];
  Map<String, List<MarketModel>> _marketsByRegion = {};
  Map<String, MenuItemModel> _menuIdToModel = {}; // 메뉴 ID -> MenuItemModel 매핑

  // 고정 지역 탭
  static const List<String> _regions = ["서울", "경기", "인천", "강원", "광주", "전라도", "경상도", "대구", "제주"];

  // 시장 시드 데이터 (지역/이름/ID)
  static const List<Map<String, String>> _marketSeeds = [
    {"region": "서울", "name": "광장시장", "id": "MA0001"},
    {"region": "서울", "name": "망원시장", "id": "MA0002"},
    {"region": "서울", "name": "통인시장", "id": "MA0003"},
    {"region": "서울", "name": "서울풍물시장", "id": "MA0004"},
    {"region": "경기", "name": "수원남문로데오시장", "id": "MA0005"},
    {"region": "인천", "name": "신포국제시장", "id": "MA0006"},
    {"region": "강원", "name": "단양 구경시장", "id": "MA0007"},
    {"region": "강원", "name": "속초관광수산시장", "id": "MA0008"},
    {"region": "강원", "name": "정선5일장", "id": "MA0009"},
    {"region": "광주", "name": "광주 양동시장", "id": "MA0010"},
    {"region": "전라도", "name": "순천 아랫장", "id": "MA0011"},
    {"region": "경상도", "name": "안동 구시장", "id": "MA0012"},
    {"region": "대구", "name": "대구 서문시장", "id": "MA0013"},
    {"region": "제주", "name": "동문재래시장", "id": "MA0014"},
    {"region": "제주", "name": "서귀포 매일올레시장", "id": "MA0015"},
  ];

  // S3 플레이스홀더용 샘플 (이름/ID 매칭)
  static const List<Map<String, String>> _samplePlaceholders = [
    {"id": "ME155", "name": "떡볶이"},
    {"id": "ME012", "name": "김밥"},
    {"id": "ME148", "name": "닭강정"},
  ];

  // Korean Street Food 데이터
  Map<String, List<FoodModel>> get foodsByCategory {
    // API에서 가져온 데이터를 FoodModel로 변환
    if (_foodsByCategory.isEmpty) {
      // 로딩 중이거나 데이터가 없을 때 더미 데이터 반환
      return {
        "Meals": _getMealsFoods(),
        "Snacks": _getSnacksFoods(),
        "Sweets": _getSweetsFoods(),
        "Drink": _getDrinkFoods(),
      };
    }

    // MenuItemModel을 FoodModel로 변환
    return {
      "Meals": _convertMenuItemsToFoodModels(_foodsByCategory["Meals"] ?? []),
      "Snacks": _convertMenuItemsToFoodModels(_foodsByCategory["Snacks"] ?? []),
      "Sweets": _convertMenuItemsToFoodModels(_foodsByCategory["Sweets"] ?? []),
      "Drink": _convertMenuItemsToFoodModels(_foodsByCategory["Drink"] ?? []),
    };
  }

  /// 단일 MenuItemModel을 FoodModel로 변환 (라우팅용)
  FoodModel _convertMenuItemToFoodModel(MenuItemModel menu) {
    final locale = _userLocale;
    final baseName = menu.name; // 이미지 경로는 항상 ko 이름 사용
    final contains = (menu.getContainsByLocale(locale) ?? '')
        .split(RegExp(r',\s*'))
        .where((e) => e.isNotEmpty)
        .toList();
    final mayContains = (menu.getMayContainsByLocale(locale) ?? '')
        .split(RegExp(r',\s*'))
        .where((e) => e.isNotEmpty)
        .toList();
    final similarText = menu.getSimilarFoodByLocale(locale);
    final similarFoods = <SimilarFood>[
      if (similarText != null && similarText.trim().isNotEmpty)
        SimilarFood(
          id: "similar_${menu.id}",
          name: similarText.trim(),
          description: "",
        ),
    ];

    // 3장의 플레이스홀더(variant 1~3) 생성 (rep_image_url 미사용)
    final imageUrls = List.generate(
      3,
      (i) => _placeholderImage(baseName, menu.id, variant: i + 1),
    );

      return FoodModel(
        id: menu.id,
      name: menu.getNameByLocale(locale),
      baseName: baseName,
        category: menu.category ?? "Meals",
      imageUrl: imageUrls.first,
      description: menu.getDescriptionByLocale(locale) ?? '',
      imageUrls: imageUrls,
        spiciness: menu.spiceLevel,
        spicinessDescription: _getSpicinessDescription(menu.spiceLevel),
      similarFoods: similarFoods,
      contains: contains,
      mayContain: mayContains,
    );
  }

  List<FoodModel> _convertMenuItemsToFoodModels(List<MenuItemModel> menuItems) {
    return menuItems.map((menu) => _convertMenuItemToFoodModel(menu)).toList();
  }

  String _getSpicinessDescription(int level) {
    final descriptions = [
      "안 매워요",
      "김치보다 안 매워요",
      "김치만큼 매워요",
      "불닭보다 안 매워요",
      "불닭만큼 매워요",
    ];
    return descriptions[level.clamp(1, 5) - 1];
  }

  /// API 카테고리 값 정규화 (DB에는 Drinks로 저장되어 있음)
  String _categoryParamForApi(String category) {
    if (category.toLowerCase() == "drink") return "Drinks";
    return category;
  }

  Future<void> _loadTrendBanners() async {
    try {
      final countryCode = _getCountryCode(selectedCountry?.id ?? '');
      final birthYyyyMm = _getBirthYyyyMm(selectedAge?.id ?? '');

      List<MenuItemModel> trendMenus = [];
      try {
        trendMenus =
          await _apiRepository.recommendationService.getNationalityAgeTrend(
        country: countryCode,
        birthYyyyMm: birthYyyyMm,
        limit: 3,
      );
        debugPrint(
            "[Explore] trend fetch: country=$countryCode birth=$birthYyyyMm count=${trendMenus.length}");
      } catch (e) {
        debugPrint("[Explore] trend fetch error: $e");
        trendMenus = [];
      }
      if (trendMenus.isEmpty) {
        debugPrint("[Explore] trend empty -> fallback");
        trendMenus = _fallbackMenuItems();
      }

      if (mounted) {
        setState(() {
          _nationalAgeMenus = trendMenus;
          _trendBanners = trendMenus
              .take(3)
              .map((menu) => TrendBannerModel(
                    id: menu.id,
                    foodName: menu.name,
                    description: "지금 가장 많이 선택되고 있는 실시간 인기 메뉴예요.",
                    imageUrl: _menuImageUrl(menu),
                    countryId: selectedCountry?.id,
                    ageId: selectedAge?.id,
                  ))
              .toList();
          // 배너 인덱스 리셋
          currentTrendBannerIndex = 0;
          if (_trendBannerController.hasClients) {
            _trendBannerController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("트렌드 배너 로드 실패: $e");
    }
  }

  List<FoodModel> _getMealsFoods() => _buildSampleFoods("Meals", 8);
  List<FoodModel> _getSnacksFoods() => _buildSampleFoods("Snacks", 8);
  List<FoodModel> _getSweetsFoods() => _buildSampleFoods("Sweets", 6);
  List<FoodModel> _getDrinkFoods() => _buildSampleFoods("Drink", 6);

  List<FoodModel> _buildSampleFoods(String category, int count) {
    return List.generate(count, (index) {
      final sample = _samplePlaceholders[index % _samplePlaceholders.length];
      final name = sample["name"]!;
      final id = sample["id"]!;
      return FoodModel(
        id: id,
        name: name,
        baseName: name,
        category: category,
        imageUrl: _placeholderImage(name, id),
        description: "지금 가장 많이 선택되는 메뉴예요.",
        imageUrls: [_placeholderImage(name, id)],
        spiciness: 3,
        spicinessDescription: "김치만큼 매워요",
        similarFoods: const [],
        contains: const [],
        mayContain: const [],
      );
    });
  }

  Map<String, List<MarketModel>> _seedMarketsByRegion() {
    final regionMap = {for (final r in _regions) r: <MarketModel>[]};
    for (final seed in _marketSeeds) {
      final region = seed["region"]!;
      final name = seed["name"]!;
      final id = seed["id"]!;
      regionMap[region]!.add(_buildMarketFromSeed(region, name, id));
    }
    return regionMap;
  }

  Map<String, List<MarketModel>> _assignMarketsByRegion(
      List<MarketModel> markets) {
    // id 우선 매핑 → 이름(ko) 매핑. 분배 없음, 매핑 실패 시 "서울"에 모음
    final idToRegion = {for (final seed in _marketSeeds) seed["id"]!: seed["region"]!};
    final nameToRegion = {for (final seed in _marketSeeds) seed["name"]!: seed["region"]!};
    final regionMap = {for (final r in _regions) r: <MarketModel>[]};

    for (final m in markets) {
      final region = idToRegion[m.id] ?? nameToRegion[m.name];
      if (region != null) {
        regionMap[region]!.add(m);
      } else {
        regionMap["서울"]!.add(m);
      }
    }

    return regionMap;
  }

  MarketModel _buildMarketFromSeed(String region, String name, String id) {
    final placeholders =
        List.generate(3, (i) => _marketPlaceholder(name, id, variant: i + 1));
    // 메뉴 ID 형식으로 변경됨 (실제 메뉴 정보는 _convertToMarketModel에서 로드)
    final mustTryIds = mustTryItemsByMarket[name] ?? const [];
    return MarketModel(
      id: id,
      name: name,
      description: "시장 소개가 준비중입니다.",
      imageUrls: placeholders,
      mustTryItems: [
        for (int i = 0; i < mustTryIds.length; i++)
          MustTryItem(
            id: mustTryIds[i],
            name: "", // 실제 메뉴 정보는 _convertToMarketModel에서 설정
            description: "",
            imageUrl: "",
          )
      ],
      address: "",
      operatingHours: "",
      transportation: "",
      parking: "",
      restroom: "",
      mapImageUrl: "",
    );
  }

  // 필터 선택 상태
  CountryFilter? selectedCountry;
  AgeFilter? selectedAge;

  // 드롭다운 표시 상태
  bool showCountryDropdown = false;
  bool showAgeDropdown = false;

  // 국가 리스트 (20개)
  final List<CountryFilter> countries = [
    CountryFilter(
      id: "country_jp",
      name: "일본",
      flagImageUrl: "assets/images/JP.gif",
    ),
    CountryFilter(
      id: "country_us",
      name: "미국",
      flagImageUrl: "assets/images/US.gif",
    ),
    CountryFilter(
      id: "country_cn",
      name: "중국",
      flagImageUrl: "assets/images/CN.gif",
    ),
    CountryFilter(
      id: "country_kr",
      name: "한국",
      flagImageUrl: "assets/images/KR.gif", // 한국 국기 이미지가 없으면 null
    ),
    CountryFilter(
      id: "country_th",
      name: "태국",
      flagImageUrl: "assets/images/TH.gif",
    ),
    CountryFilter(
      id: "country_vn",
      name: "베트남",
      flagImageUrl: "assets/images/VN.gif",
    ),
    CountryFilter(
      id: "country_sg",
      name: "싱가포르",
      flagImageUrl: "assets/images/SG.gif",
    ),
    CountryFilter(
      id: "country_my",
      name: "말레이시아",
      flagImageUrl: "assets/images/MY.gif",
    ),
    CountryFilter(
      id: "country_id",
      name: "인도네시아",
      flagImageUrl: "assets/images/ID.gif",
    ),
    CountryFilter(
      id: "country_ph",
      name: "필리핀",
      flagImageUrl: "assets/images/PH.gif",
    ),
    CountryFilter(
      id: "country_in",
      name: "인도",
      flagImageUrl: "assets/images/IN.gif",
    ),
    CountryFilter(
      id: "country_tw",
      name: "대만",
      flagImageUrl: "assets/images/TW.gif",
    ),
    CountryFilter(
      id: "country_hk",
      name: "홍콩",
      flagImageUrl: "assets/images/HK.gif",
    ),
    CountryFilter(
      id: "country_au",
      name: "호주",
      flagImageUrl: "assets/images/AU.gif",
    ),
    CountryFilter(
      id: "country_ca",
      name: "캐나다",
      flagImageUrl: "assets/images/CA.gif",
    ),
    CountryFilter(
      id: "country_gb",
      name: "영국",
      flagImageUrl: "assets/images/GB.gif",
    ),
    CountryFilter(
      id: "country_fr",
      name: "프랑스",
      flagImageUrl: "assets/images/FR.gif",
    ),
    CountryFilter(
      id: "country_de",
      name: "독일",
      flagImageUrl: "assets/images/DE.gif",
    ),
    CountryFilter(
      id: "country_ru",
      name: "러시아",
      flagImageUrl: "assets/images/RU.gif",
    ),
    CountryFilter(
      id: "country_mx",
      name: "멕시코",
      flagImageUrl: "assets/images/MX.gif",
    ),
    CountryFilter(
      id: "country_mn",
      name: "몽골",
      flagImageUrl: "assets/images/MN.gif",
    ),
  ];

  // 연령 리스트
  final List<AgeFilter> ages = [
    AgeFilter(id: "age_0", name: "10대 이하"),
    AgeFilter(id: "age_1", name: "10대"),
    AgeFilter(id: "age_2", name: "20대"),
    AgeFilter(id: "age_3", name: "30대"),
    AgeFilter(id: "age_4", name: "40대"),
    AgeFilter(id: "age_5", name: "50대"),
    AgeFilter(id: "age_6", name: "60대"),
    AgeFilter(id: "age_7", name: "70대"),
    AgeFilter(id: "age_8", name: "80대 이상"),
  ];

  // 지역별 시장 데이터
  Map<String, List<MarketModel>> get marketsByRegion {
    // API에서 가져온 데이터를 지역별로 분류
    if (_marketsByRegion.isNotEmpty) {
      return _marketsByRegion;
    }

    if (_markets.isEmpty) {
      // 로딩 중이거나 데이터가 없을 때 시드 기반 지역 분류 반환
      _marketsByRegion = _seedMarketsByRegion();
      return _marketsByRegion;
    }

    // TODO: 시장 데이터에 지역 정보가 있으면 지역별로 분류
    // 현재는 지역 정보가 없으므로 시드 이름 매핑 → 없으면 균등 분배
    _marketsByRegion = _assignMarketsByRegion(_markets);
    return _marketsByRegion;
  }

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // Discover Sijang 섹션의 탭 위치를 추적하기 위한 GlobalKey
  final GlobalKey _regionTabsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _trendBannerController = PageController(viewportFraction: 0.9);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 0. 사용자 정보로 초기 선택값 설정
      final user = await _apiRepository.userService.getCurrentUser();
      _koreanName = user.koreanName ?? user.displayName;

      // 국가 매핑
      final matchedCountry =
          _findCountryByCode(user.country) ?? countries.first;
      selectedCountry = matchedCountry;

      // 나이대 매핑
      final matchedAge = _findAgeByBirth(user.birthYyyyMm) ?? ages[2];
      selectedAge = matchedAge;

      final locale = await _apiRepository.userService.getLocale();

      // 1. 시장 목록 조회 (기존 로직 유지)
      final markets = await _apiRepository.marketService.getMarkets();

      // 2. 국적/나이 기반 메뉴 Top3 + 배너
      await _loadTrendBanners();

      // 3. 찜 기반 추천 (좋아요 → 찜하기 변경)
      List<MenuItemModel> savedBased = [];
      try {
        savedBased = await _apiRepository.menuService.getSavedMenuItems(limit: 3);
      } catch (_) {
        savedBased = [];
      }
      if (savedBased.isEmpty) {
        // 트렌딩 API가 500을 반환하므로 호출을 건너뛰고 바로 플레이스홀더로 대체
        savedBased = _fallbackMenuItems();
      }

      // 4. 카테고리별 메뉴 조회 (기존)
      final categories = ["Meals", "Snacks", "Sweets", "Drink"];
      final foodsByCategory = <String, List<MenuItemModel>>{};
      final menuIdToModel = <String, MenuItemModel>{};
      for (final category in categories) {
        try {
        final menus = await _apiRepository.menuService.getMenuItems(
            category: _categoryParamForApi(category),
          limit: 20,
        );
        foodsByCategory[category] = menus;
          // 메뉴 ID로 매핑 (must try용)
          for (final menu in menus) {
            menuIdToModel[menu.id] = menu;
          }
        } catch (e) {
          debugPrint("[Explore] getMenuItems error for $category: $e");
          foodsByCategory[category] = [];
        }
      }

      if (mounted) {
        setState(() {
          _menuIdToModel = menuIdToModel;
          _markets =
              markets.map((m) => _convertToMarketModel(m, locale)).toList();
          _marketsByRegion = _assignMarketsByRegion(_markets);
          _savedBasedMenus = savedBased;
          _foodsByCategory = foodsByCategory;
          _userLocale = locale;
          _isLoading = false;
        });
        debugPrint(
            "[Explore] state set: markets=${_markets.length}, nationalAge=${_nationalAgeMenus.length}, savedBased=${_savedBasedMenus.length}");
      }
    } catch (e) {
      debugPrint("데이터 로드 실패: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCountryCode(String countryId) {
    // countryId를 국가 코드로 변환 (예: "country_jp" -> "JP")
    final parts = countryId.split('_');
    return parts.length > 1 ? parts[1].toUpperCase() : 'JP';
  }

  String _getBirthYyyyMm(String ageId) {
    // ageId를 생년월일로 변환 (예: "age_2" -> "2000-01")
    final ageMap = {
      'age_0': '2010-01',
      'age_1': '2005-01',
      'age_2': '2000-01',
      'age_3': '1995-01',
      'age_4': '1990-01',
      'age_5': '1985-01',
      'age_6': '1980-01',
      'age_7': '1975-01',
      'age_8': '1970-01',
    };
    return ageMap[ageId] ?? '2000-01';
  }

  CountryFilter? _findCountryByCode(String? countryCode) {
    if (countryCode == null) return null;
    final lower = countryCode.toLowerCase();
    return countries.cast<CountryFilter?>().firstWhere(
          (c) => c != null && c.id.split('_').last == lower,
          orElse: () => null,
        );
  }

  AgeFilter? _findAgeByBirth(String? birthYyyyMm) {
    if (birthYyyyMm == null || birthYyyyMm.length < 4) return null;
    final year = int.tryParse(birthYyyyMm.substring(0, 4));
    if (year == null) return null;
    final nowYear = DateTime.now().year;
    final age = nowYear - year;
    if (age < 10) return ages[0];
    if (age < 20) return ages[1];
    if (age < 30) return ages[2];
    if (age < 40) return ages[3];
    if (age < 50) return ages[4];
    if (age < 60) return ages[5];
    if (age < 70) return ages[6];
    if (age < 80) return ages[7];
    return ages[8];
  }

  List<MenuItemModel> _fallbackMenuItems() {
    final samples = [
      {"id": "ME155", "name": "떡볶이"},
      {"id": "ME012", "name": "김밥"},
      {"id": "ME148", "name": "닭강정"},
    ];
    return samples
        .map(
          (s) => MenuItemModel(
            id: s["id"]!,
            name: s["name"]!,
            repImageUrl: null,
            description: "",
            category: "Meals",
            spiceLevel: 3,
            price: null,
            contains: null,
            containsEn: null,
            containsZh: null,
            containsJa: null,
            mayContains: null,
            mayContainsEn: null,
            mayContainsZh: null,
            mayContainsJa: null,
            nameEn: null,
            nameZh: null,
            nameJa: null,
            descriptionEn: null,
            descriptionZh: null,
            descriptionJa: null,
            similarFood: null,
            similarFoodEn: null,
            similarFoodZh: null,
            similarFoodJa: null,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }

  MarketModel _convertToMarketModel(
      api_models.MarketModel apiMarket, String locale) {
    // API MarketModel을 화면용 MarketModel로 변환
    final baseNameKo = apiMarket.name; // locale 비의존 (경로용)
    final placeholders = List.generate(
      3,
      (i) => _marketPlaceholder(baseNameKo, apiMarket.id, variant: i + 1),
    );
    final imageUrls = (apiMarket.silhouetteUrl != null &&
            apiMarket.silhouetteUrl!.isNotEmpty)
        ? [
            _toCdn(apiMarket.silhouetteUrl!),
            ...placeholders.skip(1),
          ]
        : placeholders;

    // Must try 메뉴 로드 (메뉴 ID 형식)
    final mustTryIds = mustTryItemsByMarket[apiMarket.name] ?? [];
    final mustTryItems = mustTryIds.map((menuId) {
      final menuModel = _menuIdToModel[menuId];
      if (menuModel == null) {
        return MustTryItem(
          id: menuId,
          name: "",
          description: "",
          imageUrl: "",
        );
      }
      final baseName = menuModel.name; // 한국어 원본 이름
      final imageUrl = _placeholderImage(baseName, menuId, variant: 1);
      final displayName = menuModel.getNameByLocale(locale);
      return MustTryItem(
        id: menuId,
        name: displayName,
        description: "",
        imageUrl: imageUrl,
      );
    }).toList();

    return MarketModel(
      id: apiMarket.id,
      name: apiMarket.getNameByLocale(locale),
      description: apiMarket.getDescriptionByLocale(locale) ?? '',
      imageUrls: imageUrls,
      mustTryItems: mustTryItems,
      address: '', // TODO: MarketInfo에서 주소 가져오기
      operatingHours: '',
      transportation: '',
      parking: '',
      restroom: '',
      mapImageUrl: '',
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _trendBannerController.dispose();
    super.dispose();
  }

  // 필터값에 따른 트렌드 배너 리스트 가져오기
  List<TrendBannerModel> getTrendBanners() {
    // API에서 가져온 데이터 사용
    if (_trendBanners.isEmpty) {
      // 로딩 중이거나 데이터가 없을 때 더미 데이터 반환
      return List.generate(3, (index) {
        return TrendBannerModel(
          id: "banner_$index",
          foodName: _getFoodNameByIndex(index),
          description: "지금 가장 많이 선택되고 있는 실시간 인기 메뉴예요.",
          imageUrl: "https://placehold.co/375x233",
          countryId: selectedCountry?.id,
          ageId: selectedAge?.id,
        );
      });
    }
    return _trendBanners;
  }

  String _getFoodNameByIndex(int index) {
    final foods = ["떡볶이", "김밥", "순대", "호떡", "어묵"];
    return foods[index % foods.length];
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              // 드롭다운 외부 클릭 시 닫기
              if (showCountryDropdown || showAgeDropdown) {
                setState(() {
                  showCountryDropdown = false;
                  showAgeDropdown = false;
                });
              }
            },
            child: ScrollConfiguration(
              // 마우스 휠 스크롤 비활성화, 드래그만 허용
              behavior: DragOnlyScrollBehavior(),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNowTrendSection(responsive, textTheme),
                  ResponsivePadding(
                    mobilePadding: 16,
                    tabletPadding: 24,
                    desktopPadding: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildKoreanStreetFoodSection(responsive, textTheme),
                        const SizedBox(height: 16),
                        _buildDiscoverSijangSection(responsive, textTheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNowTrendSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return ResponsivePadding(
          mobilePadding: 16,
          tabletPadding: 24,
          desktopPadding: 32,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // Figma 배경색
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 16),
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Now Trend",
                style: textTheme.titleMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(
                    mobileSize: 16,
                    tabletSize: 18,
                    desktopSize: 20,
                  ),
                fontWeight: FontWeight.w600, // Semi Bold
                fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              _buildFilterChips(responsive, textTheme),
            const SizedBox(height: 12),
            // 국적/나이 기반 Top3 가로 스크롤
            _buildNationalityAgeRow(responsive, textTheme),
            const SizedBox(height: 12),
            // 찜 기반 추천
            _buildSavedBasedRow(responsive, textTheme),
            ],
          ),
        ),
    );
  }

  Widget _buildFilterChips(ResponsiveHelper responsive, TextTheme textTheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCountryFilterChip(responsive, textTheme),
        _buildAgeFilterChip(responsive, textTheme),
      ],
    );
  }

  Widget _buildCountryFilterChip(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return CustomDropdown<CountryFilter>(
      selectedValue: selectedCountry,
      items: countries,
      getLabel: (country) => country.name,
      getImageUrl: (country) => country.flagImageUrl,
      onItemSelected: (country) {
        setState(() {
          selectedCountry = country;
          showCountryDropdown = false;
          showAgeDropdown = false;
          // 필터 변경 시 배너 리셋
          currentTrendBannerIndex = 0;
        });
        _loadTrendBanners(); // 내부에서 animateToPage(0) 호출
      },
      isOpen: showCountryDropdown,
      onToggle: () {
        setState(() {
          showCountryDropdown = !showCountryDropdown;
          showAgeDropdown = false;
        });
      },
      width: 200,
      maxHeight: 300,
      placeholder: "국가 선택",
    );
  }

  Widget _buildAgeFilterChip(ResponsiveHelper responsive, TextTheme textTheme) {
    return CustomDropdown<AgeFilter>(
      selectedValue: selectedAge,
      items: ages,
      getLabel: (age) => age.name,
      onItemSelected: (age) {
        setState(() {
          selectedAge = age;
          showAgeDropdown = false;
          showCountryDropdown = false;
          // 필터 변경 시 배너 리셋
          currentTrendBannerIndex = 0;
        });
        // 필터 변경 시 트렌드 배너 다시 로드
        _loadTrendBanners(); // 내부에서 animateToPage(0) 호출
      },
      isOpen: showAgeDropdown,
      onToggle: () {
        setState(() {
          showAgeDropdown = !showAgeDropdown;
          showCountryDropdown = false;
        });
      },
      width: 150,
      placeholder: "연령 선택",
    );
  }


  Widget _buildNationalityAgeRow(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final items = _nationalAgeMenus;
    if (items.isEmpty) return const SizedBox.shrink();

    final screenWidth = responsive.width;
    final horizontalPadding = responsive.responsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
    ) * 2;
    final cardWidth = screenWidth - horizontalPadding;
    final cardHeight = (cardWidth * 233.25) / 311; // Figma 비율 유지

    return SizedBox(
      height: cardHeight,
      child: ScrollConfiguration(
        // 마우스 휠 스크롤 비활성화, 드래그만 허용
        behavior: DragOnlyScrollBehavior(),
        child: PageView.builder(
          itemCount: items.length,
          controller: _trendBannerController,
          padEnds: true,
          onPageChanged: (index) {
          setState(() {
            currentTrendBannerIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final menu = items[index];
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsivePadding(mobilePadding: 8),
            ),
            child: _buildTrendMenuCard(
              responsive,
              textTheme,
              menu,
              cardWidth,
              cardHeight,
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildTrendMenuCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MenuItemModel menu,
    double width,
    double height,
  ) {
    return GestureDetector(
      onTap: () {
        final food = _convertMenuItemToFoodModel(menu);
        context.push('/explore/food/${food.id}', extra: {'food': food});
      },
      child: Container(
        width: width,
        height: height,
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
            // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
                _menuImageUrl(menu),
                width: width,
                height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: width,
                  height: height,
                  color: AppColors.imagePlaceholder,
                );
              },
            ),
          ),
          // 그라데이션 오버레이 (하단)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.38, // Figma 비율
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                colors: [
                    Colors.black.withOpacity(0.89),
                    Colors.black.withOpacity(0.0),
                ],
              ),
            ),
          ),
          ),
          // 텍스트 오버레이
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(
                responsive.responsivePadding(mobilePadding: 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    menu.name,
                    style: TextStyle(
                      fontSize: responsive.responsiveFontSize(mobileSize: 32),
                      fontWeight: FontWeight.w500, // Medium
                    color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "지금 가장 많이 선택되고 있는 실시간 인기 메뉴예요.",
                    style: TextStyle(
                      fontSize: responsive.responsiveFontSize(mobileSize: 12),
                      fontWeight: FontWeight.w500, // Medium
                    color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSavedBasedRow(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final items = _savedBasedMenus.isEmpty ? _fallbackMenuItems() : _savedBasedMenus;
    final namePrefix = (_koreanName ?? "당신");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$namePrefix님 입맛에 딱 맞을거예요",
          style: textTheme.titleMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(
              mobileSize: 16,
              tabletSize: 18,
              desktopSize: 20,
            ),
            fontWeight: FontWeight.w500, // Medium
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: items.take(3).map((menu) {
            final isLast = menu == items.take(3).last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: isLast ? 0 : responsive.responsivePadding(mobilePadding: 10),
                ),
                child: _buildSmallMenuCard(
                  responsive,
                  textTheme,
                  menu,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmallMenuCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MenuItemModel menu,
  ) {
    return GestureDetector(
      onTap: () {
        final food = _convertMenuItemToFoodModel(menu);
        context.push('/explore/food/${food.id}', extra: {'food': food});
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 이미지
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.imagePlaceholder,
                borderRadius: BorderRadius.circular(999),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.network(
                  _menuImageUrl(menu),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 40,
                      height: 40,
                      color: AppColors.imagePlaceholder,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 메뉴 이름
            Expanded(
              child: Text(
                menu.name,
                style: TextStyle(
                  fontSize: responsive.responsiveFontSize(mobileSize: 12),
                  fontWeight: FontWeight.w500, // Medium
                  color: AppColors.mainText,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _menuImageUrl(MenuItemModel menu) {
    // rep_image_url 미사용, 항상 placeholder variant 1
    return _placeholderImage(menu.name, menu.id, variant: 1);
  }

  String _toCdn(String url) {
    // S3 정규식 치환 (모든 리전 호환)
    final cdnUrl = url.replaceFirst(
      RegExp(r'https?:\/\/market-explorer-photos\.s3\.[^\/]+\.amazonaws\.com'),
      'https://dnzeuzpu74ulj.cloudfront.net',
    );

    // 상대 경로 처리 (/path 형태)
    if (cdnUrl.startsWith('/')) {
      return 'https://dnzeuzpu74ulj.cloudfront.net$cdnUrl';
    }

    return cdnUrl;
  }

  String _resolveImage(String? url, {String? fallback}) {
    if (url == null || url.isEmpty) {
      return fallback ?? _placeholderImage("떡볶이", "ME155");
    }
    // rep_image_url 미사용이지만, 혹시 들어올 경우에도 CDN으로만 정규화
    return _toCdn(url);
  }

  String _placeholderImage(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    // 경로 규칙: placeholders/Menu_all/{name}/{name}{variant}_{id}.png
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/${encodedName}/${encodedName}${clamped}_${id}.png";
  }

  String _marketPlaceholder(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    return _toCdn(
        "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/${encodedName}${clamped}_${id}.png");
  }

  Widget _buildKoreanStreetFoodSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final categories = ["Meals", "Snacks", "Sweets", "Drink"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Korean Street Food",
          style: textTheme.titleMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(
              mobileSize: 16,
              tabletSize: 18,
              desktopSize: 20,
            ),
            fontWeight: FontWeight.w600, // Semi Bold
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoryTabs(responsive, textTheme, categories),
        const SizedBox(height: 12),
        _buildFoodGrid(responsive),
      ],
    );
  }

  Widget _buildCategoryTabs(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    List<String> categories,
  ) {
    return ScrollConfiguration(
      // 마우스 휠 스크롤 비활성화, 드래그만 허용
      behavior: DragOnlyScrollBehavior(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
                currentFoodPage = 0; // 카테고리 변경 시 첫 페이지로 리셋
              });
              // PageView의 key가 변경되면 자동으로 리셋됨
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(
                vertical: responsive.responsivePadding(mobilePadding: 4),
                horizontal: responsive.responsivePadding(mobilePadding: 8),
              ),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border(
                        bottom: BorderSide(width: 2, color: AppColors.mainText),
                      )
                    : null,
              ),
              child: Text(
                category,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 13),
                  fontWeight: FontWeight.w500, // Thin
                  color:
                      isSelected ? AppColors.mainText : AppColors.inactiveText,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildFoodGrid(ResponsiveHelper responsive) {
    final foods = foodsByCategory[selectedCategory] ?? [];

    // 2x2 그리드로 나누기 (한 페이지에 4개)
    final itemsPerPage = 4;
    final totalPages = (foods.length / itemsPerPage).ceil();

    if (totalPages == 0) {
      return const SizedBox.shrink();
    }

    final cardHeight = responsive.isMobile ? 141.0 : 180.0;
    final rowSpacing = responsive.responsivePadding(mobilePadding: 12);
    final gridHeight = cardHeight * 2 + rowSpacing;

    return Column(
      children: [
        SizedBox(
          height: gridHeight,
          child: ScrollConfiguration(
            // 마우스 휠 스크롤 비활성화, 드래그만 허용
            behavior: DragOnlyScrollBehavior(),
            child: PageView.builder(
              key: ValueKey(selectedCategory), // 카테고리 변경 시 PageView 리셋
              itemCount: totalPages,
              onPageChanged: (page) {
                setState(() {
                  currentFoodPage = page;
                });
              },
              itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * itemsPerPage;
              final endIndex = (startIndex + itemsPerPage > foods.length)
                  ? foods.length
                  : startIndex + itemsPerPage;
              final pageFoods = foods.sublist(startIndex, endIndex);

              // 2x2 그리드로 표시
              return _buildFoodGridPage(responsive, pageFoods);
            },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 페이지네이션 인디케이터
        _buildPaginationIndicator(responsive, totalPages, currentFoodPage),
      ],
    );
  }

  Widget _buildFoodGridPage(
    ResponsiveHelper responsive,
    List<FoodModel> foods,
  ) {
    final screenWidth = responsive.width;
    final horizontalPadding = responsive.responsivePadding(
          mobilePadding: 16,
          tabletPadding: 24,
          desktopPadding: 32,
        ) *
        2;
    final cardSpacing = responsive.responsivePadding(
      mobilePadding: 8,
      tabletPadding: 12,
      desktopPadding: 16,
    );
    final cardWidth = (screenWidth - horizontalPadding - cardSpacing) / 2;
    final cardHeight = responsive.isMobile ? 141.0 : 180.0;
    final rowSpacing = responsive.responsivePadding(mobilePadding: 12);

    // 2x2 그리드로 나누기
    final rows = <List<FoodModel>>[];
    for (int i = 0; i < foods.length; i += 2) {
      rows.add(foods.sublist(i, i + 2 > foods.length ? foods.length : i + 2));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row == rows.last ? 0 : rowSpacing),
          child: Row(
            children: row.asMap().entries.map((entry) {
              final index = entry.key;
              final food = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  right: index == 0 ? cardSpacing / 2 : 0,
                  left: index == 1 ? cardSpacing / 2 : 0,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: _buildFoodCard(
                    responsive,
                    food,
                    cardWidth,
                    cardHeight,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaginationIndicator(
    ResponsiveHelper responsive,
    int totalPages,
    int currentPage,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          width: index == currentPage ? 14 : 6,
          height: 6,
          margin: EdgeInsets.symmetric(
            horizontal: responsive.responsivePadding(mobilePadding: 3),
          ),
          decoration: BoxDecoration(
            color: index == currentPage
                ? AppColors.mainText
                : AppColors.imagePlaceholder,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _buildFoodCard(
    ResponsiveHelper responsive,
    FoodModel food,
    double cardWidth,
    double cardHeight,
  ) {
    final primaryImage = (food.imageUrls.isNotEmpty ? food.imageUrls.first : food.imageUrl);
    final imageUrl = (primaryImage.isNotEmpty)
        ? primaryImage
        : _placeholderImage(food.baseName, food.id);

    return GestureDetector(
      onTap: () {
        context.push(
          '/explore/food/${food.id}',
          extra: {'food': food},
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppColors.imagePlaceholder,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                _resolveImage(imageUrl, fallback: _placeholderImage(food.baseName, food.id)),
                width: cardWidth,
                height: cardHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: cardWidth,
                    height: cardHeight,
                    color: AppColors.imagePlaceholder,
                  );
                },
              ),
            ),
            Positioned(
              left: responsive.responsivePadding(mobilePadding: 10.0),
              bottom: responsive.responsivePadding(mobilePadding: 10.0),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.responsivePadding(mobilePadding: 10.0),
                  vertical: responsive.responsivePadding(mobilePadding: 4.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  food.name,
                  style: TextStyle(
                    fontSize: responsive.responsiveFontSize(mobileSize: 11),
                    fontWeight: FontWeight.w500, // Thin
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverSijangSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final regions = ["서울", "경기", "인천", "강원", "광주", "전라도", "경상도", "대구", "제주"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Discover Sijang",
          style: textTheme.titleMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(
              mobileSize: 16,
              tabletSize: 18,
              desktopSize: 20,
            ),
            fontWeight: FontWeight.w600, // Semi Bold
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        _buildRegionTabs(responsive, textTheme, regions),
        const SizedBox(height: 12),
        _buildMarketGrid(responsive),
      ],
    );
  }

  Widget _buildRegionTabs(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    List<String> regions,
  ) {
    return ScrollConfiguration(
      // 마우스 휠 스크롤 비활성화, 드래그만 허용
      behavior: DragOnlyScrollBehavior(),
      child: SingleChildScrollView(
        key: _regionTabsKey,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
        children: regions.map((region) {
          final isSelected = region == selectedRegion;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedRegion = region;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(
                vertical: responsive.responsivePadding(mobilePadding: 4),
                horizontal: responsive.responsivePadding(mobilePadding: 8),
              ),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border(
                        bottom: BorderSide(width: 2, color: AppColors.mainText),
                      )
                    : null,
              ),
              child: Text(
                region,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 13),
                  fontWeight: FontWeight.w500, // Medium
                  color:
                      isSelected ? AppColors.mainText : AppColors.inactiveText,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildMarketGrid(ResponsiveHelper responsive) {
    final markets = marketsByRegion[selectedRegion] ?? [];

    // 고정된 카드 너비 계산 (화면 너비에서 패딩과 간격을 제외한 후 2로 나눔)
    // ResponsivePadding의 mobilePadding이 16이므로 실제 패딩 값 계산
    final screenWidth = responsive.width;
    final horizontalPadding = responsive.responsivePadding(
          mobilePadding: 16,
          tabletPadding: 24,
          desktopPadding: 32,
        ) *
        2;
    final cardSpacing = responsive.responsivePadding(
      mobilePadding: 8,
      tabletPadding: 12,
      desktopPadding: 16,
    );
    final cardWidth = (screenWidth - horizontalPadding - cardSpacing) / 2;
    final cardHeight = responsive.isMobile ? 141.0 : 180.0;
    final rowSpacing = responsive.responsivePadding(mobilePadding: 12);

    // 한 줄에 2개씩 표시하기 위해 그리드를 나눔
    final rows = <List<MarketModel>>[];
    for (int i = 0; i < markets.length; i += 2) {
      rows.add(
        markets.sublist(i, i + 2 > markets.length ? markets.length : i + 2),
      );
    }

    // 최소 2줄 높이 보장 (탭 위치 고정을 위해)
    final minRows = 2;
    final actualRows = rows.length < minRows ? minRows : rows.length;

    return Column(
      children: List.generate(actualRows, (rowIndex) {
        // 실제 카드가 있는 행인지 확인
        if (rowIndex < rows.length) {
          final row = rows[rowIndex];
          return Padding(
            padding: EdgeInsets.only(bottom: rowSpacing),
            child: Row(
              children: row.asMap().entries.map((entry) {
                final index = entry.key;
                final market = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == 0 ? cardSpacing / 2 : 0,
                    left: index == 1 ? cardSpacing / 2 : 0,
                  ),
                  child: SizedBox(
                    width: cardWidth,
                    child: _buildMarketCard(
                      responsive,
                      market,
                      cardWidth,
                      cardHeight,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        } else {
          // 빈 행 (최소 높이 보장용)
          return Padding(
            padding: EdgeInsets.only(bottom: rowSpacing),
            child: SizedBox(
              height: cardHeight,
              child: Row(
                children: [
                  SizedBox(width: cardWidth + cardSpacing / 2),
                  SizedBox(width: cardWidth + cardSpacing / 2),
                ],
              ),
            ),
          );
        }
      }),
    );
  }

  Widget _buildMarketCard(
    ResponsiveHelper responsive,
    MarketModel market,
    double cardWidth,
    double cardHeight,
  ) {
    final firstImage =
        market.imageUrls.isNotEmpty ? market.imageUrls.first : _marketPlaceholder(market.name, market.id, variant: 1);
    return GestureDetector(
      onTap: () {
        context.push(
          '/explore/market/${market.id}',
          extra: {'market': market},
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppColors.imagePlaceholder,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                _resolveImage(firstImage, fallback: firstImage),
                width: double.infinity,
                height: cardHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: cardHeight,
                    color: AppColors.imagePlaceholder,
                  );
                },
              ),
            ),
            Positioned(
              left: responsive.responsivePadding(mobilePadding: 10.0),
              bottom: responsive.responsivePadding(mobilePadding: 10.0),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.responsivePadding(mobilePadding: 10.0),
                  vertical: responsive.responsivePadding(mobilePadding: 4.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  market.name,
                  style: TextStyle(
                    fontSize: responsive.responsiveFontSize(mobileSize: 11),
                    fontWeight: FontWeight.w500, // Thin
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
