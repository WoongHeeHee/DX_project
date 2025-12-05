// lib/core/widgets/custom_dropdown.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";

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

    return GestureDetector(
      key: _buttonKey,
      onTap: widget.onToggle,
      child: Container(
        width: widget.width != null ? widget.width : double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 12),
          vertical: responsive.responsivePadding(mobilePadding: 10),
        ),
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: widget.width != null
              ? MainAxisSize.min
              : MainAxisSize.max,
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
                          : AppColors.filterColor,
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
                                return Container(color: AppColors.filterColor);
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
            Text(
              widget.selectedValue != null
                  ? widget.getLabel(widget.selectedValue as T)
                  : widget.placeholder,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 13),
                fontWeight: FontWeight.w600,
                color: AppColors.subText,
              ),
            ),
            SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
            Icon(
              widget.isOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: responsive.responsiveIconSize(mobileSize: 16),
              color: AppColors.subText,
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
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
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
              child: Container(
                padding: EdgeInsets.only(
                  left: responsive.responsivePadding(mobilePadding: 12),
                  right: responsive.responsivePadding(mobilePadding: 12),
                  top: index == 0
                      ? responsive.responsivePadding(mobilePadding: 8)
                      : responsive.responsivePadding(mobilePadding: 10),
                  bottom: index == widget.items.length - 1
                      ? responsive.responsivePadding(mobilePadding: 8)
                      : responsive.responsivePadding(mobilePadding: 10),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.chipBackground
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // 이미지가 있는 경우 표시
                    if (widget.getImageUrl != null)
                      Builder(
                        builder: (context) {
                          final imageUrl = widget.getImageUrl!(item);
                          return Container(
                            width: responsive.responsiveIconSize(
                              mobileSize: 24,
                            ),
                            height: responsive.responsiveIconSize(
                              mobileSize: 16,
                            ),
                            decoration: BoxDecoration(
                              color: imageUrl != null
                                  ? Colors.transparent
                                  : AppColors.filterColor,
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
                                              color: AppColors.filterColor,
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
                            mobileSize: 13,
                          ),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.mainText
                              : AppColors.subText,
                        ),
                      ),
                    ),
                    // 체크 아이콘
                    if (widget.showCheckIcon && isSelected)
                      Icon(
                        Icons.check,
                        size: responsive.responsiveIconSize(mobileSize: 16),
                        color: AppColors.primary,
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
