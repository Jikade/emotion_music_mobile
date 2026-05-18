import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/music/presentation/bang_dieu_khien_screen.dart';
import 'features/music/presentation/dang_phat_screen.dart';
import 'features/music/presentation/thu_vien_screen.dart';
import 'shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/bangDieuKhien',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/bangDieuKhien'),
    GoRoute(
      path: '/bangDieuKhien',
      pageBuilder: (context, state) {
        return const NoTransitionPage(
          child: AppShell(currentIndex: 0, child: BangDieuKhienScreen()),
        );
      },
    ),
    GoRoute(
      path: '/thuVien',
      pageBuilder: (context, state) {
        return const NoTransitionPage(
          child: AppShell(currentIndex: 1, child: ThuVienScreen()),
        );
      },
    ),
    GoRoute(
      path: '/dangPhat',
      pageBuilder: (context, state) {
        return const NoTransitionPage(
          child: AppShell(currentIndex: 2, child: DangPhatScreen()),
        );
      },
    ),
  ],
);
