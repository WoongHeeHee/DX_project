// lib/features/home/explore_screen.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_text.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/widgets/custom_dropdown.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/models/market_models.dart" as api_models;
import "../../data/models/menu_models.dart";
import "../../widgets/bottom_navigation_bar.dart";
import "models/filter_model.dart";
import "models/market_model.dart";
import "models/food_model.dart";
import "models/trend_banner_model.dart";
import "market_detail_screen.dart";
import "food_detail_screen.dart";

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
  final PageController _trendBannerController = PageController();
  bool _isLoading = false;

  // API로 가져온 데이터
  List<TrendBannerModel> _trendBanners = [];
  // List<MenuItemModel> _recommendations = []; // TODO: 추후 사용 예정
  List<MarketModel> _markets = [];
  Map<String, List<MenuItemModel>> _foodsByCategory = {};

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

  List<FoodModel> _convertMenuItemsToFoodModels(List<MenuItemModel> menuItems) {
    return menuItems.map((menu) {
      return FoodModel(
        id: menu.id,
        name: menu.name,
        category: menu.category ?? "Meals",
        imageUrl: menu.repImageUrl ?? 'https://placehold.co/151x141',
        description: menu.description ?? '',
        imageUrls: [menu.repImageUrl ?? 'https://placehold.co/362x244'],
        spiciness: menu.spiceLevel,
        spicinessDescription: _getSpicinessDescription(menu.spiceLevel),
        similarFoods: [],
        contains: menu.contains?.split(', ') ?? [],
        mayContain: menu.mayContains?.split(', ') ?? [],
      );
    }).toList();
  }

  String _getSpicinessDescription(int level) {
    final descriptions = [
      "맵지 않아요",
      "약간 매워요",
      "적당히 매워요",
      "김치만큼 매워요",
      "매우 매워요",
    ];
    return descriptions[level.clamp(1, 5) - 1];
  }

  Future<void> _loadTrendBanners() async {
    try {
      final locale = await _apiRepository.userService.getLocale();
      final countryCode = _getCountryCode(selectedCountry?.id ?? '');
      final birthYyyyMm = _getBirthYyyyMm(selectedAge?.id ?? '');
      final trendMenus =
          await _apiRepository.recommendationService.getNationalityAgeTrend(
        country: countryCode,
        birthYyyyMm: birthYyyyMm,
        limit: 3,
      );

      if (mounted) {
        setState(() {
          _trendBanners = trendMenus
              .take(3)
              .map((menu) => TrendBannerModel(
                    id: menu.id,
                    foodName: menu.getNameByLocale(locale),
                    description: "지금 가장 많이 선택되고 있는 실시간 인기 메뉴예요.",
                    imageUrl:
                        menu.repImageUrl ?? 'https://placehold.co/375x233',
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

  List<FoodModel> _getMealsFoods() {
    final names = [
      "갈치조림",
      "김밥",
      "비빔당면",
      "내장국밥",
      "떡갈비",
      "막국수",
      "막창구이",
      "꼬마김밥",
      "족발",
      "쫄면",
      "회국수",
      "소머리국밥",
      "곤드레밥",
      "콧등치기국수",
      "꼬막비빔국수",
      "간고등어",
      "헛제사밥",
      "장터국밥",
      "찜닭",
    ];
    return List.generate(
      19,
      (index) => _createDummyFood("Meals", index + 1, names[index]),
    );
  }

  List<FoodModel> _getSnacksFoods() {
    final names = [
      "구운옥수수",
      "기름떡볶이",
      "납작만두",
      "녹두전",
      "닭강정",
      "닭꼬치",
      "떡볶이",
      "모둠전",
      "빈대떡",
      "소떡소떡",
      "순대",
      "순대볶음",
      "어묵꼬치",
      "옛날통닭",
      "오징어순대",
      "육회",
      "핫도그",
      "육전",
      "만두",
    ];
    return List.generate(
      19,
      (index) => _createDummyFood("Snacks", index + 1, names[index]),
    );
  }

  List<FoodModel> _getSweetsFoods() {
    final names = ["공갈빵", "꽈배기", "달고나", "딸기찹쌀떡", "오메기떡", "호떡", "술빵"];
    return List.generate(
      7,
      (index) => _createDummyFood("Sweets", index + 1, names[index]),
    );
  }

  List<FoodModel> _getDrinkFoods() {
    final names = ["다방커피", "모과차", "미숫가루", "수정과", "식혜", "쌍화차", "아이스커피"];
    return List.generate(
      7,
      (index) => _createDummyFood("Drink", index + 1, names[index]),
    );
  }

  FoodModel _createDummyFood(String category, int index, String name) {
    return FoodModel(
      id: "${category}_food_$index",
      name: name,
      category: category,
      imageUrl: "https://placehold.co/151x141",
      description:
          "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
      imageUrls: [
        "https://placehold.co/362x244",
        "https://placehold.co/279x233",
        "https://placehold.co/279x233",
      ],
      spiciness: 3,
      spicinessDescription: "김치만큼 매워요",
      similarFoods: [
        SimilarFood(
          id: "similar_1",
          name: "Italian Gnocchi",
          description: "texture",
        ),
        SimilarFood(
          id: "similar_2",
          name: "Mexican Mole",
          description: "Sweet-spicy",
        ),
      ],
      contains: ["Gluten", "Fish", "Soy"],
      mayContain: ["Egg", "Shellfish", "Sesame"],
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
      flagImageUrl: null, // 한국 국기 이미지가 없으면 null
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
    if (_markets.isEmpty) {
      // 로딩 중이거나 데이터가 없을 때 더미 데이터 반환
      return {
        "서울": _getSeoulMarkets(),
        "경기": _getGyeonggiMarkets(),
        "인천": _getIncheonMarkets(),
        "강원": _getGangwonMarkets(),
        "광주": _getGwangjuMarkets(),
        "전라도": _getJeollaMarkets(),
        "경상도": _getGyeongsangMarkets(),
        "대구": _getDaeguMarkets(),
        "제주": _getJejuMarkets(),
      };
    }

    // TODO: 시장 데이터에 지역 정보가 있으면 지역별로 분류
    // 현재는 모든 시장을 "서울"에 표시
    return {
      "서울": _markets,
      "경기": [],
      "인천": [],
      "강원": [],
      "광주": [],
      "전라도": [],
      "경상도": [],
      "대구": [],
      "제주": [],
    };
  }

  List<MarketModel> _getSeoulMarkets() {
    return [
      _createDummyMarket(
        "서울",
        "광장시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A51_MA0001.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A52_MA0001.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A53_MA0001.png",
        ],
        address: "서울특별시 종로구 종로6가 288",
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "꼬마김밥",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "빈대떡",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%83%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "육회",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
      _createDummyMarket(
        "서울",
        "망원시장",
        2,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A51_MA0002.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A52_MA0002.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A53_MA0002.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "닭강정",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%83%E1%85%A1%E1%86%B0%E1%84%80%E1%85%A1%E1%86%BC%E1%84%8C%E1%85%A5%E1%86%BC_ME148.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "떡볶이",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%84%E1%85%A5%E1%86%A8%E1%84%87%E1%85%A9%E1%86%A9%E1%84%8B%E1%85%B5_ME155.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "구운옥수수",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%80%E1%85%AE%E1%84%8B%E1%85%AE%E1%86%AB%E1%84%8B%E1%85%A9%E1%86%A8%E1%84%89%E1%85%AE%E1%84%89%E1%85%AE_ME131.png",
          ),
        ],
      ),
      _createDummyMarket(
        "서울",
        "통인시장",
        3,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%ED%86%B5%EC%9D%B8%EC%8B%9C%EC%9E%A51_MA0003.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%ED%86%B5%EC%9D%B8%EC%8B%9C%EC%9E%A52_MA0003.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%ED%86%B5%EC%9D%B8%EC%8B%9C%EC%9E%A53_MA0003.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "기름떡볶이",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "닭꼬치",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "모둠전",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
      _createDummyMarket(
        "서울",
        "서울풍물시장",
        4,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%84%9C%EC%9A%B8%ED%92%8D%EB%AC%BC%EC%8B%9C%EC%9E%A51_MA0004.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%84%9C%EC%9A%B8%ED%92%8D%EB%AC%BC%EC%8B%9C%EC%9E%A52_MA0004.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%84%9C%EC%9A%B8%ED%92%8D%EB%AC%BC%EC%8B%9C%EC%9E%A53_MA0004.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "녹두전",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "호떡",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "소머리국밥",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getGyeonggiMarkets() {
    return [
      _createDummyMarket(
        "경기",
        "수원남문로데오시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%88%98%EC%9B%90%EB%82%A8%EB%AC%B8%EB%A1%9C%EB%8D%B0%EC%98%A4%EC%8B%9C%EC%9E%A51_MA0005.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%88%98%EC%9B%90%EB%82%A8%EB%AC%B8%EB%A1%9C%EB%8D%B0%EC%98%A4%EC%8B%9C%EC%9E%A52_MA0005.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%88%98%EC%9B%90%EB%82%A8%EB%AC%B8%EB%A1%9C%EB%8D%B0%EC%98%A4%EC%8B%9C%EC%9E%A53_MA0005.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "순대볶음",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "꽈배기",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "만두",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getIncheonMarkets() {
    return [
      _createDummyMarket(
        "인천",
        "신포국제시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%8B%A0%ED%8F%AC%EA%B5%AD%EC%A0%9C%EC%8B%9C%EC%9E%A51_MA0006.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%8B%A0%ED%8F%AC%EA%B5%AD%EC%A0%9C%EC%8B%9C%EC%9E%A52_MA0006.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%8B%A0%ED%8F%AC%EA%B5%AD%EC%A0%9C%EC%8B%9C%EC%9E%A53_MA0006.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "닭강정",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "공갈빵",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "쫄면",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getGangwonMarkets() {
    return [
      _createDummyMarket(
        "강원",
        "단양 구경시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8B%A8%EC%96%91+%EA%B5%AC%EA%B2%BD%EC%8B%9C%EC%9E%A51_MA0007.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8B%A8%EC%96%91+%EA%B5%AC%EA%B2%BD%EC%8B%9C%EC%9E%A52_MA0007.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8B%A8%EC%96%91+%EA%B5%AC%EA%B2%BD%EC%8B%9C%EC%9E%A53_MA0007.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "떡갈비",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "닭강정",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "만두",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
      _createDummyMarket(
        "강원",
        "속초관광수산시장",
        2,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%86%8D%EC%B4%88%EA%B4%80%EA%B4%91%EC%88%98%EC%82%B0%EC%8B%9C%EC%9E%A51_MA0008.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%86%8D%EC%B4%88%EA%B4%80%EA%B4%91%EC%88%98%EC%82%B0%EC%8B%9C%EC%9E%A52_MA0008.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%86%8D%EC%B4%88%EA%B4%80%EA%B4%91%EC%88%98%EC%82%B0%EC%8B%9C%EC%9E%A53_MA0008.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "닭강정",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "오징어순대",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "술빵",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
      _createDummyMarket(
        "강원",
        "정선5일장",
        3,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%A0%95%EC%84%A05%EC%9D%BC%EC%9E%A51_MA0009.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%A0%95%EC%84%A05%EC%9D%BC%EC%9E%A52_MA0009.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%A0%95%EC%84%A05%EC%9D%BC%EC%9E%A53_MA0009.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "곤드레밥",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "콧등치기국수",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "장터국밥",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getGwangjuMarkets() {
    return [
      _createDummyMarket(
        "광주",
        "양동시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EA%B4%91%EC%A3%BC+%EC%96%91%EB%8F%99%EC%8B%9C%EC%9E%A51_MA0010.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EA%B4%91%EC%A3%BC+%EC%96%91%EB%8F%99%EC%8B%9C%EC%9E%A52_MA0010.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EA%B4%91%EC%A3%BC+%EC%96%91%EB%8F%99%EC%8B%9C%EC%9E%A53_MA0010.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "옛날통닭",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "장터국밥",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "떡볶이",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getJeollaMarkets() {
    return [
      _createDummyMarket(
        "전라도",
        "순천 아랫장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%88%9C%EC%B2%9C+%EC%95%84%EB%9E%AB%EC%9E%A51_MA0011.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%88%9C%EC%B2%9C+%EC%95%84%EB%9E%AB%EC%9E%A52_MA0011.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%88%9C%EC%B2%9C+%EC%95%84%EB%9E%AB%EC%9E%A53_MA0011.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "꼬막비빔국수",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "내장국밥",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "육전",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getGyeongsangMarkets() {
    return [
      _createDummyMarket(
        "경상도",
        "안동 구시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%95%88%EB%8F%99+%EA%B5%AC%EC%8B%9C%EC%9E%A51_MA0012.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%95%88%EB%8F%99+%EA%B5%AC%EC%8B%9C%EC%9E%A52_MA0012.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%95%88%EB%8F%99+%EA%B5%AC%EC%8B%9C%EC%9E%A53_MA0012.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "찜닭",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "간고등어",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "헛제사밥",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getDaeguMarkets() {
    return [
      _createDummyMarket(
        "대구",
        "서문시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8C%80%EA%B5%AC+%EC%84%9C%EB%AC%B8%EC%8B%9C%EC%9E%A51_MA0013.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8C%80%EA%B5%AC+%EC%84%9C%EB%AC%B8%EC%8B%9C%EC%9E%A52_MA0013.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8C%80%EA%B5%AC+%EC%84%9C%EB%AC%B8%EC%8B%9C%EC%9E%A53_MA0013.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "막창구이",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "납작만두",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "어묵꼬치",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  List<MarketModel> _getJejuMarkets() {
    return [
      _createDummyMarket(
        "제주",
        "동문재래시장",
        1,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8F%99%EB%AC%B8%EC%9E%AC%EB%9E%98%EC%8B%9C%EC%9E%A51_MA0014.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8F%99%EB%AC%B8%EC%9E%AC%EB%9E%98%EC%8B%9C%EC%9E%A52_MA0014.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EB%8F%99%EB%AC%B8%EC%9E%AC%EB%9E%98%EC%8B%9C%EC%9E%A53_MA0014.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "오메기떡",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "회국수",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "갈치조림",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
      _createDummyMarket(
        "제주",
        "서귀포 매일올레시장",
        2,
        imageUrls: [
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%84%9C%EA%B7%80%ED%8F%AC%EB%A7%A4%EC%9D%BC%EC%98%AC%EB%A0%88%EC%8B%9C%EC%9E%A51_MA0015.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%84%9C%EA%B7%80%ED%8F%AC%EB%A7%A4%EC%9D%BC%EC%98%AC%EB%A0%88%EC%8B%9C%EC%9E%A52_MA0015.png",
          "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/%EC%84%9C%EA%B7%80%ED%8F%AC%EB%A7%A4%EC%9D%BC%EC%98%AC%EB%A0%88%EC%8B%9C%EC%9E%A53_MA0015.png",
        ],
        mustTryItems: [
          MustTryItem(
            id: "item_0",
            name: "오메기떡",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
          ),
          MustTryItem(
            id: "item_1",
            name: "딸기찹쌀떡",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%89%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
          ),
          MustTryItem(
            id: "item_2",
            name: "닭꼬치",
            description: "시장 입구 근처 포장마차에서 파는 대표",
            imageUrl:
                "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
          ),
        ],
      ),
    ];
  }

  MarketModel _createDummyMarket(
    String region,
    String marketName,
    int index, {
    List<String>? imageUrls,
    List<MustTryItem>? mustTryItems,
    String? address,
  }) {
    return MarketModel(
      id: "${region}_market_$index",
      name: marketName,
      description:
          "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
      imageUrls: imageUrls ??
          [
            "https://placehold.co/362x244",
            "https://placehold.co/279x233",
            "https://placehold.co/279x233",
          ],
      mustTryItems: mustTryItems ??
          List.generate(
            3,
            (i) => MustTryItem(
              id: "item_$i",
              name: "Tteokbokki",
              description: "시장 입구 근처 포장마차에서 파는 대표",
              imageUrl: "https://placehold.co/117x77",
            ),
          ),
      address: address ?? "더미 주소",
      operatingHours: "영업시간과 휴무일이 들어감",
      transportation: "더미 교통 정보",
      parking: "더미 주차 정보",
      restroom: "더미 화장실 정보",
      mapImageUrl: "https://placehold.co/309x140",
    );
  }

  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  // Discover Sijang 섹션의 탭 위치를 추적하기 위한 GlobalKey
  final GlobalKey _regionTabsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 초기값 설정 (일본, 20대)
    selectedCountry = countries.firstWhere(
      (country) => country.name == "일본",
      orElse: () => countries[0],
    );
    selectedAge = ages[2]; // 20대
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locale = await _apiRepository.userService.getLocale();

      // 1. 시장 목록 조회
      final markets = await _apiRepository.marketService.getMarkets();

      // 2. 트렌드 배너 조회 (국가/나이 필터)
      final countryCode = _getCountryCode(selectedCountry?.id ?? '');
      final birthYyyyMm = _getBirthYyyyMm(selectedAge?.id ?? '');
      final trendMenus =
          await _apiRepository.recommendationService.getNationalityAgeTrend(
        country: countryCode,
        birthYyyyMm: birthYyyyMm,
        limit: 3,
      );

      // 3. 추천 메뉴 조회 (좋아요가 있으면 개인화 추천, 없으면 전체 트렌드)
      // List<MenuItemModel> recommendations; // TODO: 추후 사용 예정
      try {
        final savedMenus =
            await _apiRepository.menuService.getSavedMenuItems(limit: 1);
        if (savedMenus.isNotEmpty) {
          // 개인화 추천
          // recommendations = await _apiRepository.recommendationService.getRecommendations(limit: 3);
        } else {
          // 전체 트렌드
          // recommendations = await _apiRepository.recommendationService.getTrendingMenus(limit: 3);
        }
      } catch (e) {
        // 에러 발생 시 전체 트렌드 사용
        // recommendations = await _apiRepository.recommendationService.getTrendingMenus(limit: 3);
      }

      // 4. 카테고리별 메뉴 조회
      final categories = ["Meals", "Snacks", "Sweets", "Drink"];
      final foodsByCategory = <String, List<MenuItemModel>>{};
      for (final category in categories) {
        final menus = await _apiRepository.menuService.getMenuItems(
          category: category,
          limit: 20,
        );
        foodsByCategory[category] = menus;
      }

      if (mounted) {
        setState(() {
          _markets =
              markets.map((m) => _convertToMarketModel(m, locale)).toList();
          _trendBanners = trendMenus
              .take(3)
              .map((menu) => TrendBannerModel(
                    id: menu.id,
                    foodName: menu.getNameByLocale(locale),
                    description: "지금 가장 많이 선택되고 있는 실시간 인기 메뉴예요.",
                    imageUrl:
                        menu.repImageUrl ?? 'https://placehold.co/375x233',
                    countryId: selectedCountry?.id,
                    ageId: selectedAge?.id,
                  ))
              .toList();
          // _recommendations = recommendations; // TODO: 추후 사용 예정
          _foodsByCategory = foodsByCategory;
          _isLoading = false;
        });
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

  MarketModel _convertToMarketModel(
      api_models.MarketModel apiMarket, String locale) {
    // API MarketModel을 화면용 MarketModel로 변환
    return MarketModel(
      id: apiMarket.id,
      name: apiMarket.getNameByLocale(locale),
      description: apiMarket.getDescriptionByLocale(locale) ?? '',
      imageUrls: [apiMarket.silhouetteUrl ?? 'https://placehold.co/362x244'],
      mustTryItems: [], // TODO: Must eat 메뉴 조회 필요
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
            child: SingleChildScrollView(
              controller: _scrollController,
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
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildNowTrendSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 컨텐츠 (제목, 필터) - 박스 없이
        ResponsivePadding(
          mobilePadding: 16,
          tabletPadding: 24,
          desktopPadding: 32,
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
                ),
              ),
              const SizedBox(height: 12),
              _buildFilterChips(responsive, textTheme),
            ],
          ),
        ),
        // 배너 카루셀 (마진 없이 화면 끝까지)
        _buildTrendBannerCarousel(responsive, textTheme),
        // 추천 메뉴
        ResponsivePadding(
          mobilePadding: 16,
          tabletPadding: 24,
          desktopPadding: 32,
          child: _buildRecommendedMenuChips(responsive, textTheme),
        ),
      ],
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
          _trendBannerController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
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
          _trendBannerController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
        // 필터 변경 시 트렌드 배너 다시 로드
        _loadTrendBanners();
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

  Widget _buildTrendBannerCarousel(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final banners = getTrendBanners();
    final cardHeight = responsive.isMobile ? 233.25 : 280.0;

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    // 화면 너비 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = responsive.responsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
    );
    final sidePadding = horizontalPadding;

    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        controller: _trendBannerController,
        itemCount: banners.length,
        onPageChanged: (index) {
          setState(() {
            currentTrendBannerIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            width: screenWidth,
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: _buildTrendBannerCard(
              responsive,
              textTheme,
              banner,
              cardHeight,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendBannerCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    TrendBannerModel banner,
    double cardHeight,
  ) {
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // 배경 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              banner.imageUrl,
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
          // 그라데이션 오버레이
          Container(
            width: double.infinity,
            height: cardHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.5, 0),
                end: const Alignment(0.5, 1),
                colors: [
                  Colors.black.withOpacity(0),
                  Colors.black.withOpacity(0.4),
                  Colors.black,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // 하단 텍스트 오버레이
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(
                responsive.responsivePadding(mobilePadding: 12),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.5, 1),
                  end: const Alignment(0.5, 0),
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    text: banner.foodName,
                    mobileFontSize: 32,
                    tabletFontSize: 36,
                    desktopFontSize: 40,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  ResponsiveText(
                    text: banner.description,
                    mobileFontSize: 12,
                    tabletFontSize: 14,
                    desktopFontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedMenuChips(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final menus = ["호떡", "치킨", "빙수"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "당신 입맛에 딱 맞을거예요",
          style: textTheme.titleMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(
              mobileSize: 16,
              tabletSize: 18,
              desktopSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: menus.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < menus.length - 1
                      ? responsive.responsivePadding(mobilePadding: 8)
                      : 0,
                ),
                child: _buildMenuChip(
                  responsive,
                  textTheme: textTheme,
                  name: name,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuChip(
    ResponsiveHelper responsive, {
    required TextTheme textTheme,
    required String name,
  }) {
    // 세로 길이를 1.5배로 늘림 (기존 6 * 2 = 12, 12 * 1.5 = 18)
    final baseVerticalPadding = responsive.responsivePadding(mobilePadding: 6);
    final verticalPadding = baseVerticalPadding * 1.5;

    // 이미지 크기도 1.5배로 늘림
    final imageSize = responsive.responsiveIconSize(mobileSize: 28) * 1.5;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 8),
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 왼쪽 이미지 영역
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: AppColors.imagePlaceholder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "https://placehold.co/${imageSize.toInt()}x${imageSize.toInt()}",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: AppColors.imagePlaceholder);
                },
              ),
            ),
          ),
          SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
          // 텍스트 영역
          Expanded(
            child: Text(
              name,
              style: textTheme.bodySmall?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 12),
              ),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected ? AppColors.mainText : AppColors.inactiveText,
                ),
              ),
            ),
          );
        }).toList(),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodDetailScreen(food: food)),
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
                food.imageUrl,
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
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
    return SingleChildScrollView(
      key: _regionTabsKey,
      scrollDirection: Axis.horizontal,
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
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected ? AppColors.mainText : AppColors.inactiveText,
                ),
              ),
            ),
          );
        }).toList(),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketDetailScreen(market: market),
          ),
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
                market.imageUrls.isNotEmpty
                    ? market.imageUrls[0]
                    : "https://placehold.co/151x141",
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
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
