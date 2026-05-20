import 'dart:math' as math;

import '../../music/models/track.dart';

enum BotCommandType { play, control, volume, none }

enum BotPlayerControl { pause, resume, next, previous }

class BotCommandResult {
  final BotCommandType type;
  final String reply;
  final Track? track;
  final BotPlayerControl? control;
  final double? volume;
  final bool? muted;

  const BotCommandResult({
    required this.type,
    required this.reply,
    this.track,
    this.control,
    this.volume,
    this.muted,
  });
}

class MusicBotQuickPrompt {
  final String id;
  final String label;
  final String prompt;

  const MusicBotQuickPrompt({
    required this.id,
    required this.label,
    required this.prompt,
  });
}

const musicBotQuickPrompts = [
  MusicBotQuickPrompt(
    id: 'happy',
    label: 'Nhạc vui',
    prompt: 'Hãy phát nhạc vui',
  ),
  MusicBotQuickPrompt(
    id: 'sad',
    label: 'Nhạc buồn',
    prompt: 'Hãy phát nhạc buồn',
  ),
  MusicBotQuickPrompt(
    id: 'random',
    label: 'Random',
    prompt: 'Phát một bài ngẫu nhiên',
  ),
  MusicBotQuickPrompt(id: 'pause', label: 'Tạm dừng', prompt: 'Tạm dừng nhạc'),
];

class _TrackMatch {
  final Track track;
  final int score;
  final String reason;

  const _TrackMatch({
    required this.track,
    required this.score,
    required this.reason,
  });
}

BotCommandResult resolveBotMusicCommand(
  String rawInput,
  List<Track> songs, {
  required String currentEmotion,
  Track? nowPlaying,
}) {
  final input = rawInput.trim();

  if (input.isEmpty) {
    return const BotCommandResult(
      type: BotCommandType.none,
      reply: 'Bạn muốn nghe bài gì? Hãy nhập tên bài, mood hoặc artist nhé.',
    );
  }

  final normalized = _normalize(input);

  if (_hasAny(normalized, [
    'tam dung',
    'dung nhac',
    'dung lai',
    'pause',
    'stop',
  ])) {
    return const BotCommandResult(
      type: BotCommandType.control,
      control: BotPlayerControl.pause,
      reply: 'Mình đã tạm dừng nhạc.',
    );
  }

  if (_hasAny(normalized, [
    'phat tiep',
    'tiep tuc',
    'resume',
    'continue',
    'play again',
  ])) {
    return const BotCommandResult(
      type: BotCommandType.control,
      control: BotPlayerControl.resume,
      reply: 'Mình phát tiếp bài đang nghe nhé.',
    );
  }

  if (_hasAny(normalized, [
    'bai tiep',
    'tiep theo',
    'next',
    'skip',
    'chuyen bai',
  ])) {
    return const BotCommandResult(
      type: BotCommandType.control,
      control: BotPlayerControl.next,
      reply: 'Mình chuyển sang bài tiếp theo.',
    );
  }

  if (_hasAny(normalized, [
    'bai truoc',
    'quay lai',
    'previous',
    'prev',
    'back',
  ])) {
    return const BotCommandResult(
      type: BotCommandType.control,
      control: BotPlayerControl.previous,
      reply: 'Mình quay lại bài trước.',
    );
  }

  if (_hasAny(normalized, ['tat tieng', 'mute', 'im lang'])) {
    return const BotCommandResult(
      type: BotCommandType.volume,
      volume: 0,
      muted: true,
      reply: 'Mình đã tắt âm lượng.',
    );
  }

  if (_hasAny(normalized, ['bat tieng', 'unmute', 'mo tieng'])) {
    return const BotCommandResult(
      type: BotCommandType.volume,
      volume: 80,
      muted: false,
      reply: 'Mình đã bật lại âm lượng.',
    );
  }

  final volume = _readVolume(normalized);

  if (volume != null) {
    return BotCommandResult(
      type: BotCommandType.volume,
      volume: volume,
      muted: volume <= 0,
      reply: 'Mình đã chỉnh âm lượng thành ${volume.round()}%.',
    );
  }

  if (songs.isEmpty) {
    return const BotCommandResult(
      type: BotCommandType.none,
      reply:
          'Mình chưa tải được danh sách bài hát. Hãy thử lại sau vài giây nhé.',
    );
  }

  if (_hasAny(normalized, [
    'random',
    'ngau nhien',
    'bat ky',
    'bai nao cung duoc',
  ])) {
    final track = _pickRandomLike(songs, normalized);

    return BotCommandResult(
      type: BotCommandType.play,
      track: track,
      reply: 'Mình phát ngẫu nhiên bài "${track.title}" của ${track.artist}.',
    );
  }

  final moodTrack = _findByMood(normalized, songs);

  if (moodTrack != null) {
    return BotCommandResult(
      type: BotCommandType.play,
      track: moodTrack,
      reply:
          'Mình tìm thấy bài "${moodTrack.title}" phù hợp với mood ${moodTrack.moodText}.',
    );
  }

  final songQuery = _extractSongQuery(normalized);
  final bestMatch = _findBestTrackMatch(songQuery, songs);

  if (bestMatch != null) {
    final track = bestMatch.track;

    final reply = switch (bestMatch.reason) {
      'artist' =>
        'Mình tìm thấy ca sĩ ${track.artist}, phát bài "${track.title}".',
      'fuzzy_title' =>
        'Có vẻ bạn muốn nghe "${track.title}". Mình phát bài này nhé.',
      'fuzzy_artist' =>
        'Có vẻ bạn muốn nghe nhạc của ${track.artist}. Mình phát bài "${track.title}".',
      _ => 'Mình phát bài "${track.title}" của ${track.artist}.',
    };

    return BotCommandResult(
      type: BotCommandType.play,
      track: track,
      reply: reply,
    );
  }

  final emotionTrack = _findByMood(_normalize(currentEmotion), songs);

  if (emotionTrack != null) {
    return BotCommandResult(
      type: BotCommandType.play,
      track: emotionTrack,
      reply:
          'Mình chưa tìm đúng tên bài hoặc ca sĩ bạn nói, nên phát bài hợp mood hiện tại: "${emotionTrack.title}".',
    );
  }

  final currentText = nowPlaying == null
      ? ''
      : ' Bài hiện tại là "${nowPlaying.title}" của ${nowPlaying.artist}.';

  return BotCommandResult(
    type: BotCommandType.none,
    reply:
        'Mình chưa hiểu lệnh này. Bạn có thể nói: "Hãy phát bài Lemon Tree", "phát nhạc của Ed Sheeran", "phát nhạc buồn", "next", "pause", hoặc "âm lượng 50".$currentText',
  );
}

Track _pickRandomLike(List<Track> songs, String normalizedInput) {
  final moodTrack = _findByMood(normalizedInput, songs);

  if (moodTrack != null) return moodTrack;

  final index = DateTime.now().millisecondsSinceEpoch % songs.length;

  return songs[index];
}

Track? _findByMood(String normalizedInput, List<Track> songs) {
  final moodKeys = <String, List<String>>{
    'happy': [
      'happy',
      'vui',
      'vui ve',
      'hanh phuc',
      'tich cuc',
      'sui dong',
      'joy',
      'cheerful',
    ],
    'sad': [
      'sad',
      'buon',
      'co don',
      'tam trang',
      'that tinh',
      'lonely',
      'blue',
    ],
    'angry': ['angry', 'gian', 'tuc', 'stress', 'cang thang', 'mad'],
    'relaxed': ['relaxed', 'relax', 'thu gian', 'chill', 'binh yen', 'calm'],
    'energetic': ['energetic', 'nang luong', 'manh me', 'soi dong', 'energy'],
    'romantic': ['romantic', 'lang man', 'yeu', 'love'],
    'nostalgic': ['nostalgic', 'hoai niem', 'xua', 'ky niem'],
  };

  String? targetMood;

  for (final entry in moodKeys.entries) {
    final matched = entry.value.any(normalizedInput.contains);

    if (matched) {
      targetMood = entry.key;
      break;
    }
  }

  if (targetMood == null) return null;

  for (final track in songs) {
    final mood = _normalize(track.moodText);

    if (mood.contains(targetMood)) {
      return track;
    }

    final aliases = moodKeys[targetMood] ?? const <String>[];

    if (aliases.any(mood.contains)) {
      return track;
    }
  }

  return null;
}

_TrackMatch? _findBestTrackMatch(String query, List<Track> songs) {
  final cleanQuery = query.trim();

  if (cleanQuery.isEmpty) return null;

  final candidates = <_TrackMatch>[];

  for (final track in songs) {
    final title = _normalize(track.title);
    final artist = _normalize(track.artist);
    final combined = '$title $artist'.trim();

    final compactQuery = _compact(cleanQuery);
    final compactTitle = _compact(title);
    final compactArtist = _compact(artist);
    final compactCombined = _compact(combined);

    int score = 0;
    String reason = 'exact';

    if (title == cleanQuery) {
      score += 220;
      reason = 'title';
    }

    if (artist == cleanQuery) {
      score += 205;
      reason = 'artist';
    }

    if (title.contains(cleanQuery)) {
      score += 170;
      reason = 'title';
    }

    if (cleanQuery.contains(title) && title.isNotEmpty) {
      score += 155;
      reason = 'title';
    }

    if (artist.contains(cleanQuery)) {
      score += 150;
      reason = 'artist';
    }

    if (cleanQuery.contains(artist) && artist.isNotEmpty) {
      score += 145;
      reason = 'artist';
    }

    if (combined.contains(cleanQuery)) {
      score += 130;
      reason = 'title';
    }

    if (compactTitle == compactQuery) {
      score += 190;
      reason = 'title';
    }

    if (compactArtist == compactQuery) {
      score += 175;
      reason = 'artist';
    }

    if (compactCombined.contains(compactQuery) && compactQuery.length >= 3) {
      score += 120;
      reason = 'title';
    }

    final titleSimilarity = _similarity(cleanQuery, title);
    final artistSimilarity = _similarity(cleanQuery, artist);
    final combinedSimilarity = _similarity(cleanQuery, combined);
    final compactTitleSimilarity = _similarity(compactQuery, compactTitle);
    final compactArtistSimilarity = _similarity(compactQuery, compactArtist);

    if (titleSimilarity >= 0.74) {
      score += (titleSimilarity * 120).round();
      reason = 'fuzzy_title';
    }

    if (artistSimilarity >= 0.74) {
      score += (artistSimilarity * 112).round();
      reason = 'fuzzy_artist';
    }

    if (combinedSimilarity >= 0.72) {
      score += (combinedSimilarity * 90).round();
      reason = reason == 'exact' ? 'fuzzy_title' : reason;
    }

    if (compactTitleSimilarity >= 0.76) {
      score += (compactTitleSimilarity * 118).round();
      reason = 'fuzzy_title';
    }

    if (compactArtistSimilarity >= 0.76) {
      score += (compactArtistSimilarity * 108).round();
      reason = 'fuzzy_artist';
    }

    final tokenScore = _tokenMatchScore(cleanQuery, title, artist);

    score += tokenScore.score;

    if (tokenScore.reason != null && reason == 'exact') {
      reason = tokenScore.reason!;
    }

    final typoScore = _typoWordScore(cleanQuery, title, artist);

    score += typoScore.score;

    if (typoScore.reason != null) {
      reason = typoScore.reason!;
    }

    if (score > 0) {
      candidates.add(_TrackMatch(track: track, score: score, reason: reason));
    }
  }

  if (candidates.isEmpty) return null;

  candidates.sort((a, b) => b.score.compareTo(a.score));

  final best = candidates.first;

  // Ngưỡng này đủ thấp để bắt typo như:
  // "Dailyght" -> "Daylight"
  // "Death ded" -> "Death bed"
  // nhưng vẫn tránh phát nhầm khi user nhập quá mơ hồ.
  if (best.score < 62) return null;

  return best;
}

({int score, String? reason}) _tokenMatchScore(
  String query,
  String title,
  String artist,
) {
  final queryTokens = _tokens(query);
  final titleTokens = _tokens(title);
  final artistTokens = _tokens(artist);

  if (queryTokens.isEmpty) {
    return (score: 0, reason: null);
  }

  int titleScore = 0;
  int artistScore = 0;

  for (final queryToken in queryTokens) {
    if (queryToken.length < 2) continue;

    for (final titleToken in titleTokens) {
      if (titleToken == queryToken) {
        titleScore += 26;
      } else if (titleToken.contains(queryToken) ||
          queryToken.contains(titleToken)) {
        titleScore += 17;
      } else {
        final similarity = _similarity(queryToken, titleToken);

        if (similarity >= 0.72) {
          titleScore += (similarity * 18).round();
        }
      }
    }

    for (final artistToken in artistTokens) {
      if (artistToken == queryToken) {
        artistScore += 24;
      } else if (artistToken.contains(queryToken) ||
          queryToken.contains(artistToken)) {
        artistScore += 15;
      } else {
        final similarity = _similarity(queryToken, artistToken);

        if (similarity >= 0.72) {
          artistScore += (similarity * 16).round();
        }
      }
    }
  }

  if (artistScore > titleScore) {
    return (score: artistScore, reason: 'artist');
  }

  if (titleScore > 0) {
    return (score: titleScore, reason: 'title');
  }

  return (score: 0, reason: null);
}

({int score, String? reason}) _typoWordScore(
  String query,
  String title,
  String artist,
) {
  final queryTokens = _tokens(query);
  final titleTokens = _tokens(title);
  final artistTokens = _tokens(artist);

  int titleScore = 0;
  int artistScore = 0;

  for (final queryToken in queryTokens) {
    if (queryToken.length < 3) continue;

    final bestTitle = _bestTokenSimilarity(queryToken, titleTokens);
    final bestArtist = _bestTokenSimilarity(queryToken, artistTokens);

    if (bestTitle >= 0.70) {
      titleScore += (bestTitle * 36).round();
    }

    if (bestArtist >= 0.70) {
      artistScore += (bestArtist * 32).round();
    }
  }

  final queryTokenCount = queryTokens.length;

  if (queryTokenCount >= 2) {
    final titleCoverage = _coverageScore(queryTokens, titleTokens);
    final artistCoverage = _coverageScore(queryTokens, artistTokens);

    titleScore += (titleCoverage * 55).round();
    artistScore += (artistCoverage * 48).round();
  }

  if (artistScore > titleScore) {
    return (score: artistScore, reason: 'fuzzy_artist');
  }

  if (titleScore > 0) {
    return (score: titleScore, reason: 'fuzzy_title');
  }

  return (score: 0, reason: null);
}

double _coverageScore(List<String> queryTokens, List<String> targetTokens) {
  if (queryTokens.isEmpty || targetTokens.isEmpty) return 0;

  double total = 0;

  for (final queryToken in queryTokens) {
    total += _bestTokenSimilarity(queryToken, targetTokens);
  }

  return total / queryTokens.length;
}

double _bestTokenSimilarity(String token, List<String> targetTokens) {
  if (targetTokens.isEmpty) return 0;

  double best = 0;

  for (final targetToken in targetTokens) {
    final value = _similarity(token, targetToken);

    if (value > best) {
      best = value;
    }
  }

  return best;
}

double _similarity(String a, String b) {
  final left = a.trim();
  final right = b.trim();

  if (left.isEmpty || right.isEmpty) return 0;
  if (left == right) return 1;

  final maxLength = math.max(left.length, right.length);

  if (maxLength == 0) return 1;

  final distance = _levenshteinDistance(left, right);
  final levenshtein = 1 - (distance / maxLength);
  final dice = _diceCoefficient(left, right);

  return math.max(levenshtein, dice).clamp(0, 1).toDouble();
}

int _levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final previous = List<int>.generate(b.length + 1, (index) => index);
  final current = List<int>.filled(b.length + 1, 0);

  for (var i = 0; i < a.length; i++) {
    current[0] = i + 1;

    for (var j = 0; j < b.length; j++) {
      final insertCost = current[j] + 1;
      final deleteCost = previous[j + 1] + 1;
      final replaceCost = previous[j] + (a[i] == b[j] ? 0 : 1);

      current[j + 1] = math.min(insertCost, math.min(deleteCost, replaceCost));
    }

    for (var j = 0; j <= b.length; j++) {
      previous[j] = current[j];
    }
  }

  return previous[b.length];
}

double _diceCoefficient(String a, String b) {
  final left = _compact(a);
  final right = _compact(b);

  if (left.length < 2 || right.length < 2) {
    return left == right ? 1 : 0;
  }

  final leftBigrams = <String, int>{};

  for (var i = 0; i < left.length - 1; i++) {
    final gram = left.substring(i, i + 2);

    leftBigrams[gram] = (leftBigrams[gram] ?? 0) + 1;
  }

  int matches = 0;

  for (var i = 0; i < right.length - 1; i++) {
    final gram = right.substring(i, i + 2);
    final count = leftBigrams[gram] ?? 0;

    if (count > 0) {
      leftBigrams[gram] = count - 1;
      matches++;
    }
  }

  return (2.0 * matches) / ((left.length - 1) + (right.length - 1));
}

double? _readVolume(String normalizedInput) {
  if (!normalizedInput.contains('am luong') &&
      !normalizedInput.contains('volume') &&
      !normalizedInput.contains('vol')) {
    return null;
  }

  final match = RegExp(r'(\d{1,3})').firstMatch(normalizedInput);

  if (match == null) {
    if (normalizedInput.contains('tang')) return 90;
    if (normalizedInput.contains('giam')) return 35;

    return null;
  }

  final value = double.tryParse(match.group(1) ?? '');

  if (value == null) return null;

  return value.clamp(0, 100).toDouble();
}

String _extractSongQuery(String normalizedInput) {
  var text = normalizedInput;

  final removePhrases = [
    'khoalisa',
    'ai',
    'hey',
    'ok',
    'hay',
    'giup toi',
    'cho toi',
    'cho minh',
    'minh muon',
    'toi muon',
    'toi muon nghe',
    'minh muon nghe',
    'phat bai hat cua',
    'phat bai cua',
    'phat nhac cua',
    'mo bai hat cua',
    'mo bai cua',
    'nghe bai hat cua',
    'nghe bai cua',
    'bat bai hat cua',
    'bat bai cua',
    'phat bai hat',
    'phat bai',
    'phat nhac',
    'mo bai hat',
    'mo bai',
    'nghe bai hat',
    'nghe bai',
    'bat bai hat',
    'bat bai',
    'cua ca si',
    'cua nghe si',
    'cua tac gia',
    'ca si',
    'nghe si',
    'tac gia',
    'artist',
    'singer',
    'by',
    'from',
    'play song by',
    'play the song by',
    'play songs by',
    'play music by',
    'play song',
    'play the song',
    'play music',
    'play',
    'song by',
    'music by',
    'song',
    'music',
    'bai hat',
    'bai',
    'nhac',
  ];

  for (final phrase in removePhrases) {
    text = text.replaceAll(
      RegExp('(^|\\s)${RegExp.escape(phrase)}(\\s|\$)'),
      ' ',
    );
  }

  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _hasAny(String input, List<String> keys) {
  return keys.any(input.contains);
}

List<String> _tokens(String value) {
  return value
      .split(' ')
      .map((item) => item.trim())
      .where((item) => item.length >= 2)
      .toList();
}

String _compact(String value) {
  return value.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _normalize(String value) {
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

  return text
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
