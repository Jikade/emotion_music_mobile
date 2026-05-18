import '../../../core/network/api_client.dart';

class EmotionRepository {
  EmotionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> detectTextEmotion(String text) async {
    final response = await _apiClient.dio.post(
      '/api/emotion/detect',
      data: {'text': text},
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getRecommendations({
    required String emotion,
    int limit = 10,
  }) async {
    final response = await _apiClient.dio.post(
      '/recommend/',
      data: {
        'emotion_state': {
          'label': emotion,
          'emotion': emotion,
          'mood': emotion,
          'confidence': 0.8,
        },
        'limit': limit,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}
