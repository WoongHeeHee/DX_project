/// 온보딩 데이터 유틸리티
class OnboardingData {
  // 국가 코드 매핑 (CountryFilter.id -> ISO 2자리 코드)
  static String? getCountryCode(String countryId) {
    final mapping = {
      'country_jp': 'JP',
      'country_us': 'US',
      'country_cn': 'CN',
      'country_kr': 'KR',
      'country_th': 'TH',
      'country_vn': 'VN',
      'country_sg': 'SG',
      'country_my': 'MY',
      'country_id': 'ID',
      'country_ph': 'PH',
      'country_in': 'IN',
      'country_tw': 'TW',
      'country_hk': 'HK',
      'country_au': 'AU',
      'country_ca': 'CA',
      'country_gb': 'GB',
      'country_fr': 'FR',
      'country_de': 'DE',
      'country_ru': 'RU',
      'country_mx': 'MX',
      'country_mn': 'MN',
    };
    return mapping[countryId];
  }

  // 스타일 -> adventure 매핑
  static String getAdventureFromStyle(String style) {
    final mapping = {
      '신중하게 고민하는 편': 'conservative',
      '일단 시도하는 편': 'adventurous',
      '잘 모르겠어요': 'moderate',
    };
    return mapping[style] ?? 'moderate';
  }

  // 한국 경험 수준 매핑 (기본값: first_time)
  // TODO: 실제 화면에서 선택할 수 있도록 수정 필요
  static String getKoreanExperience() {
    return 'first_time'; // 기본값
  }
}

