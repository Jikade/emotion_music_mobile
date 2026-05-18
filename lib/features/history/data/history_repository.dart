import '../../../core/network/api_client.dart';

class HistoryRepository {
  HistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> getHistory({int limit = 100}) async {
    final response = await _apiClient.dio.get(
      '/history',
      queryParameters: {'limit': limit},
    );

    if (response.data is List) {
      return response.data;
    }

    return [];
  }

  Future<void> addListenHistory({
    required int trackId,
    int listenMs = 0,
    Map<String, dynamic>? emotionState,
  }) async {
    await _apiClient.dio.post(
      '/history',
      data: {
        'track_id': trackId,
        'listen_ms': listenMs,
        'emotion_state_at_time': emotionState,
      },
    );
  }

  Future<void> clearHistory() async {
    await _apiClient.dio.delete('/history');
  }
}
