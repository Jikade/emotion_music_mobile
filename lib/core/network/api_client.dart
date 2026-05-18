import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;

  String mediaUrl(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/media/')) {
      return '${AppConfig.apiBaseUrl}$value';
    }
    return '${AppConfig.apiBaseUrl}/media/$value';
  }

  String imageUrl(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/images/')) {
      return '${AppConfig.apiBaseUrl}$value';
    }
    return '${AppConfig.apiBaseUrl}/images/$value';
  }
}
