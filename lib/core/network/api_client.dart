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
          try {
            final token = await _tokenStorage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}

          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;

  String mediaUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return '';

    final url = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : raw.startsWith('/media/')
        ? '${AppConfig.apiBaseUrl}$raw'
        : '${AppConfig.apiBaseUrl}/media/$raw';

    return Uri.encodeFull(url);
  }

  String imageUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return '';

    final url = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : raw.startsWith('/images/')
        ? '${AppConfig.apiBaseUrl}$raw'
        : '${AppConfig.apiBaseUrl}/images/$raw';

    return Uri.encodeFull(url);
  }
}
