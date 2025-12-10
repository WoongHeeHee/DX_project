// lib/core/widgets/main_navigation.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "../../features/home/explore_screen.dart";
import "../../features/map/map_screen.dart";

/// 메인 네비게이션 바를 포함한 스캐폴드
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // 지도 화면을 기본으로 설정
  final ImagePicker _picker = ImagePicker();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      label: "탐색",
      route: "/explore",
      // 아이콘은 추후 등록 예정
    ),
    NavigationItem(
      label: "지도",
      route: "/map",
      // 아이콘은 추후 등록 예정
    ),
    NavigationItem(
      label: "카메라",
      route: "/camera",
      // 아이콘은 추후 등록 예정
    ),
    NavigationItem(
      label: "마이",
      route: "/my",
      // 아이콘은 추후 등록 예정
    ),
  ];

  void _onItemTapped(int index) {
    // 카메라 버튼(index 2)을 누르면 바로 카메라 실행
    if (index == 2) {
      _handleCameraTap();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleCameraTap() async {
    try {
      // 먼저 프리뷰 화면 표시
      await context.push('/camera/preview');

      // 2초 후 카메라 실행
      if (!mounted) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // 촬영 성공 시 성공 화면으로 이동
        await context.push('/camera/success');

        // 성공 화면에서 돌아온 후 홈화면(탐색 화면)으로 이동
        if (mounted) {
          setState(() {
            _currentIndex = 0; // 탐색 화면으로 이동
          });
        }
      } else if (mounted) {
        // 촬영을 취소한 경우 현재 화면 유지
        // _currentIndex는 변경하지 않음
      }
    } catch (e) {
      debugPrint("카메라 실행 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("카메라를 실행할 수 없습니다."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: _navigationItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(
              Icons.circle_outlined, // 임시 아이콘, 추후 교체 예정
              size: 24,
            ),
            activeIcon: Icon(
              Icons.circle, // 임시 아이콘, 추후 교체 예정
              size: 24,
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const ExploreScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const Center(
          child: Text("카메라 화면"),
        );
      case 3:
        return const Center(
          child: Text("마이 화면"),
        );
      default:
        return const ExploreScreen();
    }
  }
}

class NavigationItem {
  final String label;
  final String route;

  NavigationItem({
    required this.label,
    required this.route,
  });
}

