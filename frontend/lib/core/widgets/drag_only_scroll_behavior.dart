// lib/core/widgets/drag_only_scroll_behavior.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 드래그만 허용하고 마우스 휠 스크롤을 비활성화하는 ScrollBehavior
class DragOnlyScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // 스크롤바 숨김
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

