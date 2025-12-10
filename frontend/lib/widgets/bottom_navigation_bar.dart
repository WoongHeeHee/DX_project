import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../core/theme/app_colors.dart";

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.subText,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 10,
      ),
      backgroundColor: AppColors.white,
      elevation: 4,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go("/explore");
            break;
          case 1:
            context.go("/map");
            break;
          case 2:
            context.go("/camera");
            break;
          case 3:
            context.go("/my");
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: "탐색",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: "지도",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: "카메라",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "마이",
        ),
      ],
    );
  }
}

