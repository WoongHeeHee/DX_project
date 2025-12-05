import 'package:uuid/uuid.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String? email;
  final String displayName;
  final String? koreanName;
  final String? englishPronunciation;
  final String? country;
  final String? birthYyyyMm;
  final int spiceLevel;
  final AdventureLevel adventure;
  final KoreanExperience koreanExperience;
  final UserLocale locale;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    this.email,
    required this.displayName,
    this.koreanName,
    this.englishPronunciation,
    this.country,
    this.birthYyyyMm,
    this.spiceLevel = 3,
    this.adventure = AdventureLevel.moderate,
    this.koreanExperience = KoreanExperience.firstTime,
    this.locale = UserLocale.ko,
    this.onboardingCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      email: json['email'],
      displayName: json['display_name'] ?? '',
      koreanName: json['korean_name'],
      country: json['country'],
      birthYyyyMm: json['birth_yyyy_mm'],
      spiceLevel: json['spice_level'] ?? 3,
      adventure: AdventureLevel.fromString(json['adventure'] ?? 'moderate'),
      koreanExperience: KoreanExperience.fromString(json['korean_experience'] ?? 'first_time'),
      locale: UserLocale.fromString(json['locale'] ?? 'ko'),
      onboardingCompleted: json['onboarding_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'korean_name': koreanName,
      'country': country,
      'birth_yyyy_mm': birthYyyyMm,
      'spice_level': spiceLevel,
      'adventure': adventure.value,
      'korean_experience': koreanExperience.value,
      'locale': locale.value,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? koreanName,
    String? englishPronunciation,
    String? country,
    String? birthYyyyMm,
    int? spiceLevel,
    AdventureLevel? adventure,
    KoreanExperience? koreanExperience,
    UserLocale? locale,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      koreanName: koreanName ?? this.koreanName,
      englishPronunciation: englishPronunciation ?? this.englishPronunciation,
      country: country ?? this.country,
      birthYyyyMm: birthYyyyMm ?? this.birthYyyyMm,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      adventure: adventure ?? this.adventure,
      koreanExperience: koreanExperience ?? this.koreanExperience,
      locale: locale ?? this.locale,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

