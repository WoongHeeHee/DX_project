// lib/features/map/widgets/must_eat_section.dart

import "package:flutter/material.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/theme/app_colors.dart";
import "../../home/models/market_model.dart";
import "../../home/constants/must_try_items.dart";

/// 메뉴 이미지를 로드하고 에러 시 대체 경로를 시도하는 위젯
class _MenuImageWithFallback extends StatefulWidget {
  final List<String> urls;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _MenuImageWithFallback({
    required this.urls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<_MenuImageWithFallback> createState() => _MenuImageWithFallbackState();
}

class _MenuImageWithFallbackState extends State<_MenuImageWithFallback> {
  int _currentUrlIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentUrlIndex >= widget.urls.length) {
      // 모든 URL 시도 실패
      return Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFFF3EEF3),
      );
    }

    return Image.network(
      widget.urls[_currentUrlIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        // 다음 URL 시도
        if (_currentUrlIndex < widget.urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentUrlIndex++;
              });
            }
          });
          // 로딩 중 표시
          return Container(
            width: widget.width,
            height: widget.height,
            color: const Color(0xFFF3EEF3),
          );
        }
        // 모든 URL 시도 실패
        return Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFFF3EEF3),
        );
      },
    );
  }
}

/// Must Eat 섹션 위젯
class MustEatSection extends StatelessWidget {
  final MarketModel market;

  const MustEatSection({
    super.key,
    required this.market,
  });

  // 메뉴 ID에서 메뉴 이름 매핑
  static const Map<String, String> _menuIdToName = {
    "ME012": "김밥",
    "ME327": "식혜",
    "ME016": "꼬마김밥",
    "ME175": "빈대떡",
    "ME197": "육회",
    "ME148": "닭강정",
    "ME155": "떡볶이",
    "ME131": "구운옥수수",
    "ME134": "기름떡볶이",
    "ME149": "닭꼬치",
    "ME166": "모둠전",
    "ME147": "녹두전",
    "ME343": "소머리국밥",
    "ME299": "호떡",
    "ME181": "순대볶음",
    "ME243": "꽈배기",
    "ME354": "만두",
    "ME237": "공갈빵",
    "ME094": "쫄면",
    "ME032": "떡갈비",
    "ME192": "오징어순대",
    "ME352": "술빵",
    "ME345": "곤드레밥",
    "ME346": "콧등치기국수",
    "ME351": "장터국밥",
    "ME191": "옛날통닭",
    "ME347": "꼬막비빔국수",
    "ME019": "내장국밥",
    "ME350": "육전",
    "ME353": "찜닭",
    "ME348": "간고등어",
    "ME349": "헛제사밥",
    "ME038": "막창구이",
    "ME146": "납작만두",
    "ME187": "어묵꼬치",
    "ME275": "오메기떡",
    "ME119": "회국수",
    "ME004": "갈치조림",
    "ME251": "딸기찹쌀떡",
  };

  String _placeholderImage(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    // 경로 규칙: placeholders/Menu_all/{name}/{name}{variant}_{id}.png
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/${encodedName}/${encodedName}${clamped}_${id}.png";
  }
  
  /// 메뉴 placeholder 이미지의 대체 경로 반환
  /// 원본 경로와 대체 경로(잘못 저장된 형식)를 모두 반환
  List<String> _placeholderImageUrls(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    final baseUrl = "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/${encodedName}";
    
    // 원본 경로: {name}{variant}_{id}.png
    final originalUrl = "$baseUrl/${encodedName}${clamped}_${id}.png";
    // 대체 경로: {name}_{name}{variant}_{id}.png
    final alternateUrl = "$baseUrl/${encodedName}_${encodedName}${clamped}_${id}.png";
    
    return [originalUrl, alternateUrl];
  }

  List<MustTryItem> _getDefaultMustTryItems() {
    final marketName = market.name;
    final mustTryIds = mustTryItemsByMarket[marketName] ?? [];

    if (mustTryIds.isEmpty) {
      // 기본값 (다른 시장의 경우)
      return [
        MustTryItem(
          id: "ME016",
          name: "꼬마김밥",
          description: "",
          imageUrl: _placeholderImage("꼬마김밥", "ME016"),
        ),
        MustTryItem(
          id: "ME175",
          name: "빈대떡",
          description: "",
          imageUrl: _placeholderImage("빈대떡", "ME175"),
        ),
        MustTryItem(
          id: "ME197",
          name: "육회",
          description: "",
          imageUrl: _placeholderImage("육회", "ME197"),
        ),
      ];
    }

    return mustTryIds.map((menuId) {
      final menuName = _menuIdToName[menuId] ?? menuId;
      return MustTryItem(
        id: menuId,
        name: menuName,
        description: "",
        imageUrl: _placeholderImage(menuName, menuId),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    final mustTryItems = market.mustTryItems.isNotEmpty
        ? market.mustTryItems
        : _getDefaultMustTryItems();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Must eat ${market.name.toLowerCase().replaceAll("시장", "").trim()}",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w500,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: mustTryItems.take(3).map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: responsive.responsiveIconSize(mobileSize: 100),
                      height: responsive.responsiveIconSize(mobileSize: 100),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEF3),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _MenuImageWithFallback(
                          urls: _placeholderImageUrls(item.name, item.id, variant: 1),
                          width: responsive.responsiveIconSize(mobileSize: 100),
                          height: responsive.responsiveIconSize(mobileSize: 100),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 6),
                    ),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 13),
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainText,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

