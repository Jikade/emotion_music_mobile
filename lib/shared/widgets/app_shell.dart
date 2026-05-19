import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'bottom_mini_player.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, this.currentIndex, required this.child});

  final int? currentIndex;
  final Widget child;

  int _selectedIndex(String location) {
    if (location.startsWith('/nhanDienCamXuc')) return 1;
    if (location.startsWith('/thuVien')) return 2;
    if (location.startsWith('/lichSu') ||
        location.startsWith('/goiY') ||
        location.startsWith('/caiDat')) {
      return 3;
    }

    return 0;
  }

  void _handleDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/bangDieuKhien');
        break;
      case 1:
        context.go('/nhanDienCamXuc');
        break;
      case 2:
        context.go('/thuVien');
        break;
      case 3:
        _showMoreMenu(context);
        break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff070b12).withOpacity(0.98),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.42),
                  blurRadius: 42,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xff22d3ee).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xff22d3ee).withOpacity(0.24),
                        ),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Color(0xffa5f3fc),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu nhanh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Mở các trang phụ của hệ thống',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuRouteButton(
                  icon: Icons.history_rounded,
                  title: 'Lịch sử nghe',
                  subtitle: 'Xem các bài hát đã nghe theo từng tài khoản',
                  color: const Color(0xff22d3ee),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/lichSu');
                  },
                ),
                const SizedBox(height: 10),
                _MenuRouteButton(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Gợi ý dành riêng cho cậu',
                  subtitle: 'Đề xuất bài hát theo lịch sử, mood và lượt thích',
                  color: const Color(0xffa78bfa),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/goiY');
                  },
                ),
                const SizedBox(height: 10),
                _MenuRouteButton(
                  icon: Icons.settings_rounded,
                  title: 'Cài đặt tài khoản',
                  subtitle: 'Xem hồ sơ, trạng thái VIP PRO và đăng xuất',
                  color: const Color(0xffffd166),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/caiDat');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      backgroundColor: const Color(0xff05070d),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.25,
              colors: [Color(0x2214b8a6), Color(0xff05070d)],
            ),
          ),
          child: child,
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomMiniPlayer(),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xff070b12).withOpacity(0.98),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.34),
                  blurRadius: 28,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                indicatorColor: Colors.white.withOpacity(0.10),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);

                  return TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);

                  return IconThemeData(
                    color: selected ? Colors.white : Colors.white54,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                height: 70,
                elevation: 0,
                onDestinationSelected: (index) {
                  _handleDestinationSelected(context, index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Trang chủ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.psychology_alt_outlined),
                    selectedIcon: Icon(Icons.psychology_alt_rounded),
                    label: 'Cảm xúc',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music_rounded),
                    label: 'Thư viện',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_rounded),
                    selectedIcon: Icon(Icons.menu_open_rounded),
                    label: 'Menu',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRouteButton extends StatelessWidget {
  const _MenuRouteButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.28)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }
}
