// lib/core/widgets/custom_dropdown.dart

import "package:flutter/material.dart";
import "package:market_explorer_frontend/core/theme/app_colors.dart";
import "package:market_explorer_frontend/core/widgets/responsive_helper.dart";

/// 재사용 가능한 드롭다운 위젯
class CustomDropdown<T> extends StatefulWidget {
  final T? selectedValue;
  final List<T> items;
  final String Function(T) getLabel;
  final String? Function(T)? getImageUrl; // 이미지 URL (선택적)
  final void Function(T) onItemSelected;
  final bool isOpen;
  final void Function() onToggle;
  final double? width;
  final double? maxHeight;
  final String placeholder;
  final bool showCheckIcon;
  final bool useTextFieldStyle; // 텍스트 필드 스타일 사용 여부

  const CustomDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.getLabel,
    this.getImageUrl,
    required this.onItemSelected,
    required this.isOpen,
    required this.onToggle,
    this.width,
    this.maxHeight,
    this.placeholder = "선택",
    this.showCheckIcon = true,
    this.useTextFieldStyle = false,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isOpen) {
          _showOverlay();
        }
      });
    }
  }

  @override
  void didUpdateWidget(CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.isOpen) {
            _showOverlay();
          }
        });
      } else {
        _hideOverlay();
      }
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    // 버튼의 실제 너비를 사용 (width가 지정되지 않았거나 double.infinity인 경우)
    final dropdownWidth =
        (widget.width != null &&
            widget.width != double.infinity &&
            widget.width! > 0)
        ? widget.width!.toDouble()
        : size.width > 0
        ? size.width
        : 200.0;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 전체 화면을 덮는 투명한 영역 (외부 클릭 감지용)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                widget.onToggle();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // 드롭다운 메뉴
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              child: _buildDropdownMenu(context, dropdownWidth),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final textSize = responsive.responsiveFontSize(mobileSize: 16);
    final hasSelection = widget.selectedValue != null;

    return GestureDetector(
      key: _buttonKey,
      onTap: widget.onToggle,
      child: Container(
        width: widget.width != null ? widget.width : double.infinity,
        constraints: widget.useTextFieldStyle
            ? BoxConstraints(
                // TextField의 실제 높이를 1.5배로 설정
                // 텍스트 크기(16px) * line height(1.25) + padding(12px * 2) = 약 44px
                // 1.5배 = 약 66px
                minHeight: ((textSize * 1.25) + 
                    (responsive.responsivePadding(mobilePadding: 12) * 2)) * 1.5,
              )
            : null,
        padding: widget.useTextFieldStyle
            ? EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 16),
                vertical: responsive.responsivePadding(mobilePadding: 12),
              )
            : EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 12),
                vertical: responsive.responsivePadding(mobilePadding: 10),
              ),
        decoration: BoxDecoration(
          color: widget.useTextFieldStyle
              ? AppColors.white
              : AppColors.chipBackground,
          border: widget.useTextFieldStyle
              ? Border.all(
                  color: widget.isOpen
                      ? AppColors.mainText.withOpacity(0.5)
                      : const Color(0xFFF7F7F8),
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(
            widget.useTextFieldStyle ? 12 : 8,
          ),
        ),
        child: Row(
          mainAxisSize: widget.width != null
              ? MainAxisSize.min
              : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 이미지가 있는 경우 표시
            if (widget.getImageUrl != null && widget.selectedValue != null)
              Builder(
                builder: (context) {
                  final imageUrl = widget.getImageUrl!(widget.selectedValue!);
                  return Container(
                    width: responsive.responsiveIconSize(mobileSize: 30),
                    height: responsive.responsiveIconSize(mobileSize: 18),
                    decoration: BoxDecoration(
                      color: imageUrl != null
                          ? Colors.transparent
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.asset(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint("❌ 국기 이미지 로드 실패: $imageUrl");
                                return Container(color: AppColors.white);
                              },
                            ),
                          )
                        : null,
                  );
                },
              ),
            if (widget.getImageUrl != null && widget.selectedValue != null)
              SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
            // 선택된 값 또는 플레이스홀더
            Expanded(
              child: Text(
                widget.selectedValue != null
                    ? widget.getLabel(widget.selectedValue as T)
                    : widget.placeholder,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: widget.useTextFieldStyle
                      ? textSize
                      : responsive.responsiveFontSize(mobileSize: 13),
                  fontWeight: widget.useTextFieldStyle
                      ? (hasSelection ? FontWeight.w600 : FontWeight.w500)
                      : FontWeight.w600,
                  color: widget.useTextFieldStyle
                      ? (hasSelection
                          ? AppColors.mainText
                          : AppColors.inactiveText)
                      : AppColors.subText,
                  letterSpacing: widget.useTextFieldStyle && !hasSelection
                      ? 0.5
                      : 0,
                ),
              ),
            ),
            SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
            Icon(
              widget.isOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: responsive.responsiveIconSize(mobileSize: 16),
              color: widget.useTextFieldStyle
                  ? AppColors.mainText
                  : AppColors.subText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownMenu(BuildContext context, double dropdownWidth) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        // 드롭다운 메뉴 내부 클릭 시 이벤트 전파 중지
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: dropdownWidth,
        constraints: BoxConstraints(maxHeight: widget.maxHeight ?? 300),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF7F7F8),
            width: 1,
          ),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.all(
            responsive.responsivePadding(mobilePadding: 12),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.5,
          ),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected =
                widget.selectedValue != null &&
                _isEqual(widget.selectedValue as T, item);

            return InkWell(
              onTap: () {
                widget.onItemSelected(item);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.responsivePadding(mobilePadding: 12),
                  vertical: responsive.responsivePadding(mobilePadding: 10),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.chipBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 이미지가 있는 경우 표시
                    if (widget.getImageUrl != null)
                      Builder(
                        builder: (context) {
                          final imageUrl = widget.getImageUrl!(item);
                          final textSize = responsive.responsiveFontSize(mobileSize: 16);
                          final flagHeight = textSize * 1.25; // 폰트 높이에 맞춤
                          final flagWidth = flagHeight * 1.5; // 국기 비율 유지 (3:2)
                          return Container(
                            width: flagWidth,
                            height: flagHeight,
                            decoration: BoxDecoration(
                              color: imageUrl != null
                                  ? Colors.transparent
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Image.asset(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            debugPrint(
                                              "❌ 국기 이미지 로드 실패: $imageUrl",
                                            );
                                            return Container(
                                              color: AppColors.white,
                                            );
                                          },
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    if (widget.getImageUrl != null)
                      SizedBox(
                        width: responsive.responsivePadding(mobilePadding: 8),
                      ),
                    // 라벨
                    Expanded(
                      child: Text(
                        widget.getLabel(item),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: responsive.responsiveFontSize(
                            mobileSize: 16,
                          ),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.mainText
                              : AppColors.subText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 체크 아이콘
                    if (widget.showCheckIcon && isSelected)
                      Padding(
                        padding: EdgeInsets.only(
                          left: responsive.responsivePadding(mobilePadding: 4),
                        ),
                        child: Icon(
                          Icons.check,
                          size: responsive.responsiveIconSize(mobileSize: 16),
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isEqual(T a, T b) {
    // 객체 비교를 위한 헬퍼 메서드
    // 필요시 각 모델의 id를 비교하도록 수정 가능
    return a == b;
  }
}
