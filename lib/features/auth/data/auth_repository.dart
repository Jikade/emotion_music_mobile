import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final session = AuthSession.fromJson(response.data);
    await _tokenStorage.saveToken(session.accessToken);
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    final session = AuthSession.fromJson(response.data);
    await _tokenStorage.saveToken(session.accessToken);
    return session;
  }

  Future<AuthUser> me() async {
    final response = await _apiClient.dio.get('/auth/me');
    return AuthUser.fromJson(response.data);
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } finally {
      await _tokenStorage.clear();
    }
  }
}
