import '../../../core/network/api_client.dart';
import '../models/track.dart';

class TrackRepository {
  TrackRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Track>> getTracks() async {
    final response = await _apiClient.dio.get('/tracks/');
    final data = response.data;

    if (data is! List) return [];

    return data.whereType<Map<String, dynamic>>().map(Track.fromJson).toList();
  }

  String getAudioUrl(Track track) {
    return _apiClient.mediaUrl(track.audioUrl);
  }

  String getCoverUrl(Track track) {
    return _apiClient.imageUrl(track.coverImage);
  }
}
