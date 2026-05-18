import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.currentIndex});

  final Widget child;
  final int currentIndex;

  void _goToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/bangDieuKhien');
        break;
      case 1:
        context.go('/thuVien');
        break;
      case 2:
        context.go('/dangPhat');
        break;
      case 3:
        context.go('/nhanDienCamXuc');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          authState.user == null
              ? 'Emotion Music'
              : 'Xin chào, ${authState.user!.name}',
        ),
        actions: [
          if (authState.isLoggedIn)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();

                if (context.mounted) {
                  context.go('/dangNhap');
                }
              },
              icon: const Icon(Icons.logout),
            )
          else
            TextButton(
              onPressed: () => context.go('/dangNhap'),
              child: const Text('Đăng nhập'),
            ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _goToPage(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Bảng điều khiển',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Thư viện',
          ),
          NavigationDestination(
            icon: Icon(Icons.album_outlined),
            selectedIcon: Icon(Icons.album),
            label: 'Đang phát',
          ),
          NavigationDestination(
            icon: Icon(Icons.mood_outlined),
            selectedIcon: Icon(Icons.mood),
            label: 'Cảm xúc',
          ),
        ],
      ),
    );
  }
}
