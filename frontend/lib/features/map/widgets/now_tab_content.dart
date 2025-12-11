// lib/features/map/widgets/now_tab_content.dart

import "package:flutter/material.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/widgets/responsive_padding.dart";
import "../../home/models/market_model.dart";
import "must_eat_section.dart";
import "feed_header.dart";
import "feed_image_slider.dart";
import "action_buttons.dart";

/// NOW 탭 콘텐츠 위젯
class NowTabContent extends StatelessWidget {
  final MarketModel market;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const NowTabContent({
    super.key,
    required this.market,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Must eat 섹션
          MustEatSection(market: market),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 피드 섹션 (제목과 필터)
          FeedHeader(
            marketName: market.name,
            selectedFilter: selectedFilter,
            onFilterChanged: onFilterChanged,
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 피드 이미지 영역 (전체 너비)
          FeedImageSlider(
            marketId: market.id,
            selectedFilter: selectedFilter,
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 버튼들
          ActionButtons(market: market),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
        ],
      ),
    );
  }
}

