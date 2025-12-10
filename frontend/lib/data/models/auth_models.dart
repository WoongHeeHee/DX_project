/// 토큰 응답 모델
class TokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    if (accessToken == null) {
      throw FormatException('access_token이 응답에 없습니다. 응답: $json');
    }
    
    final expiresIn = json['expires_in'];
    if (expiresIn == null) {
      throw FormatException('expires_in이 응답에 없습니다. 응답: $json');
    }
    
    return TokenResponse(
      accessToken: accessToken as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: expiresIn is int ? expiresIn : int.tryParse(expiresIn.toString()) ?? 0,
    );
  }
}

/// 사용자 응답 모델
class UserResponse {
  final String id;
  final String displayName;
  final String? koreanName;
  final String? email;
  final String? country;
  final String? birthYyyyMm;
  final int spiceLevel;
  final String locale;

  UserResponse({
    required this.id,
    required this.displayName,
    this.koreanName,
    this.email,
    this.country,
    this.birthYyyyMm,
    required this.spiceLevel,
    required this.locale,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      koreanName: json['korean_name'] as String?,
      email: json['email'] as String?,
      country: json['country'] as String?,
      birthYyyyMm: json['birth_yyyy_mm'] as String?,
      spiceLevel: json['spice_level'] as int? ?? 3,
      locale: json['locale'] as String? ?? 'ko',
    );
  }
}

