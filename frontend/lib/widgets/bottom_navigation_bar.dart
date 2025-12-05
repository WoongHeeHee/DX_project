import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/explore');
            break;
          case 1:
            context.go('/map');
            break;
          case 2:
            context.go('/camera');
            break;
          case 3:
            context.go('/my');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: '탐색',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: '지도',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: '카메라',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '마이',
        ),
      ],
    );
  }
}

