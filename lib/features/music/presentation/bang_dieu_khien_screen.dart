import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/song_grid.dart';

class BangDieuKhienScreen extends StatelessWidget {
  const BangDieuKhienScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHeader(),
          SizedBox(height: 18),
          Expanded(
            child: SongGrid(
              emptyMessage: 'Không có bài hát nào phù hợp với bộ lọc hiện tại.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final title = const Expanded(
          child: PageHeader(
            eyebrow: 'Bảng điều khiển',
            title: 'Không gian nghe của cậu',
            description:
                'Dùng thanh lọc bên trên để tìm bài hát, lọc theo mood hoặc chỉ xem các bài đã like.',
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(width: 16),
              const _HeaderAuthButton(),
            ],
          );
        }

        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              eyebrow: 'Bảng điều khiển',
              title: 'Không gian nghe của cậu',
              description:
                  'Dùng thanh lọc bên trên để tìm bài hát, lọc theo mood hoặc chỉ xem các bài đã like.',
            ),
            SizedBox(height: 14),
            Align(alignment: Alignment.centerRight, child: _HeaderAuthButton()),
          ],
        );
      },
    );
  }
}

class _HeaderAuthButton extends ConsumerWidget {
  const _HeaderAuthButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isLoggedIn = user != null;

    if (!isLoggedIn) {
      return _AuthShell(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            context.go('/dangNhap');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xff22d3ee).withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xff22d3ee).withOpacity(0.28),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login_rounded, color: Color(0xffa5f3fc), size: 20),
                SizedBox(width: 9),
                Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: Color(0xffa5f3fc),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayName = user.name.trim().isNotEmpty ? user.name.trim() : 'User';
    final email = user.email.trim();
    final avatarLetter = displayName.characters.first.toUpperCase();

    return _AuthShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Mở cài đặt tài khoản',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                context.go('/caiDat');
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff22d3ee), Color(0xffa78bfa)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff22d3ee).withOpacity(0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.46),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Đăng xuất',
            child: IconButton(
              onPressed: () async {
                await _confirmAndLogout(context, ref);
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.12),
                foregroundColor: Colors.redAccent.shade100,
                fixedSize: const Size(42, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.22)),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff0b1020),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          title: const Text(
            'Đăng xuất?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Bạn có chắc muốn đăng xuất khỏi tài khoản hiện tại không?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.64),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await Future.sync(() => ref.read(authControllerProvider.notifier).logout());

    if (!context.mounted) return;

    context.go('/dangNhap');
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
