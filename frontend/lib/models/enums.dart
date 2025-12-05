// 언어 선택
enum UserLocale {
  ko('ko', '한국어'),
  en('en', 'English'),
  zh('zh', '中文'),
  ja('ja', '日本語');

  final String value;
  final String displayName;
  const UserLocale(this.value, this.displayName);

  static UserLocale fromString(String value) {
    return UserLocale.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserLocale.ko,
    );
  }
}

// 모험 수준 (도전 강도)
enum AdventureLevel {
  conservative('conservative', '안정형'),
  moderate('moderate', '몰라요'),
  adventurous('adventurous', '도전형');

  final String value;
  final String displayName;
  const AdventureLevel(this.value, this.displayName);

  static AdventureLevel fromString(String value) {
    return AdventureLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AdventureLevel.moderate,
    );
  }
}

// 한식 경험 수준
enum KoreanExperience {
  firstTime('first_time', '뉴비'),
  someExperience('some_experience', '즐겜러'),
  frequentVisitor('frequent_visitor', '고인물'),
  livingInKorea('living_in_korea', '고인물');

  final String value;
  final String displayName;
  const KoreanExperience(this.value, this.displayName);

  static KoreanExperience fromString(String value) {
    return KoreanExperience.values.firstWhere(
      (e) => e.value == value,
      orElse: () => KoreanExperience.firstTime,
    );
  }
}

// 맵기 수준 (1-5)
enum SpiceLevel {
  level1(1, '🔥'),
  level2(2, '🔥🔥'),
  level3(3, '🔥🔥🔥'),
  level4(4, '🔥🔥🔥🔥'),
  level5(5, '🔥🔥🔥🔥🔥');

  final int value;
  final String display;
  const SpiceLevel(this.value, this.display);

  static SpiceLevel fromInt(int value) {
    return SpiceLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SpiceLevel.level3,
    );
  }
}

// 메뉴 카테고리
enum MenuCategory {
  meals('Meals', '식사'),
  snacks('Snacks', '간식'),
  sweets('Sweets', '디저트'),
  drinks('Drink', '음료수');

  final String value;
  final String displayName;
  const MenuCategory(this.value, this.displayName);
}

// 시장 지역
enum MarketRegion {
  seoul('서울', 'Seoul'),
  busan('부산', 'Busan'),
  jeju('제주도', 'Jeju'),
  incheon('인천', 'Incheon');

  final String koreanName;
  final String englishName;
  const MarketRegion(this.koreanName, this.englishName);
}

// 다이어리 키워드
enum DiaryKeyword {
  mostlyLocals('mostly_locals', '대부분 현지인들이 방문해요'),
  mostlyTourists('mostly_tourists', '대부분 관광객들이 방문해요'),
  quiet('quiet', '한적해요'),
  spacious('spacious', '내부가 넓어요'),
  cramped('cramped', '가게가 협소해요'),
  parking('parking', '주차하기 좋아요'),
  publicTransport('public_transport', '대중교통이 편해요'),
  friendly('friendly', '사람들이 친절해요');

  final String value;
  final String displayName;
  const DiaryKeyword(this.value, this.displayName);

  static DiaryKeyword fromString(String value) {
    return DiaryKeyword.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DiaryKeyword.friendly,
    );
  }
}

// 가게 상태
enum ShopStatus {
  open('open', '영업 중', 0xFF4CAF50), // 녹색
  uncertain('uncertain', '불확실', 0xFFFFC107), // 황색
  closed('closed', '영업 종료', 0xFFF44336); // 적색

  final String value;
  final String displayName;
  final int color;
  const ShopStatus(this.value, this.displayName, this.color);
}

