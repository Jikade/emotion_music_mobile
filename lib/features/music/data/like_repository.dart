import '../../../core/network/api_client.dart';

class LikeRepository {
  LikeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Set<int>> getLikedTrackIds() async {
    final response = await _apiClient.dio.get('/likes');
    final data = response.data;

    if (data is Map && data['track_ids'] is List) {
      return (data['track_ids'] as List)
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toSet();
    }

    return <int>{};
  }

  Future<void> likeTrack(int trackId) async {
    await _apiClient.dio.post('/likes/$trackId');
  }

  Future<void> unlikeTrack(int trackId) async {
    await _apiClient.dio.delete('/likes/$trackId');
  }
}
