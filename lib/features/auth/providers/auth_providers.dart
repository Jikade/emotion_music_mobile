import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/music/providers/music_providers.dart';
import '../data/auth_repository.dart';
import '../data/google_auth_service.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  final AuthUser? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isLoggedIn => token != null && token!.isNotEmpty && user != null;

  AuthState copyWith({
    AuthUser? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      token: clearToken ? null : token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    Future.microtask(_restoreSession);

    return const AuthState(isLoading: true);
  }

  Future<void> _restoreSession() async {
    final token = await _repository.getStoredToken();
    final storedUser = await _repository.getStoredUser();

    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }

    if (storedUser != null) {
      state = AuthState(token: token, user: storedUser);
    }

    try {
      final user = await _repository.me();

      state = AuthState(token: token, user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );

      state = AuthState(token: response.accessToken, user: response.user);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
      );

      state = AuthState(token: response.accessToken, user: response.user);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final googleAuthService = ref.read(googleAuthServiceProvider);
      final googleCredential = await googleAuthService.getGoogleCredential();

      final response = await _repository.loginWithGoogle(
        credential: googleCredential.idToken,
        accessToken: googleCredential.accessToken,
      );

      state = AuthState(token: response.accessToken, user: response.user);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(googleAuthServiceProvider).signOut();
    } catch (_) {}

    await _repository.logout();

    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
