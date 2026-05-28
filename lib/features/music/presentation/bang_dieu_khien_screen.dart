import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/song_grid.dart';
import '../../auth/providers/auth_providers.dart';
import '../../payments/presentation/vip_pro_payment_sheet.dart';

class BangDieuKhienScreen extends StatefulWidget {
  const BangDieuKhienScreen({super.key});

  @override
  State<BangDieuKhienScreen> createState() => _BangDieuKhienScreenState();
}

class _BangDieuKhienScreenState extends State<BangDieuKhienScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _showScrollTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final shouldShow = _scrollController.offset > 260;

    if (shouldShow == _showScrollTopButton) return;

    setState(() {
      _showScrollTopButton = shouldShow;
    });
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: NestedScrollView(
            controller: _scrollController,
            floatHeaderSlivers: false,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _DashboardHeader(),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 18)),
              ];
            },
            body: const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: SongGrid(
                emptyMessage:
                    'Không có bài hát nào phù hợp với bộ lọc hiện tại.',
              ),
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 96,
          child: IgnorePointer(
            ignoring: !_showScrollTopButton,
            child: AnimatedOpacity(
              opacity: _showScrollTopButton ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: AnimatedSlide(
                offset: _showScrollTopButton
                    ? Offset.zero
                    : const Offset(0, 0.3),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: _ScrollTopButton(onTap: _scrollToTop),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;

        if (isWide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageHeader(
                  eyebrow: 'Bảng điều khiển',
                  title: 'Không gian nghe của cậu',
                  description:
                      'Dùng thanh lọc bên trên để tìm bài hát, lọc theo mood hoặc chỉ xem các bài đã like.',
                ),
              ),
              SizedBox(width: 16),
              _HeaderActions(),
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
            Align(alignment: Alignment.centerRight, child: _HeaderActions()),
          ],
        );
      },
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [_VipProHeaderButton(), _HeaderAuthButton()],
    );
  }
}

class _VipProHeaderButton extends ConsumerWidget {
  const _VipProHeaderButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isVip = authState.user?.isVip == true;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        showVipProPaymentSheet(context);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isVip
                ? [
                    const Color(0xff34d399).withOpacity(0.24),
                    const Color(0xff22d3ee).withOpacity(0.10),
                  ]
                : [
                    const Color(0xffffd166).withOpacity(0.28),
                    const Color(0xfff97316).withOpacity(0.12),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isVip
                ? const Color(0xff34d399).withOpacity(0.32)
                : const Color(0xffffd166).withOpacity(0.36),
          ),
          boxShadow: [
            BoxShadow(
              color: (isVip ? const Color(0xff34d399) : const Color(0xffffd166))
                  .withOpacity(0.15),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVip ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              color: isVip ? const Color(0xffbbf7d0) : const Color(0xffffd166),
              size: 21,
            ),
            const SizedBox(width: 9),
            Text(
              isVip ? 'VIP PRO' : 'Nâng cấp VIP PRO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isVip
                    ? const Color(0xffbbf7d0)
                    : const Color(0xffffd166),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
    final avatarLetter = displayName.trim().isEmpty
        ? 'U'
        : displayName.trim()[0].toUpperCase();
    final avatarUrl = user.avatarUrl?.trim();

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
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _AvatarInitial(letter: avatarLetter);
                          },
                        )
                      : _AvatarInitial(letter: avatarLetter),
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

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
    );
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

class _ScrollTopButton extends StatelessWidget {
  const _ScrollTopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xff070b12).withOpacity(0.96),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.38),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}
