class Track {
  final int id;
  final String title;
  final String artist;
  final String? audioUrl;
  final String? coverImage;
  final int duration;
  final String? emotion;
  final String? emotionLabelVi;
  final String? lyrics;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.audioUrl,
    this.coverImage,
    required this.duration,
    this.emotion,
    this.emotionLabelVi,
    this.lyrics,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Không rõ tên bài hát',
      artist: json['artist'] ?? 'Unknown Artist',
      audioUrl: json['audio_url'],
      coverImage: json['cover_image'],
      duration: (json['duration'] ?? 0).round(),
      emotion: json['emotion'] ?? json['mood'],
      emotionLabelVi: json['emotion_label_vi'],
      lyrics: json['lyrics'],
    );
  }
}
