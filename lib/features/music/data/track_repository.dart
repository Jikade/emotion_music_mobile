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

  String audioUrl(Track track) => _apiClient.mediaUrl(track.audioUrl);

  String coverUrl(Track track) => _apiClient.imageUrl(track.coverImage);
}
