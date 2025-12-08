import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final String? returnPath;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.returnPath,
  });

  @override
  Widget build(BuildContext context) {
    const selectedBg = Color(0xFFE9DFF0);
    const unselectedBg = Color(0xFFF7F7F8);
    const selectedIcon = Color(0xFF4B2E83);
    const unselectedIcon = Color(0xFF9CA3AF);

    final items = [
      _NavItem(
        icon: Icons.explore,
        label: '탐색',
        route: '/explore',
      ),
      _NavItem(
        icon: Icons.map,
        label: '지도',
        route: '/map',
      ),
      _NavItem(
        icon: Icons.camera_alt,
        label: '카메라',
        route: '/camera',
      ),
      _NavItem(
        icon: Icons.person,
        label: '마이',
        route: '/my',
      ),
    ];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
        switch (index) {
          case 0:
                      context.go(item.route);
            break;
          case 1:
                      context.go(item.route);
            break;
          case 2:
                      final path =
                          returnPath ?? GoRouterState.of(context).uri.toString();
                      context.go(item.route, extra: {'returnPath': path});
            break;
          case 3:
                      context.go(item.route);
            break;
        }
      },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? selectedBg : unselectedBg,
                    borderRadius: BorderRadius.circular(8),
        ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: selected ? selectedIcon : unselectedIcon,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? selectedIcon : unselectedIcon,
                        ),
                      ),
                    ],
        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

