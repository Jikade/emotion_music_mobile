import 'dart:math';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../music/models/track.dart';

typedef EmotionProbabilities = Map<String, double>;

class NlpEmotion {
  static const happy = 'happy';
  static const sad = 'sad';
  static const angry = 'angry';
  static const relaxed = 'relaxed';

  static const values = [happy, sad, angry, relaxed];
}

class RecommendedTrack {
  final Track track;
  final double recommendationScore;
  final String? matchedMood;

  const RecommendedTrack({
    required this.track,
    required this.recommendationScore,
    this.matchedMood,
  });
}

class EmotionDetectResult {
  final String emotion;
  final double confidence;
  final int confidencePercent;
  final EmotionProbabilities probabilities;
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

class LocalEmotionResult {
  final String? emotion;
  final double confidence;
  final EmotionProbabilities scores;
  final EmotionProbabilities probabilities;
  final Map<String, List<String>> matchedKeywords;

  const LocalEmotionResult({
    required this.emotion,
    required this.confidence,
    required this.scores,
    required this.probabilities,
    required this.matchedKeywords,
  });
}

class KeywordRule {
  final String keyword;
  final double weight;

  const KeywordRule(this.keyword, this.weight);
}

class EmotionRepository {
  EmotionRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  static const labels = {
    NlpEmotion.happy: {'vi': 'Vui vẻ', 'en': 'Happy'},
    NlpEmotion.sad: {'vi': 'Buồn / cô đơn', 'en': 'Sad'},
    NlpEmotion.angry: {'vi': 'Tức giận', 'en': 'Angry'},
    NlpEmotion.relaxed: {'vi': 'Thư giãn', 'en': 'Relaxed'},
  };

  static const moodAliases = {
    NlpEmotion.happy: [
      'happy',
      'joy',
      'enjoyment',
      'positive',
      'vui',
      'vui vẻ',
      'hạnh phúc',
      'yêu đời',
      'phấn khích',
      'tích cực',
      'green',
      'energetic',
    ],
    NlpEmotion.sad: [
      'sad',
      'sadness',
      'negative',
      'lonely',
      'buon',
      'buồn',
      'buồn chán',
      'chán',
      'cô đơn',
      'đau lòng',
      'thất vọng',
      'khóc',
      'blue',
      'nostalgic',
    ],
    NlpEmotion.angry: [
      'angry',
      'anger',
      'disgust',
      'fear',
      'stressed',
      'stress',
      'tức',
      'giận',
      'bực',
      'khó chịu',
      'cáu',
      'căng thẳng',
      'tức giận',
      'red',
    ],
    NlpEmotion.relaxed: [
      'relaxed',
      'relax',
      'calm',
      'chill',
      'healing',
      'sleep',
      'thư giãn',
      'bình yên',
      'nhẹ nhàng',
      'êm dịu',
      'an yên',
      'cyan',
    ],
  };

  static const localKeywords = {
    NlpEmotion.happy: [
      KeywordRule('vui vẻ', 2.2),
      KeywordRule('hạnh phúc', 2.4),
      KeywordRule('tuyệt vời', 2.0),
      KeywordRule('yêu đời', 1.8),
      KeywordRule('phấn khích', 1.8),
      KeywordRule('hào hứng', 1.8),
      KeywordRule('tích cực', 1.5),
      KeywordRule('vui', 1.2),
      KeywordRule('tuyệt', 1.2),
      KeywordRule('cười', 1.1),
      KeywordRule('happy', 1.5),
      KeywordRule('joy', 1.5),
      KeywordRule('joyful', 1.6),
      KeywordRule('excited', 1.5),
      KeywordRule('positive', 1.2),
    ],
    NlpEmotion.sad: [
      KeywordRule('buồn chán', 2.4),
      KeywordRule('cô đơn', 2.3),
      KeywordRule('đau lòng', 2.0),
      KeywordRule('thất vọng', 1.8),
      KeywordRule('mệt mỏi', 1.4),
      KeywordRule('chán nản', 1.8),
      KeywordRule('tủi thân', 1.8),
      KeywordRule('trống rỗng', 1.7),
      KeywordRule('buồn', 1.4),
      KeywordRule('chán', 1.2),
      KeywordRule('khóc', 1.4),
      KeywordRule('lụy', 1.2),
      KeywordRule('nhớ', 0.9),
      KeywordRule('sad', 1.5),
      KeywordRule('lonely', 1.8),
      KeywordRule('cry', 1.2),
      KeywordRule('tired', 1.1),
      KeywordRule('depressed', 1.8),
    ],
    NlpEmotion.angry: [
      KeywordRule('tức giận', 2.4),
      KeywordRule('bực mình', 2.0),
      KeywordRule('khó chịu', 1.8),
      KeywordRule('điên tiết', 2.2),
      KeywordRule('phẫn nộ', 2.2),
      KeywordRule('căng thẳng', 1.7),
      KeywordRule('tức', 1.2),
      KeywordRule('giận', 1.4),
      KeywordRule('bực', 1.2),
      KeywordRule('cáu', 1.1),
      KeywordRule('angry', 1.5),
      KeywordRule('mad', 1.3),
      KeywordRule('rage', 1.8),
      KeywordRule('annoyed', 1.4),
      KeywordRule('stress', 1.2),
      KeywordRule('stressed', 1.3),
    ],
    NlpEmotion.relaxed: [
      KeywordRule('thư giãn', 2.2),
      KeywordRule('bình yên', 2.0),
      KeywordRule('nhẹ nhàng', 1.8),
      KeywordRule('êm dịu', 1.7),
      KeywordRule('nghỉ ngơi', 1.5),
      KeywordRule('an yên', 1.8),
      KeywordRule('tĩnh lặng', 1.5),
      KeywordRule('chill', 1.4),
      KeywordRule('calm', 1.5),
      KeywordRule('relax', 1.4),
      KeywordRule('relaxed', 1.5),
      KeywordRule('peaceful', 1.5),
      KeywordRule('sleep', 1.2),
      KeywordRule('healing', 1.2),
    ],
  };

  static const contrastMarkers = [
    'nhưng',
    'nhung',
    'tuy nhiên',
    'tuy nhien',
    'dù vậy',
    'du vay',
    'song',
    'but',
    'however',
  ];

  Future<EmotionDetectResult> detectTextEmotion(
    String text, {
    int limit = 10,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Vui lòng nhập nội dung trước khi phân tích.');
    }

    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập trước khi nhận diện cảm xúc.');
    }

    final localEmotion = _detectLocalEmotion(cleanText);

    final backendEmotionResponse = await _detectBackendEmotion(cleanText);
    final lyricsMood = await _analyzeLyricsMood(cleanText);

    final backendEmotion = _normalizeNlpEmotion(
      backendEmotionResponse?['label']?.toString(),
    );
    final backendConfidence = _confidenceToUnit(
      backendEmotionResponse?['confidence'],
    );

    final lyricsEmotion = lyricsMood?['mood'] == null
        ? null
        : _normalizeNlpEmotion(lyricsMood?['mood']?.toString());
    final lyricsConfidence = _confidenceToUnit(lyricsMood?['confidence']);
    final lyricsMatchedKeywords =
        (lyricsMood?['matched_keywords'] as List?) ?? [];

    final isDefaultLyricsRelax =
        lyricsEmotion == NlpEmotion.relaxed &&
        lyricsConfidence <= 0.45 &&
        lyricsMatchedKeywords.isEmpty;

    late String finalEmotion;
    late double finalConfidence;
    late EmotionProbabilities finalProbabilities;
    late String source;

    if (localEmotion.emotion != null) {
      finalEmotion = localEmotion.emotion!;
      finalConfidence = localEmotion.confidence;
      finalProbabilities = localEmotion.probabilities;
      source = 'local';
    } else if (backendEmotionResponse?['label'] != null) {
      finalEmotion = backendEmotion;
      finalConfidence = backendConfidence == 0 ? 0.75 : backendConfidence;
      finalProbabilities = _buildProbabilitiesFromConfidence(
        finalEmotion,
        finalConfidence,
      );
      source = 'backend';
    } else if (lyricsEmotion != null && !isDefaultLyricsRelax) {
      finalEmotion = lyricsEmotion;
      finalConfidence = lyricsConfidence == 0 ? 0.65 : lyricsConfidence;
      finalProbabilities = _buildProbabilitiesFromConfidence(
        finalEmotion,
        finalConfidence,
      );
      source = 'lyrics';
    } else {
      finalEmotion = NlpEmotion.relaxed;
      finalConfidence = 0.65;
      finalProbabilities = _buildProbabilitiesFromConfidence(
        finalEmotion,
        finalConfidence,
      );
      source = 'local';
    }

    final backendRecommendation = await _getBackendRecommendations(
      emotion: finalEmotion,
      confidence: finalConfidence,
      limit: limit,
      rawEmotion: backendEmotionResponse,
    );

    final localTracks = await _getTracksByMood(finalEmotion, limit);

    final preferLocalTracks =
        localTracks.isNotEmpty &&
        localTracks.any(
          (track) => _isMoodMatch(
            track.track.mood ?? track.track.emotion,
            finalEmotion,
          ),
        );

    final mergedTracks = preferLocalTracks
        ? _mergeUniqueTracks(localTracks, backendRecommendation.tracks)
        : _mergeUniqueTracks(backendRecommendation.tracks, localTracks);

    final recommendedSongs = _rankTracksByMood(
      mergedTracks,
      finalEmotion,
    ).take(limit).toList();

    final fallbackRationale =
        backendRecommendation.rationale ??
        (lyricsMood != null && !isDefaultLyricsRelax
            ? 'Mood lyrics: ${lyricsMood['mood']}.'
            : 'Đề xuất theo cảm xúc $finalEmotion.');

    return EmotionDetectResult(
      emotion: finalEmotion,
      confidence: finalConfidence,
      confidencePercent: (finalConfidence * 100).round(),
      probabilities: finalProbabilities,
      recommendedSongs: recommendedSongs,
      autoPlaySong: recommendedSongs.isEmpty ? null : recommendedSongs.first,
      rationale: source == 'local'
          ? _buildMixedEmotionRationale(localEmotion, fallbackRationale)
          : fallbackRationale,
    );
  }

  Future<Map<String, dynamic>?> _detectBackendEmotion(String text) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/emotion/detect',
        data: {'text': text},
      );

      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _analyzeLyricsMood(String text) async {
    try {
      final response = await _apiClient.dio.post(
        '/lyrics-mood/analyze',
        data: {'lyrics': text, 'language': 'auto', 'top_k': 3},
      );

      final data = Map<String, dynamic>.from(response.data);
      final moods = data['moods'];

      if (moods is List && moods.isNotEmpty) {
        return Map<String, dynamic>.from(moods.first);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<({List<RecommendedTrack> tracks, String? rationale})>
  _getBackendRecommendations({
    required String emotion,
    required double confidence,
    required int limit,
    required Map<String, dynamic>? rawEmotion,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/recommend/',
        data: {
          'user_id': 0,
          'emotion_state': {
            'label': emotion,
            'emotion': emotion,
            'mood': emotion,
            'confidence': confidence,
            'valence': rawEmotion?['valence'] ?? 0,
            'arousal': rawEmotion?['arousal'] ?? 0,
          },
          'limit': limit,
        },
      );

      final data = Map<String, dynamic>.from(response.data);
      final rawTracks = data['tracks'];

      final tracks = rawTracks is List
          ? rawTracks
                .whereType<Map>()
                .map(
                  (track) => _normalizeTrack(
                    Map<String, dynamic>.from(track),
                    emotion,
                  ),
                )
                .toList()
          : <RecommendedTrack>[];

      return (
        tracks: _rankTracksByMood(tracks, emotion),
        rationale: data['rationale']?.toString(),
      );
    } catch (_) {
      return (tracks: <RecommendedTrack>[], rationale: null);
    }
  }

  Future<List<RecommendedTrack>> _getTracksByMood(
    String emotion,
    int limit,
  ) async {
    try {
      final response = await _apiClient.dio.get('/tracks/');
      final data = response.data;

      if (data is! List) return [];

      final tracks = data
          .whereType<Map>()
          .map(
            (track) =>
                _normalizeTrack(Map<String, dynamic>.from(track), emotion),
          )
          .toList();

      return _rankTracksByMood(tracks, emotion).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  RecommendedTrack _normalizeTrack(Map<String, dynamic> json, String emotion) {
    final mood =
        json['mood']?.toString() ?? json['emotion']?.toString() ?? emotion;

    final matched = _isMoodMatch(mood, emotion);

    final score = _toDouble(
      json['recommendation_score'],
      fallback: matched ? 95 : 55,
    );

    final track = Track(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? 'Không rõ tên bài hát',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      audioUrl: json['audio_url']?.toString(),
      coverImage: json['cover_image']?.toString(),
      durationSeconds: _toInt(json['duration']),
      emotion: json['emotion']?.toString() ?? mood,
      mood: mood,
      emotionLabelVi: json['emotion_label_vi']?.toString(),
      lyrics: json['lyrics']?.toString(),
    );

    return RecommendedTrack(
      track: track,
      recommendationScore: score,
      matchedMood: json['matched_mood']?.toString() ?? mood,
    );
  }

  LocalEmotionResult _detectLocalEmotion(String text) {
    final scores = _emptyProbabilities();
    final matchedKeywords = {
      for (final emotion in NlpEmotion.values) emotion: <String>[],
    };

    for (final entry in localKeywords.entries) {
      final result = _scoreKeywordRules(text, entry.value);
      scores[entry.key] = scores[entry.key]! + result.score;
      matchedKeywords[entry.key]!.addAll(result.matchedKeywords);
    }

    final contrastTail = _getContrastTail(text);

    if (contrastTail.isNotEmpty) {
      for (final entry in localKeywords.entries) {
        final result = _scoreKeywordRules(contrastTail, entry.value);
        scores[entry.key] = scores[entry.key]! + result.score * 0.25;
      }
    }

    final probabilities = _normalizeScoresToProbabilities(scores);
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalScore = scores.values.fold<double>(0, (sum, item) => sum + item);

    if (totalScore <= 0) {
      return LocalEmotionResult(
        emotion: null,
        confidence: 0,
        scores: scores,
        probabilities: probabilities,
        matchedKeywords: matchedKeywords,
      );
    }

    return LocalEmotionResult(
      emotion: sorted.first.key,
      confidence: sorted.first.value,
      scores: scores,
      probabilities: probabilities,
      matchedKeywords: matchedKeywords,
    );
  }

  ({double score, List<String> matchedKeywords}) _scoreKeywordRules(
    String text,
    List<KeywordRule> rules,
  ) {
    final normalizedText = ' ${_normalizeVietnameseText(text)} ';
    final matchedKeywords = <String>[];
    double score = 0;

    final sortedRules = [...rules]
      ..sort(
        (a, b) => _normalizeVietnameseText(
          b.keyword,
        ).length.compareTo(_normalizeVietnameseText(a.keyword).length),
      );

    for (final rule in sortedRules) {
      final keyword = _normalizeVietnameseText(rule.keyword);
      if (keyword.isEmpty) continue;

      if (normalizedText.contains(' $keyword ')) {
        matchedKeywords.add(rule.keyword);
        score += rule.weight;
      }
    }

    return (score: score, matchedKeywords: matchedKeywords);
  }

  String _getContrastTail(String text) {
    final normalized = _normalizeVietnameseText(text);

    for (final marker in contrastMarkers) {
      final normalizedMarker = _normalizeVietnameseText(marker);
      final pattern = ' $normalizedMarker ';
      final index = normalized.indexOf(pattern);

      if (index >= 0) {
        return normalized.substring(index + pattern.length).trim();
      }
    }

    return '';
  }

  EmotionProbabilities _emptyProbabilities() {
    return {
      NlpEmotion.happy: 0,
      NlpEmotion.sad: 0,
      NlpEmotion.angry: 0,
      NlpEmotion.relaxed: 0,
    };
  }

  EmotionProbabilities _normalizeScoresToProbabilities(
    EmotionProbabilities scores,
  ) {
    final rawTotal = scores.values.fold<double>(0, (sum, item) => sum + item);

    if (rawTotal <= 0) {
      return {
        NlpEmotion.happy: 0.25,
        NlpEmotion.sad: 0.25,
        NlpEmotion.angry: 0.25,
        NlpEmotion.relaxed: 0.25,
      };
    }

    const smoothing = 0.08;
    final damped = {
      for (final emotion in NlpEmotion.values)
        emotion: sqrt(max(0, scores[emotion] ?? 0)),
    };

    final total = NlpEmotion.values.fold<double>(
      0,
      (sum, emotion) => sum + damped[emotion]! + smoothing,
    );

    return {
      for (final emotion in NlpEmotion.values)
        emotion: (damped[emotion]! + smoothing) / total,
    };
  }

  EmotionProbabilities _buildProbabilitiesFromConfidence(
    String emotion,
    double confidence,
  ) {
    final safeConfidence = confidence.clamp(0.25, 0.98);
    final rest = max(0, 1 - safeConfidence) / 3;

    return {
      NlpEmotion.happy: emotion == NlpEmotion.happy ? safeConfidence : rest,
      NlpEmotion.sad: emotion == NlpEmotion.sad ? safeConfidence : rest,
      NlpEmotion.angry: emotion == NlpEmotion.angry ? safeConfidence : rest,
      NlpEmotion.relaxed: emotion == NlpEmotion.relaxed ? safeConfidence : rest,
    };
  }

  String _normalizeNlpEmotion(String? value) {
    final raw = _normalizeVietnameseText(value ?? 'relaxed');

    for (final entry in moodAliases.entries) {
      if (entry.value.any((alias) => _normalizeVietnameseText(alias) == raw)) {
        return entry.key;
      }
    }

    if (raw.contains('vui') ||
        raw.contains('happy') ||
        raw.contains('joy') ||
        raw.contains('positive')) {
      return NlpEmotion.happy;
    }

    if (raw.contains('buon') ||
        raw.contains('sad') ||
        raw.contains('lonely') ||
        raw.contains('co don')) {
      return NlpEmotion.sad;
    }

    if (raw.contains('angry') ||
        raw.contains('stress') ||
        raw.contains('cang') ||
        raw.contains('gian') ||
        raw.contains('buc') ||
        raw.contains('kho chiu')) {
      return NlpEmotion.angry;
    }

    return NlpEmotion.relaxed;
  }

  bool _isMoodMatch(String? trackMood, String emotion) {
    final raw = _normalizeVietnameseText(trackMood ?? '');
    if (raw.isEmpty) return false;

    return moodAliases[emotion]!.any((alias) {
      final normalizedAlias = _normalizeVietnameseText(alias);
      return raw == normalizedAlias || raw.contains(normalizedAlias);
    });
  }

  List<RecommendedTrack> _rankTracksByMood(
    List<RecommendedTrack> tracks,
    String emotion,
  ) {
    final sorted = [...tracks];

    sorted.sort((a, b) {
      final aMatched = _isMoodMatch(a.track.mood ?? a.track.emotion, emotion)
          ? 1
          : 0;
      final bMatched = _isMoodMatch(b.track.mood ?? b.track.emotion, emotion)
          ? 1
          : 0;

      if (aMatched != bMatched) {
        return bMatched.compareTo(aMatched);
      }

      return b.recommendationScore.compareTo(a.recommendationScore);
    });

    return sorted;
  }

  List<RecommendedTrack> _mergeUniqueTracks(
    List<RecommendedTrack> first,
    List<RecommendedTrack> second,
  ) {
    final map = <int, RecommendedTrack>{};

    for (final track in [...first, ...second]) {
      map.putIfAbsent(track.track.id, () => track);
    }

    return map.values.toList();
  }

  String _buildMixedEmotionRationale(
    LocalEmotionResult localEmotion,
    String fallback,
  ) {
    final rows =
        localEmotion.probabilities.entries
            .where((entry) => entry.value >= 0.12)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (rows.length >= 2) {
      final text = rows
          .map((entry) {
            final label = labels[entry.key]?['vi'] ?? entry.key;
            final percent = (entry.value * 100).round();

            return '$label: $percent%';
          })
          .join(', ');

      return 'Câu có nhiều sắc thái cảm xúc: $text.';
    }

    return fallback;
  }

  double _confidenceToUnit(dynamic value) {
    final numeric = _toDouble(value, fallback: 0);

    if (numeric > 1) {
      return (numeric / 100).clamp(0, 1);
    }

    return numeric.clamp(0, 1);
  }

  String emotionNameLabel(String emotion, {String language = 'vi'}) {
    return labels[emotion]?[language] ?? emotion;
  }

  String _normalizeVietnameseText(String value) {
    var text = value.toLowerCase();

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

    replacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.trim();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value, {required double fallback}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
