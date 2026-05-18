import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../music/data/track_repository.dart';
import '../../music/models/track.dart';

class PersonalRecommendationResult {
  final List<Track> tracks;
  final String? rationale;

  const PersonalRecommendationResult({
    required this.tracks,
    required this.rationale,
  });
}

class RecommendationRepository {
  RecommendationRepository(this._apiClient, this._trackRepository);

  final ApiClient _apiClient;
  final TrackRepository _trackRepository;

  Future<PersonalRecommendationResult> getPersonalRecommendations({
    required int limit,
    required String emotion,
  }) async {
    try {
      final normalizedEmotion = _normalizeEmotion(emotion);

      final response = await _apiClient.dio.post(
        '/recommend/',
        data: {
          'user_id': 0,
          'emotion_state': {
            'label': normalizedEmotion,
            'emotion': normalizedEmotion,
            'mood': normalizedEmotion,
            'confidence': 0.82,
            'valence': 0,
            'arousal': 0,
            'source': 'goiY',
          },
          'limit': limit,
        },
      );

      final data = response.data;

      final rawTracks = data is Map
          ? data['tracks']
          : data is List
          ? data
          : null;

      final tracks = rawTracks is List
          ? rawTracks
                .whereType<Map>()
                .map((item) => Track.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : <Track>[];

      final rationale = data is Map ? data['rationale']?.toString() : null;

      return PersonalRecommendationResult(tracks: tracks, rationale: rationale);
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    } catch (error) {
      throw Exception('Không tải được gợi ý cá nhân hoá: $error');
    }
  }

  Future<List<Track>> getFallbackTracks() async {
    return _trackRepository.getTracks();
  }

  String _normalizeEmotion(String value) {
    final raw = value.trim().toLowerCase();

    if (raw.contains('happy') || raw.contains('vui')) {
      return 'happy';
    }

    if (raw.contains('sad') ||
        raw.contains('buồn') ||
        raw.contains('buon') ||
        raw.contains('lonely')) {
      return 'sad';
    }

    if (raw.contains('angry') ||
        raw.contains('giận') ||
        raw.contains('gian') ||
        raw.contains('stress')) {
      return 'angry';
    }

    if (raw.contains('energetic') || raw.contains('năng lượng')) {
      return 'energetic';
    }

    if (raw.contains('romantic') || raw.contains('lãng mạn')) {
      return 'romantic';
    }

    if (raw.contains('nostalgic') || raw.contains('hoài niệm')) {
      return 'nostalgic';
    }

    return 'relaxed';
  }

  String _readableError(DioException error) {
    if (error.response?.statusCode == 401 ||
        error.response?.statusCode == 403) {
      return 'Bạn cần đăng nhập để xem gợi ý cá nhân hoá theo tài khoản.';
    }

    if (error.response != null) {
      return 'Backend trả lỗi ${error.response?.statusCode}: ${error.response?.data}';
    }

    return 'Không kết nối được backend API: ${error.message}';
  }
}
