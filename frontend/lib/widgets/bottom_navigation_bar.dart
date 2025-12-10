import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          return Expanded(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.subText,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.subText,
                    ),
                  ),
                ],
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

