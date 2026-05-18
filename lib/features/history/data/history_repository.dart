import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../music/models/track.dart';

class ListeningHistoryItem {
  final int id;
  final int trackId;
  final int listenMs;
  final DateTime createdAt;
  final Track track;

  const ListeningHistoryItem({
    required this.id,
    required this.trackId,
    required this.listenMs,
    required this.createdAt,
    required this.track,
  });

  factory ListeningHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawTrackId =
        json['track_id'] ?? json['trackId'] ?? json['track']?['id'];
    final trackId = _toInt(rawTrackId);

    final rawTrack = json['track'];

    final track = rawTrack is Map
        ? Track.fromJson(Map<String, dynamic>.from(rawTrack))
        : Track.fromJson({
            'id': trackId,
            'title': 'Không rõ tên bài hát',
            'artist': 'Unknown Artist',
            'duration': 0,
          });

    return ListeningHistoryItem(
      id: _toInt(json['id']),
      trackId: trackId == 0 ? track.id : trackId,
      listenMs: _toInt(
        json['listen_ms'] ?? json['listenMs'] ?? json['played_ms'],
      ),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
      track: track,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    final raw = value?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return DateTime.now();
    }

    return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
  }
}

class HistoryRepository {
  HistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ListeningHistoryItem>> getListeningHistory({
    int limit = 100,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/history',
        queryParameters: {'limit': limit},
      );

      final data = response.data;

      final rawItems = data is List
          ? data
          : data is Map && data['items'] is List
          ? data['items'] as List
          : data is Map && data['history'] is List
          ? data['history'] as List
          : const [];

      final items = rawItems
          .whereType<Map>()
          .map(
            (item) =>
                ListeningHistoryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return items;
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    } catch (error) {
      throw Exception('Không tải được lịch sử nghe: $error');
    }
  }

  Future<void> clearListeningHistory() async {
    try {
      await _apiClient.dio.delete('/history');
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    } catch (error) {
      throw Exception('Không xoá được lịch sử nghe: $error');
    }
  }

  Future<void> saveListeningHistory({
    required int trackId,
    required int listenMs,
  }) async {
    try {
      await _apiClient.dio.post(
        '/history',
        data: {'track_id': trackId, 'listen_ms': listenMs},
      );
    } catch (_) {
      // Không chặn player nếu lưu lịch sử thất bại.
    }
  }

  String _readableError(DioException error) {
    if (error.response?.statusCode == 401 ||
        error.response?.statusCode == 403) {
      return 'Bạn cần đăng nhập để xem lịch sử nghe của tài khoản này.';
    }

    if (error.response != null) {
      return 'Backend trả lỗi ${error.response?.statusCode}: ${error.response?.data}';
    }

    return 'Không kết nối được backend API: ${error.message}';
  }
}
