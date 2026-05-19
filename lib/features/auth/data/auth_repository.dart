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
    } catch (error) {
      throw Exception('Không thể đăng nhập: $error');
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
    } catch (error) {
      throw Exception('Không thể đăng ký: $error');
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
    } catch (error) {
      throw Exception('Không thể đăng nhập Google: $error');
    }
  }

  Future<AuthUser> me() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      final user = _parseUser(response.data);

      await _tokenStorage.saveUser(user);

      return user;
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    } catch (error) {
      throw Exception('Không thể tải thông tin tài khoản: $error');
    }
  }

  Future<AuthUser> getCurrentUser() async {
    return me();
  }

  Future<void> saveUser(AuthUser user) async {
    await _tokenStorage.saveUser(user);
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // JWT stateless: nếu backend logout lỗi thì app vẫn xoá token local.
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

  AuthUser _parseUser(dynamic data) {
    if (data is Map<String, dynamic>) {
      return AuthUser.fromJson(data);
    }

    if (data is Map) {
      return AuthUser.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Backend trả dữ liệu user không hợp lệ.');
  }

  String _readableError(DioException error) {
    final data = error.response?.data;

    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];

      if (detail is List) {
        return detail.map((item) => item.toString()).join('\n');
      }

      return detail.toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Không kết nối được backend. Kiểm tra API_BASE_URL và Docker backend.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Kết nối backend quá lâu. Hãy kiểm tra backend FastAPI có đang chạy không.';
    }

    return error.message ?? 'Có lỗi xảy ra khi gọi API xác thực.';
  }
}
