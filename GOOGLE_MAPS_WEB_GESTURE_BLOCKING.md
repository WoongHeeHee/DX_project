# Google Maps 웹 제스처 차단 - JavaScript 구현 계획

## 문제 분석

웹에서 Google Maps는 iframe으로 렌더링되므로, Flutter의 제스처 시스템만으로는 완전히 제어하기 어렵습니다. 특히:
- 마우스 휠 이벤트 (wheel)
- 드래그 이벤트 (mousedown, mousemove, mouseup)
- 터치 이벤트 (touchstart, touchmove, touchend)

이러한 이벤트들이 iframe 내부로 전파되어 지도가 확대/축소되거나 이동할 수 있습니다.

## 해결 방안

### 1. JavaScript를 통한 Google Maps iframe 제어

#### 접근 방법 A: CSS pointer-events 제어

바텀시트가 열려있을 때 Google Maps iframe의 `pointer-events` CSS 속성을 `none`으로 설정합니다.

**구현 위치**: `frontend/web/index.html` 또는 별도 JavaScript 파일

```javascript
// 바텀시트 상태를 추적하는 전역 변수
window.bottomSheetState = {
  isOpen: false,
  minSize: 0.1,
  currentSize: 0.4
};

// Google Maps iframe을 찾아서 pointer-events 제어
function updateMapPointerEvents() {
  const mapIframe = document.querySelector('iframe[src*="maps.googleapis.com"]');
  if (mapIframe) {
    if (window.bottomSheetState.isOpen && 
        window.bottomSheetState.currentSize > window.bottomSheetState.minSize) {
      // 바텀시트가 열려있을 때 지도 터치 차단
      mapIframe.style.pointerEvents = 'none';
    } else {
      // 바텀시트가 닫혀있을 때 지도 정상 작동
      mapIframe.style.pointerEvents = 'auto';
    }
  }
}

// Flutter에서 호출할 수 있는 함수
window.setBottomSheetState = function(isOpen, currentSize) {
  window.bottomSheetState.isOpen = isOpen;
  window.bottomSheetState.currentSize = currentSize;
  updateMapPointerEvents();
};
```

#### 접근 방법 B: 이벤트 리스너로 이벤트 차단

바텀시트 영역에서 발생하는 이벤트를 가로채서 지도로 전파되지 않도록 합니다.

```javascript
// 바텀시트 영역 계산
function getBottomSheetBounds() {
  const screenHeight = window.innerHeight;
  const sheetSize = window.bottomSheetState.currentSize;
  const sheetHeight = screenHeight * sheetSize;
  return {
    top: screenHeight - sheetHeight,
    bottom: screenHeight
  };
}

// 마우스 이벤트 차단
document.addEventListener('wheel', function(e) {
  const bounds = getBottomSheetBounds();
  if (e.clientY >= bounds.top && window.bottomSheetState.isOpen) {
    e.stopPropagation();
    e.preventDefault();
  }
}, { passive: false, capture: true });

// 드래그 이벤트 차단
let isDragging = false;
document.addEventListener('mousedown', function(e) {
  const bounds = getBottomSheetBounds();
  if (e.clientY >= bounds.top && window.bottomSheetState.isOpen) {
    isDragging = true;
    e.stopPropagation();
  }
}, { capture: true });

document.addEventListener('mousemove', function(e) {
  if (isDragging) {
    e.stopPropagation();
    e.preventDefault();
  }
}, { capture: true });

document.addEventListener('mouseup', function(e) {
  isDragging = false;
}, { capture: true });
```

### 2. Flutter와 JavaScript 통신

#### MethodChannel 사용

Flutter에서 JavaScript 함수를 호출하여 바텀시트 상태를 전달합니다.

**구현 위치**: `frontend/lib/features/map/market_map_detail_screen.dart`

```dart
import 'dart:js' as js;
import 'package:js/js.dart';

// 바텀시트 상태 변경 시 JavaScript 호출
void _updateBottomSheetState(double size) {
  if (kIsWeb) {
    final isOpen = size > _minSize;
    js.context.callMethod('setBottomSheetState', [isOpen, size]);
  }
}

// _onDragUpdate 메서드에서 호출
void _onDragUpdate() {
  if (!_draggableController.isAttached) return;

  final currentSize = _draggableController.size;
  _updateBottomSheetState(currentSize); // JavaScript에 상태 전달
  
  // ... 기존 스냅 로직
}
```

#### 또는 dart:html 사용

```dart
import 'dart:html' as html;

void _updateBottomSheetState(double size) {
  if (kIsWeb) {
    final isOpen = size > _minSize;
    html.window.callMethod('setBottomSheetState', [isOpen, size]);
  }
}
```

### 3. 구현 단계

#### Step 1: JavaScript 함수 추가
- `frontend/web/index.html`에 위의 JavaScript 코드 추가
- 또는 별도 파일 `frontend/web/gesture_blocking.js` 생성 후 HTML에서 로드

#### Step 2: Flutter 코드 수정
- `market_map_detail_screen.dart`와 `store_list_screen.dart`의 `_onDragUpdate` 메서드 수정
- 바텀시트 크기 변경 시 JavaScript 함수 호출

#### Step 3: 테스트
- 바텀시트가 열려있을 때 지도 터치/드래그/휠 이벤트가 차단되는지 확인
- 바텀시트가 닫혀있을 때 지도가 정상 작동하는지 확인

### 4. 대안: CSS만 사용

더 간단한 방법으로, 바텀시트가 열려있을 때 지도 위에 투명한 오버레이를 배치합니다.

```dart
// market_map_detail_screen.dart의 build 메서드
Stack(
  children: [
    GoogleMapWidget(...),
    // 바텀시트가 열려있을 때 투명 오버레이
    AnimatedBuilder(
      animation: _draggableController,
      builder: (context, child) {
        final sheetSize = _draggableController.isAttached
            ? _draggableController.size
            : _midSize;
        final shouldBlock = sheetSize > _minSize;
        
        if (!shouldBlock) return SizedBox.shrink();
        
        final screenHeight = MediaQuery.of(context).size.height;
        final sheetHeight = screenHeight * sheetSize;
        
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight - sheetHeight,
          child: IgnorePointer(
            ignoring: false,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        );
      },
    ),
    // ... 나머지 위젯들
  ],
)
```

이 방법은 Flutter만으로 구현 가능하지만, 바텀시트 영역 위의 지도 영역만 차단하므로 완전하지 않을 수 있습니다.

## 권장 사항

1. **우선 시도**: CSS `pointer-events` 방법 (접근 방법 A)
   - 구현이 간단하고 효과적
   - 성능 영향 최소

2. **추가 보완**: 이벤트 리스너 방법 (접근 방법 B)
   - 더 세밀한 제어 가능
   - 모든 이벤트 타입 차단 가능

3. **최종 대안**: Flutter 오버레이 방법
   - JavaScript 없이 구현 가능
   - 하지만 완전한 차단은 어려움

## 참고 사항

- Google Maps iframe의 `src` 속성이 동적으로 변경될 수 있으므로, iframe 선택자를 정확히 해야 합니다.
- 바텀시트 크기가 변경될 때마다 JavaScript 함수를 호출하므로 성능을 고려해야 합니다.
- 모바일에서는 터치 이벤트도 고려해야 합니다.

