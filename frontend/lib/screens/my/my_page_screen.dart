import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_navigation_bar.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/my/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 프로필 사진
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: user?.koreanName != null
                  ? Text(
                      user!.koreanName![0],
                      style: const TextStyle(fontSize: 40),
                    )
                  : const Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 10),
            // 이름
            if (user != null) ...[
              Text(
                user.koreanName ?? user.displayName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (user.englishPronunciation != null)
                Text(
                  user.englishPronunciation!,
                  style: const TextStyle(fontSize: 16),
                ),
            ],
            const SizedBox(height: 40),
            // 컨테이너들
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('리뷰(다이어리) 작성'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/my/diary');
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('핀한 가게'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/my/pinned-shops');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('저장한 메뉴'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/my/saved-menus');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('메뉴'),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('시장'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
    );
  }
}

