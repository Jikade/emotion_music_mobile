import 'dart:ui';

class TrackPalette {
  final Color primary;
  final Color secondary;

  const TrackPalette({required this.primary, required this.secondary});

  factory TrackPalette.fromMood(String? mood) {
    final key = (mood ?? '').toLowerCase();

    if (key.contains('happy') || key.contains('vui')) {
      return const TrackPalette(
        primary: Color(0xffffd166),
        secondary: Color(0xff06d6a0),
      );
    }

    if (key.contains('sad') || key.contains('buồn')) {
      return const TrackPalette(
        primary: Color(0xff60a5fa),
        secondary: Color(0xff818cf8),
      );
    }

    if (key.contains('angry') || key.contains('giận')) {
      return const TrackPalette(
        primary: Color(0xfffb7185),
        secondary: Color(0xfff97316),
      );
    }

    if (key.contains('relaxed') ||
        key.contains('calm') ||
        key.contains('thư giãn')) {
      return const TrackPalette(
        primary: Color(0xff34d399),
        secondary: Color(0xff22d3ee),
      );
    }

    return const TrackPalette(
      primary: Color(0xffa78bfa),
      secondary: Color(0xff22d3ee),
    );
  }
}

class Track {
  final int id;
  final String title;
  final String artist;
  final String? audioUrl;
  final String? coverImage;
  final int durationSeconds;
  final String? emotion;
  final String? mood;
  final String? emotionLabelVi;
  final String? lyrics;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    this.audioUrl,
    this.coverImage,
    this.emotion,
    this.mood,
    this.emotionLabelVi,
    this.lyrics,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: _toInt(json['id']),
      title: _toString(json['title'], fallback: 'Không rõ tên bài hát'),
      artist: _toString(json['artist'], fallback: 'Unknown Artist'),
      audioUrl: json['audio_url']?.toString(),
      coverImage: json['cover_image']?.toString(),
      durationSeconds: _toInt(json['duration']),
      emotion: json['emotion']?.toString(),
      mood: json['mood']?.toString(),
      emotionLabelVi: json['emotion_label_vi']?.toString(),
      lyrics: json['lyrics']?.toString(),
    );
  }

  String get moodText {
    final value = emotionLabelVi ?? emotion ?? mood;
    if (value == null || value.trim().isEmpty) return 'Không rõ mood';
    return value;
  }

  TrackPalette get palette {
    return TrackPalette.fromMood(emotionLabelVi ?? emotion ?? mood);
  }

  Duration get duration {
    return Duration(seconds: durationSeconds);
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value, {required String fallback}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }
}
