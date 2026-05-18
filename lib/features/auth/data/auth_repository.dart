import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<TokenResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      final tokenResponse = TokenResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      await _saveSession(tokenResponse);

      return tokenResponse;
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    }
  }

  Future<TokenResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final tokenResponse = TokenResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      await _saveSession(tokenResponse);

      return tokenResponse;
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    }
  }

  Future<TokenResponse> loginWithGoogle({
    String? credential,
    String? accessToken,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/google',
        data: {
          if (credential != null && credential.isNotEmpty)
            'credential': credential,
          if (accessToken != null && accessToken.isNotEmpty)
            'access_token': accessToken,
        },
      );

      final tokenResponse = TokenResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );

      await _saveSession(tokenResponse);

      return tokenResponse;
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    }
  }

  Future<AuthUser> me() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');

      final user = AuthUser.fromJson(Map<String, dynamic>.from(response.data));

      await _tokenStorage.saveUser(user);

      return user;
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // JWT stateless nên chỉ cần xóa token phía app.
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  Future<String?> getStoredToken() {
    return _tokenStorage.getToken();
  }

  Future<AuthUser?> getStoredUser() {
    return _tokenStorage.getUser();
  }

  Future<void> _saveSession(TokenResponse tokenResponse) async {
    await _tokenStorage.saveToken(tokenResponse.accessToken);
    await _tokenStorage.saveUser(tokenResponse.user);
  }

  String _readableError(DioException error) {
    final data = error.response?.data;

    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Không kết nối được backend. Kiểm tra API_BASE_URL và Docker backend.';
    }

    return error.message ?? 'Có lỗi xảy ra khi gọi API xác thực.';
  }
}
