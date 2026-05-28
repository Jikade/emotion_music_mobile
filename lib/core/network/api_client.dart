import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: _cleanBaseUrl(AppConfig.apiBaseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',

          // Cần cho request API qua ngrok.
          // Lưu ý: ảnh/audio không phải lúc nào cũng đi qua Dio,
          // nên vẫn cần MEDIA_BASE_URL riêng.
          'ngrok-skip-browser-warning': 'true',
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

    final path = _extractAssetPath(raw, allowedPrefix: '/media/');

    if (path.isEmpty) return '';

    return Uri.encodeFull('${_cleanBaseUrl(AppConfig.mediaBaseUrl)}$path');
  }

  String imageUrl(String? value) {
    final raw = value?.trim();

    if (raw == null || raw.isEmpty) return '';

    final path = _extractAssetPath(raw, allowedPrefix: '/images/');

    if (path.isEmpty) return '';

    return Uri.encodeFull('${_cleanBaseUrl(AppConfig.mediaBaseUrl)}$path');
  }

  String _extractAssetPath(String raw, {required String allowedPrefix}) {
    final value = raw.trim();

    if (value.isEmpty) return '';

    if (value.startsWith(allowedPrefix)) {
      return value;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      final path = uri?.path ?? '';

      if (path.startsWith(allowedPrefix)) {
        return path;
      }

      return '';
    }

    final cleaned = value.startsWith('/') ? value.substring(1) : value;

    if (allowedPrefix == '/media/') {
      return '/media/$cleaned';
    }

    if (allowedPrefix == '/images/') {
      return '/images/$cleaned';
    }

    return '';
  }

  static String _cleanBaseUrl(String value) {
    final raw = value.trim();

    if (raw.endsWith('/')) {
      return raw.substring(0, raw.length - 1);
    }

    return raw;
  }
}
