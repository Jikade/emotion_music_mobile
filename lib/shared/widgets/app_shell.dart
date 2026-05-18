import 'package:flutter/material.dart';

import 'bottom_player.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTap,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomPlayer(),
          NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite),
                label: 'Gợi ý',
              ),
              NavigationDestination(
                icon: Icon(Icons.mood_outlined),
                selectedIcon: Icon(Icons.mood),
                label: 'Cảm xúc',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Lịch sử',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
