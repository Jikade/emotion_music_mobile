import 'package:go_router/go_router.dart';

import 'features/auth/presentation/auth_form_screen.dart';
import 'features/emotion/presentation/nhan_dien_cam_xuc_screen.dart';
import 'features/music/presentation/bang_dieu_khien_screen.dart';
import 'features/music/presentation/dang_phat_screen.dart';
import 'features/music/presentation/thu_vien_screen.dart';
import 'shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/bangDieuKhien',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/bangDieuKhien'),
    GoRoute(
      path: '/dangNhap',
      builder: (context, state) {
        return const AuthFormScreen(mode: AuthFormMode.login);
      },
    ),
    GoRoute(
      path: '/dangKy',
      builder: (context, state) {
        return const AuthFormScreen(mode: AuthFormMode.register);
      },
    ),
    GoRoute(
      path: '/bangDieuKhien',
      builder: (context, state) {
        return const AppShell(currentIndex: 0, child: BangDieuKhienScreen());
      },
    ),
    GoRoute(
      path: '/thuVien',
      builder: (context, state) {
        return const AppShell(currentIndex: 1, child: ThuVienScreen());
      },
    ),
    GoRoute(
      path: '/dangPhat',
      builder: (context, state) {
        return const AppShell(currentIndex: 2, child: DangPhatScreen());
      },
    ),
    GoRoute(
      path: '/nhanDienCamXuc',
      builder: (context, state) {
        return const AppShell(currentIndex: 3, child: NhanDienCamXucScreen());
      },
    ),
  ],
);
