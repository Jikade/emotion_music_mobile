import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';

class CaiDatScreen extends ConsumerStatefulWidget {
  const CaiDatScreen({super.key});

  @override
  ConsumerState<CaiDatScreen> createState() => _CaiDatScreenState();
}

class _CaiDatScreenState extends ConsumerState<CaiDatScreen> {
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  String? _message;

  Future<void> _refreshUser() async {
    setState(() {
      _isRefreshing = true;
      _message = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).refreshUser();

      if (!mounted) return;

      setState(() {
        _message = 'Đã cập nhật thông tin tài khoản mới nhất.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message = 'Không thể cập nhật thông tin tài khoản. Vui lòng thử lại.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _logout() async {
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
              color: Colors.white.withOpacity(0.68),
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

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).logout();

      if (!mounted) return;

      context.go('/dangNhap');
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Material(
      color: const Color(0xff05070d),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Builder(
              builder: (context) {
                if (authState.isLoading) {
                  return const _LoadingProfile();
                }

                if (user == null) {
                  return _LoginRequiredCard(
                    onLogin: () => context.go('/dangNhap'),
                  );
                }

                final isAdmin =
                    user.email == 'admin@gmail.com' || user.role == 'admin';
                final isVipPro = user.isVip;
                final displayName = user.name.trim().isNotEmpty
                    ? user.name.trim()
                    : 'Người dùng MoodSync';
                final initial = _getInitial(user.name, user.email);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHero(
                      displayName: displayName,
                      email: user.email,
                      avatarUrl: user.avatarUrl,
                      initial: initial,
                      isVipPro: isVipPro,
                      isAdmin: isAdmin,
                      isRefreshing: _isRefreshing,
                      isLoggingOut: _isLoggingOut,
                      onRefresh: _refreshUser,
                      onLogout: _logout,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      _InfoMessage(message: _message!),
                    ],
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;

                        final accountInfo = _AccountInfoSection(
                          userId: user.id,
                          name: displayName,
                          email: user.email,
                          authProvider: user.authProvider,
                          isAdmin: isAdmin,
                          isVipPro: isVipPro,
                        );

                        final sideInfo = _SideInfoSection(
                          isVipPro: isVipPro,
                          isAdmin: isAdmin,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 13, child: accountInfo),
                              const SizedBox(width: 18),
                              Expanded(flex: 8, child: sideInfo),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            accountInfo,
                            const SizedBox(height: 18),
                            sideInfo,
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getInitial(String? name, String email) {
    final source = (name?.trim().isNotEmpty == true ? name!.trim() : email)
        .trim();

    if (source.isEmpty) return 'U';

    return source.characters.first.toUpperCase();
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.initial,
    required this.isVipPro,
    required this.isAdmin,
    required this.isRefreshing,
    required this.isLoggingOut,
    required this.onRefresh,
    required this.onLogout,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final String initial;
  final bool isVipPro;
  final bool isAdmin;
  final bool isRefreshing;
  final bool isLoggingOut;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffffd166).withOpacity(0.16),
            const Color(0xff070b12),
            const Color(0xffa78bfa).withOpacity(0.13),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 46,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 780;

          final profile = Row(
            children: [
              _AvatarBox(
                avatarUrl: avatarUrl,
                initial: initial,
                isVipPro: isVipPro,
                size: isWide ? 112 : 88,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeaderPill(
                      icon: Icons.person_rounded,
                      label: 'Hồ sơ người dùng',
                    ),
                    const SizedBox(height: 13),
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWide ? 34 : 25,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.white.withOpacity(0.50),
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.58),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusBadge(
                          icon: Icons.workspace_premium_rounded,
                          label: isVipPro
                              ? 'VIP PRO đã kích hoạt'
                              : 'Chưa có VIP PRO',
                          color: isVipPro
                              ? const Color(0xffffd166)
                              : Colors.white70,
                        ),
                        _StatusBadge(
                          icon: Icons.shield_rounded,
                          label: isAdmin ? 'Admin' : 'User',
                          color: isAdmin
                              ? const Color(0xff34d399)
                              : Colors.white70,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: isWide ? WrapAlignment.end : WrapAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white.withOpacity(0.18),
                  disabledForegroundColor: Colors.white.withOpacity(0.45),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  isRefreshing ? 'Đang cập nhật...' : 'Cập nhật hồ sơ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: isLoggingOut ? null : onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent.shade100,
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.30)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: profile),
                const SizedBox(width: 18),
                actions,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [profile, const SizedBox(height: 18), actions],
          );
        },
      ),
    );
  }
}

class _AccountInfoSection extends StatelessWidget {
  const _AccountInfoSection({
    required this.userId,
    required this.name,
    required this.email,
    required this.authProvider,
    required this.isAdmin,
    required this.isVipPro,
  });

  final int userId;
  final String name;
  final String email;
  final String? authProvider;
  final bool isAdmin;
  final bool isVipPro;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.account_circle_rounded,
            title: 'Thông tin tài khoản',
            subtitle: 'Các thông tin được lấy từ tài khoản đang đăng nhập.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 620;

              final cards = [
                _InfoTile(
                  label: 'ID người dùng',
                  value: '#$userId',
                  icon: Icons.tag_rounded,
                ),
                _InfoTile(
                  label: 'Tên hiển thị',
                  value: name,
                  icon: Icons.badge_rounded,
                ),
                _InfoTile(
                  label: 'Email',
                  value: email,
                  icon: Icons.mail_rounded,
                ),
                _InfoTile(
                  label: 'Phương thức đăng nhập',
                  value: _getProviderLabel(authProvider),
                  icon: Icons.login_rounded,
                ),
                _InfoTile(
                  label: 'Vai trò',
                  value: isAdmin ? 'Quản trị viên' : 'Người dùng',
                  icon: Icons.shield_rounded,
                ),
                _InfoTile(
                  label: 'Trạng thái VIP PRO',
                  value: isVipPro ? 'Đã kích hoạt' : 'Chưa kích hoạt',
                  icon: Icons.workspace_premium_rounded,
                ),
              ];

              return GridView.builder(
                itemCount: cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.65 : 3.3,
                ),
                itemBuilder: (context, index) => cards[index],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getProviderLabel(String? provider) {
    final value = provider?.trim().toLowerCase();

    if (value == null || value.isEmpty) return 'Không xác định';
    if (value == 'local') return 'Email / Mật khẩu';
    if (value == 'google') return 'Google';

    return provider!;
  }
}

class _SideInfoSection extends StatelessWidget {
  const _SideInfoSection({required this.isVipPro, required this.isAdmin});

  final bool isVipPro;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GlassSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.workspace_premium_rounded,
                title: 'Gói VIP PRO',
                subtitle: 'Trạng thái quyền tải nhạc độc quyền.',
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color:
                      (isVipPro
                              ? const Color(0xff34d399)
                              : const Color(0xffffd166))
                          .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        (isVipPro
                                ? const Color(0xff34d399)
                                : const Color(0xffffd166))
                            .withOpacity(0.24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isVipPro
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      color: isVipPro
                          ? const Color(0xff34d399)
                          : const Color(0xffffd166),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        isVipPro
                            ? 'Tài khoản đã được duyệt VIP PRO. Bạn có thể tải các bài nhạc độc quyền từ chúng tôi.'
                            : 'Chưa đăng ký VIP PRO. Hãy nâng cấp để có thể tải nhạc độc quyền từ chúng tôi.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _GlassSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.flash_on_rounded,
                title: 'Truy cập nhanh',
                subtitle: 'Các lối tắt theo quyền tài khoản.',
              ),
              const SizedBox(height: 15),
              if (!isVipPro)
                const _QuickAccessTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Nâng cấp VIP PRO',
                  subtitle: 'Mở gói VIP PRO ở hệ thống web để nâng cấp.',
                  color: Color(0xffffd166),
                ),
              if (isAdmin) ...[
                const SizedBox(height: 10),
                const _QuickAccessTile(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Quản lý đơn hàng VIP PRO',
                  subtitle: 'Chức năng dành cho quản trị viên.',
                  color: Color(0xff34d399),
                ),
                const SizedBox(height: 10),
                const _QuickAccessTile(
                  icon: Icons.library_music_rounded,
                  title: 'Quản lý bài hát',
                  subtitle: 'Chức năng dành cho quản trị viên.',
                  color: Color(0xff22d3ee),
                ),
              ],
              if (isVipPro && !isAdmin)
                const _QuickAccessTile(
                  icon: Icons.check_circle_rounded,
                  title: 'Tài khoản đang hoạt động tốt',
                  subtitle: 'Không có thao tác bổ sung cần thực hiện.',
                  color: Color(0xff34d399),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarBox extends StatelessWidget {
  const _AvatarBox({
    required this.avatarUrl,
    required this.initial,
    required this.isVipPro,
    required this.size,
  });

  final String? avatarUrl;
  final String initial;
  final bool isVipPro;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl?.trim();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: avatar != null && avatar.isNotEmpty
                ? Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _InitialAvatar(initial: initial);
                    },
                  )
                : _InitialAvatar(initial: initial),
          ),
        ),
        if (isVipPro)
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xffffd166),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
      ],
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.10),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xffa78bfa).withOpacity(0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xffc4b5fd), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.34),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xffffd166).withOpacity(0.13),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: const Color(0xffffd166)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.50),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.76), size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff22d3ee).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xff22d3ee).withOpacity(0.22)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.72),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingProfile extends StatelessWidget {
  const _LoadingProfile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _LoginRequiredCard extends StatelessWidget {
  const _LoginRequiredCard({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.white.withOpacity(0.50),
            size: 44,
          ),
          const SizedBox(height: 14),
          const Text(
            'Bạn cần đăng nhập',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập để xem hồ sơ, trạng thái VIP PRO và cài đặt tài khoản.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.login_rounded),
            label: const Text(
              'Đăng nhập',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
