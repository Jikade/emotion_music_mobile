import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../music/models/track.dart';

enum NlpEmotion { happy, sad, angry, relaxed }

extension NlpEmotionX on NlpEmotion {
  String get key {
    switch (this) {
      case NlpEmotion.happy:
        return 'happy';
      case NlpEmotion.sad:
        return 'sad';
      case NlpEmotion.angry:
        return 'angry';
      case NlpEmotion.relaxed:
        return 'relaxed';
    }
  }

  String get labelVi {
    switch (this) {
      case NlpEmotion.happy:
        return 'Vui vẻ';
      case NlpEmotion.sad:
        return 'Buồn';
      case NlpEmotion.angry:
        return 'Tức giận';
      case NlpEmotion.relaxed:
        return 'Thư giãn';
    }
  }

  String get description {
    switch (this) {
      case NlpEmotion.happy:
        return 'Tâm trạng tích cực, vui vẻ, nhiều năng lượng.';
      case NlpEmotion.sad:
        return 'Có sắc thái buồn, cô đơn hoặc mệt mỏi.';
      case NlpEmotion.angry:
        return 'Có cảm giác bực bội, căng thẳng hoặc khó chịu.';
      case NlpEmotion.relaxed:
        return 'Cần sự bình yên, thư giãn hoặc chữa lành.';
    }
  }
}

class RecommendedTrack {
  final Track track;
  final double recommendationScore;
  final String moodText;

  const RecommendedTrack({
    required this.track,
    required this.recommendationScore,
    required this.moodText,
  });

  factory RecommendedTrack.fromJson(
    Map<String, dynamic> json, {
    required int index,
    required NlpEmotion fallbackEmotion,
  }) {
    final track = Track.fromJson(json);

    final rawScore =
        json['recommendation_score'] ??
        json['score'] ??
        json['confidence'] ??
        (92 - index * 4);

    final score = _toDouble(rawScore).clamp(0, 100).toDouble();

    final moodText = json['mood']?.toString().trim().isNotEmpty == true
        ? json['mood'].toString()
        : json['emotion']?.toString().trim().isNotEmpty == true
        ? json['emotion'].toString()
        : fallbackEmotion.labelVi;

    return RecommendedTrack(
      track: track,
      recommendationScore: score,
      moodText: moodText,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class EmotionDetectResult {
  final NlpEmotion emotion;
  final double confidence;
  final int confidencePercent;
  final Map<NlpEmotion, double> probabilities;
  final List<RecommendedTrack> recommendedSongs;
  final RecommendedTrack? autoPlaySong;
  final String? rationale;

  const EmotionDetectResult({
    required this.emotion,
    required this.confidence,
    required this.confidencePercent,
    required this.probabilities,
    required this.recommendedSongs,
    required this.autoPlaySong,
    required this.rationale,
  });
}

class _BackendEmotionResult {
  final NlpEmotion emotion;
  final double confidence;
  final Map<NlpEmotion, double>? probabilities;
  final double? valence;
  final double? arousal;

  const _BackendEmotionResult({
    required this.emotion,
    required this.confidence,
    this.probabilities,
    this.valence,
    this.arousal,
  });
}

class _LocalEmotionResult {
  final NlpEmotion emotion;
  final double confidence;
  final Map<NlpEmotion, double> probabilities;
  final List<String> matchedKeywords;

  const _LocalEmotionResult({
    required this.emotion,
    required this.confidence,
    required this.probabilities,
    required this.matchedKeywords,
  });
}

class EmotionRepository {
  EmotionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<EmotionDetectResult> detectTextEmotion(
    String text, {
    int limit = 9,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Vui lòng nhập nội dung cảm xúc trước khi phân tích.');
    }

    final local = _detectLocalEmotion(cleanText);
    final backend = await _detectBackendEmotion(cleanText);

    final selectedEmotion = backend?.emotion ?? local.emotion;
    final confidence = backend?.confidence ?? local.confidence;

    final probabilities = _normalizeProbabilities(
      backend?.probabilities ?? local.probabilities,
      selectedEmotion,
      confidence,
    );

    final recommended = await _getBackendRecommendations(
      emotion: selectedEmotion,
      confidence: confidence,
      limit: limit,
      valence: backend?.valence,
      arousal: backend?.arousal,
    );

    final fallbackRecommended = recommended.isEmpty
        ? await _getTracksByMood(emotion: selectedEmotion, limit: limit)
        : recommended;

    final sorted = _rankTracksByMood(
      fallbackRecommended,
      selectedEmotion,
    ).take(limit).toList();

    final rationale = _buildRationale(
      text: cleanText,
      emotion: selectedEmotion,
      probabilities: probabilities,
      matchedKeywords: local.matchedKeywords,
      hasBackend: backend != null,
    );

    return EmotionDetectResult(
      emotion: selectedEmotion,
      confidence: confidence.clamp(0, 1).toDouble(),
      confidencePercent: (confidence.clamp(0, 1) * 100).round(),
      probabilities: probabilities,
      recommendedSongs: sorted,
      autoPlaySong: sorted.isNotEmpty ? sorted.first : null,
      rationale: rationale,
    );
  }

  Future<_BackendEmotionResult?> _detectBackendEmotion(String text) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/emotion/detect',
        data: {'text': text},
      );

      final data = response.data;

      if (data is! Map) return null;

      final map = Map<String, dynamic>.from(data);

      final rawEmotion =
          map['emotion'] ??
          map['label'] ??
          map['mood'] ??
          map['prediction'] ??
          map['dominant_emotion'];

      final emotion = _emotionFromString(rawEmotion?.toString());

      final rawConfidence =
          map['confidence'] ?? map['score'] ?? map['probability'] ?? 0.75;

      final confidence = _toProbability(rawConfidence);

      return _BackendEmotionResult(
        emotion: emotion,
        confidence: confidence,
        probabilities: _readProbabilities(
          map['probabilities'] ?? map['scores'],
        ),
        valence: _toNullableDouble(map['valence']),
        arousal: _toNullableDouble(map['arousal']),
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<RecommendedTrack>> _getBackendRecommendations({
    required NlpEmotion emotion,
    required double confidence,
    required int limit,
    double? valence,
    double? arousal,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/recommend/',
        data: {
          'user_id': 0,
          'emotion_state': {
            'label': emotion.key,
            'emotion': emotion.key,
            'mood': emotion.key,
            'confidence': confidence,
            'valence': valence ?? 0,
            'arousal': arousal ?? 0,
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

      if (rawTracks is! List) return [];

      return rawTracks
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map(
            (entry) => RecommendedTrack.fromJson(
              Map<String, dynamic>.from(entry.value),
              index: entry.key,
              fallbackEmotion: emotion,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RecommendedTrack>> _getTracksByMood({
    required NlpEmotion emotion,
    required int limit,
  }) async {
    try {
      final response = await _apiClient.dio.get('/tracks/');
      final data = response.data;

      if (data is! List) return [];

      return data
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map(
            (entry) => RecommendedTrack.fromJson(
              Map<String, dynamic>.from(entry.value),
              index: entry.key,
              fallbackEmotion: emotion,
            ),
          )
          .toList()
          .take(limit)
          .toList();
    } catch (_) {
      return [];
    }
  }

  _LocalEmotionResult _detectLocalEmotion(String text) {
    final normalized = _normalizeVietnameseText(text);

    final scores = <NlpEmotion, double>{
      NlpEmotion.happy: 0,
      NlpEmotion.sad: 0,
      NlpEmotion.angry: 0,
      NlpEmotion.relaxed: 0,
    };

    final matched = <String>[];

    void score(NlpEmotion emotion, Map<String, double> keywords) {
      for (final entry in keywords.entries) {
        if (normalized.contains(entry.key)) {
          scores[emotion] = (scores[emotion] ?? 0) + entry.value;
          matched.add(entry.key);
        }
      }
    }

    score(NlpEmotion.happy, {
      'vui': 2.2,
      'vui ve': 2.4,
      'hanh phuc': 2.7,
      'tuyet': 1.8,
      'tich cuc': 2.0,
      'yeu doi': 2.2,
      'phan khoi': 2.0,
      'hao hung': 1.8,
      'happy': 2.2,
      'joy': 2.2,
      'great': 1.8,
    });

    score(NlpEmotion.sad, {
      'buon': 2.4,
      'co don': 2.8,
      'met moi': 2.2,
      'chan nan': 2.5,
      'that vong': 2.5,
      'khoc': 2.4,
      'dau long': 2.6,
      'nho': 1.2,
      'sad': 2.2,
      'lonely': 2.7,
      'tired': 1.8,
    });

    score(NlpEmotion.angry, {
      'tuc': 2.4,
      'gian': 2.5,
      'buc': 2.2,
      'kho chiu': 2.3,
      'cang thang': 2.0,
      'stress': 2.0,
      'ap luc': 1.8,
      'phat dien': 2.7,
      'angry': 2.5,
      'mad': 2.0,
    });

    score(NlpEmotion.relaxed, {
      'thu gian': 2.6,
      'binh yen': 2.4,
      'nhe nhang': 2.2,
      'chill': 2.1,
      'ngu': 1.6,
      'yen tinh': 2.0,
      'chua lanh': 2.2,
      'calm': 2.2,
      'relax': 2.4,
      'peace': 2.0,
    });

    final contrastTail = _getContrastTail(normalized);

    if (contrastTail != null) {
      for (final emotion in NlpEmotion.values) {
        final tailLocal = _detectTailScore(contrastTail, emotion);
        scores[emotion] = (scores[emotion] ?? 0) + tailLocal * 0.35;
      }
    }

    final probabilities = _scoresToProbabilities(scores);
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.first;

    return _LocalEmotionResult(
      emotion: top.key,
      confidence: top.value,
      probabilities: probabilities,
      matchedKeywords: matched,
    );
  }

  double _detectTailScore(String text, NlpEmotion emotion) {
    final local = _detectLocalEmotionWithoutContrast(text);

    return local[emotion] ?? 0;
  }

  Map<NlpEmotion, double> _detectLocalEmotionWithoutContrast(String text) {
    final scores = <NlpEmotion, double>{
      NlpEmotion.happy: 0,
      NlpEmotion.sad: 0,
      NlpEmotion.angry: 0,
      NlpEmotion.relaxed: 0,
    };

    void add(NlpEmotion emotion, List<String> words) {
      for (final word in words) {
        if (text.contains(word)) {
          scores[emotion] = (scores[emotion] ?? 0) + 1;
        }
      }
    }

    add(NlpEmotion.happy, ['vui', 'hanh phuc', 'tuyet', 'happy']);
    add(NlpEmotion.sad, ['buon', 'co don', 'met moi', 'sad', 'lonely']);
    add(NlpEmotion.angry, ['tuc', 'gian', 'buc', 'stress', 'angry']);
    add(NlpEmotion.relaxed, ['thu gian', 'binh yen', 'nhe nhang', 'chill']);

    return scores;
  }

  List<RecommendedTrack> _rankTracksByMood(
    List<RecommendedTrack> tracks,
    NlpEmotion emotion,
  ) {
    final result = [...tracks];

    result.sort((a, b) {
      final aMood =
          _isMoodMatch(a.track.moodText, emotion) ||
          _isMoodMatch(a.moodText, emotion);
      final bMood =
          _isMoodMatch(b.track.moodText, emotion) ||
          _isMoodMatch(b.moodText, emotion);

      if (aMood != bMood) {
        return aMood ? -1 : 1;
      }

      return b.recommendationScore.compareTo(a.recommendationScore);
    });

    return result;
  }

  bool _isMoodMatch(String value, NlpEmotion emotion) {
    final normalized = _normalizeVietnameseText(value);

    switch (emotion) {
      case NlpEmotion.happy:
        return normalized.contains('happy') ||
            normalized.contains('vui') ||
            normalized.contains('joy') ||
            normalized.contains('positive');
      case NlpEmotion.sad:
        return normalized.contains('sad') ||
            normalized.contains('buon') ||
            normalized.contains('co don') ||
            normalized.contains('lonely');
      case NlpEmotion.angry:
        return normalized.contains('angry') ||
            normalized.contains('gian') ||
            normalized.contains('tuc') ||
            normalized.contains('stress');
      case NlpEmotion.relaxed:
        return normalized.contains('relax') ||
            normalized.contains('relaxed') ||
            normalized.contains('calm') ||
            normalized.contains('thu gian') ||
            normalized.contains('chill') ||
            normalized.contains('binh yen');
    }
  }

  Map<NlpEmotion, double> _scoresToProbabilities(
    Map<NlpEmotion, double> scores,
  ) {
    final damped = <NlpEmotion, double>{};

    for (final emotion in NlpEmotion.values) {
      damped[emotion] = math.sqrt(math.max(0, scores[emotion] ?? 0));
    }

    final rawTotal = damped.values.fold<double>(0, (sum, value) => sum + value);

    if (rawTotal <= 0) {
      return {
        NlpEmotion.happy: 0.25,
        NlpEmotion.sad: 0.25,
        NlpEmotion.angry: 0.25,
        NlpEmotion.relaxed: 0.25,
      };
    }

    const smoothing = 0.08;
    final total = damped.values.fold<double>(
      0,
      (sum, value) => sum + value + smoothing,
    );

    return {
      for (final emotion in NlpEmotion.values)
        emotion: ((damped[emotion] ?? 0) + smoothing) / total,
    };
  }

  Map<NlpEmotion, double> _normalizeProbabilities(
    Map<NlpEmotion, double> source,
    NlpEmotion emotion,
    double confidence,
  ) {
    if (source.isEmpty) {
      final safeConfidence = confidence.clamp(0.25, 0.98).toDouble();
      final rest = (1 - safeConfidence) / 3;

      return {
        NlpEmotion.happy: emotion == NlpEmotion.happy ? safeConfidence : rest,
        NlpEmotion.sad: emotion == NlpEmotion.sad ? safeConfidence : rest,
        NlpEmotion.angry: emotion == NlpEmotion.angry ? safeConfidence : rest,
        NlpEmotion.relaxed: emotion == NlpEmotion.relaxed
            ? safeConfidence
            : rest,
      };
    }

    final total = source.values.fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) {
      return {
        NlpEmotion.happy: 0.25,
        NlpEmotion.sad: 0.25,
        NlpEmotion.angry: 0.25,
        NlpEmotion.relaxed: 0.25,
      };
    }

    return {
      for (final item in source.entries)
        item.key: (item.value / total).clamp(0, 1).toDouble(),
    };
  }

  Map<NlpEmotion, double>? _readProbabilities(dynamic value) {
    if (value is! Map) return null;

    final result = <NlpEmotion, double>{};

    for (final emotion in NlpEmotion.values) {
      final raw =
          value[emotion.key] ??
          value[emotion.labelVi] ??
          value[_normalizeVietnameseText(emotion.labelVi)];

      if (raw != null) {
        result[emotion] = _toProbability(raw);
      }
    }

    return result.isEmpty ? null : result;
  }

  NlpEmotion _emotionFromString(String? value) {
    final normalized = _normalizeVietnameseText(value ?? '');

    if (normalized.contains('happy') ||
        normalized.contains('joy') ||
        normalized.contains('vui') ||
        normalized.contains('positive')) {
      return NlpEmotion.happy;
    }

    if (normalized.contains('sad') ||
        normalized.contains('buon') ||
        normalized.contains('lonely') ||
        normalized.contains('co don')) {
      return NlpEmotion.sad;
    }

    if (normalized.contains('angry') ||
        normalized.contains('anger') ||
        normalized.contains('gian') ||
        normalized.contains('tuc') ||
        normalized.contains('stress')) {
      return NlpEmotion.angry;
    }

    return NlpEmotion.relaxed;
  }

  String _buildRationale({
    required String text,
    required NlpEmotion emotion,
    required Map<NlpEmotion, double> probabilities,
    required List<String> matchedKeywords,
    required bool hasBackend,
  }) {
    final rows = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strongRows = rows
        .where((entry) => entry.value >= 0.12)
        .map((entry) => '${entry.key.labelVi}: ${(entry.value * 100).round()}%')
        .toList();

    final source = hasBackend ? 'Backend AI + bộ lọc local' : 'Bộ lọc local';

    if (strongRows.length >= 2) {
      return '$source phát hiện câu có nhiều sắc thái cảm xúc: ${strongRows.join(", ")}.';
    }

    if (matchedKeywords.isNotEmpty) {
      return '$source nhận diện cảm xúc chính là ${emotion.labelVi} dựa trên các tín hiệu: ${matchedKeywords.take(6).join(", ")}.';
    }

    return '$source nhận diện cảm xúc chính là ${emotion.labelVi}.';
  }

  double _toProbability(dynamic value) {
    final raw = _toNullableDouble(value) ?? 0.75;

    if (raw > 1) {
      return (raw / 100).clamp(0, 1).toDouble();
    }

    return raw.clamp(0, 1).toDouble();
  }

  double? _toNullableDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '');
  }

  String? _getContrastTail(String text) {
    final separators = [
      ' nhung ',
      ' tuy nhien ',
      ' ma ',
      ' con ',
      ' nhưng ',
      ' tuy nhiên ',
    ];

    for (final separator in separators) {
      final index = text.lastIndexOf(separator);

      if (index >= 0 && index + separator.length < text.length) {
        return text.substring(index + separator.length).trim();
      }
    }

    return null;
  }

  String _normalizeVietnameseText(String value) {
    var text = value.toLowerCase().trim();

    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    return text.replaceAll(RegExp(r'\s+'), ' ');
  }
}
