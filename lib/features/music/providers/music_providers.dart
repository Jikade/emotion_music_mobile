import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/like_repository.dart';
import '../data/track_repository.dart';
import '../models/track.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository(ref.watch(apiClientProvider));
});

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  return LikeRepository(ref.watch(apiClientProvider));
});

final tracksProvider = FutureProvider<List<Track>>((ref) async {
  return ref.watch(trackRepositoryProvider).getTracks();
});

final likedTracksProvider = NotifierProvider<LikedTracksController, Set<int>>(
  LikedTracksController.new,
);

class LikedTracksController extends Notifier<Set<int>> {
  late final LikeRepository _repository;

  @override
  Set<int> build() {
    _repository = ref.watch(likeRepositoryProvider);
    Future.microtask(load);
    return <int>{};
  }

  Future<void> load() async {
    try {
      state = await _repository.getLikedTrackIds();
    } catch (_) {
      state = <int>{};
    }
  }

  Future<void> toggleLike(int trackId) async {
    final isLiked = state.contains(trackId);
    final nextState = <int>{...state};

    if (isLiked) {
      nextState.remove(trackId);
      state = nextState;

      try {
        await _repository.unlikeTrack(trackId);
      } catch (_) {}
    } else {
      nextState.add(trackId);
      state = nextState;

      try {
        await _repository.likeTrack(trackId);
      } catch (_) {}
    }
  }
}

class PlayerState {
  final Track? nowPlaying;
  final List<Track> queue;
  final bool isPlaying;
  final bool isLoading;
  final Duration currentTime;
  final Duration totalDuration;
  final double volume;
  final bool isMuted;
  final String? errorMessage;

  const PlayerState({
    this.nowPlaying,
    this.queue = const [],
    this.isPlaying = false,
    this.isLoading = false,
    this.currentTime = Duration.zero,
    this.totalDuration = Duration.zero,
    this.volume = 80,
    this.isMuted = false,
    this.errorMessage,
  });

  double get progress {
    if (totalDuration.inMilliseconds <= 0) return 0;

    final value =
        currentTime.inMilliseconds / totalDuration.inMilliseconds * 100;

    return value.clamp(0, 100);
  }

  String get currentEmotion {
    return nowPlaying?.moodText ?? 'neutral';
  }

  PlayerState copyWith({
    Track? nowPlaying,
    List<Track>? queue,
    bool? isPlaying,
    bool? isLoading,
    Duration? currentTime,
    Duration? totalDuration,
    double? volume,
    bool? isMuted,
    String? errorMessage,
    bool clearNowPlaying = false,
    bool clearError = false,
  }) {
    return PlayerState(
      nowPlaying: clearNowPlaying ? null : nowPlaying ?? this.nowPlaying,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentTime: currentTime ?? this.currentTime,
      totalDuration: totalDuration ?? this.totalDuration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final musicPlayerProvider =
    NotifierProvider<MusicPlayerController, PlayerState>(
      MusicPlayerController.new,
    );

class MusicPlayerController extends Notifier<PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<PlayerState>? _processingSub;

  int _playRequestId = 0;

  @override
  PlayerState build() {
    _positionSub = _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(currentTime: position);
    });

    _durationSub = _audioPlayer.durationStream.listen((duration) {
      state = state.copyWith(
        totalDuration: duration ?? state.nowPlaying?.duration ?? Duration.zero,
      );
    });

    _playingSub = _audioPlayer.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    ref.onDispose(() {
      _positionSub?.cancel();
      _durationSub?.cancel();
      _playingSub?.cancel();
      _processingSub?.cancel();
      _audioPlayer.dispose();
    });

    return const PlayerState();
  }

  Future<void> playTrack(Track track, {required List<Track> queue}) async {
    final requestId = ++_playRequestId;
    final repository = ref.read(trackRepositoryProvider);
    final audioUrl = repository.getAudioUrl(track);

    if (audioUrl.isEmpty) {
      state = state.copyWith(
        nowPlaying: track,
        queue: queue,
        isPlaying: false,
        isLoading: false,
        currentTime: Duration.zero,
        totalDuration: track.duration,
        errorMessage: 'Bài hát này chưa có audio_url.',
      );
      return;
    }

    state = state.copyWith(
      nowPlaying: track,
      queue: queue,
      isPlaying: false,
      isLoading: true,
      currentTime: Duration.zero,
      totalDuration: track.duration,
      clearError: true,
    );

    try {
      // Quan trọng: dừng hẳn source cũ trước khi set source mới.
      await _audioPlayer.stop();

      // Nếu user bấm bài khác rất nhanh, bỏ request cũ.
      if (requestId != _playRequestId) return;

      await _audioPlayer.seek(Duration.zero);

      if (requestId != _playRequestId) return;

      // Set URL mới. Dùng Uri để tránh lỗi URL có dấu cách/ký tự tiếng Việt.
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(audioUrl)),
        preload: true,
      );

      if (requestId != _playRequestId) return;

      await _audioPlayer.setVolume(state.isMuted ? 0 : state.volume / 100);

      if (requestId != _playRequestId) return;

      await _audioPlayer.play();

      if (requestId != _playRequestId) return;

      state = state.copyWith(
        nowPlaying: track,
        queue: queue,
        isPlaying: true,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (requestId != _playRequestId) return;

      await _audioPlayer.stop();

      state = state.copyWith(
        nowPlaying: track,
        queue: queue,
        isPlaying: false,
        isLoading: false,
        currentTime: Duration.zero,
        totalDuration: track.duration,
        errorMessage: 'Không phát được bài hát: $error',
      );
    }
  }

  Future<void> togglePlayPause() async {
    if (state.nowPlaying == null || state.isLoading) return;

    if (state.isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> playNext() async {
    final current = state.nowPlaying;
    final queue = state.queue;

    if (current == null || queue.isEmpty) return;

    final index = queue.indexWhere((item) => item.id == current.id);
    final nextIndex = index < 0 || index == queue.length - 1 ? 0 : index + 1;

    await playTrack(queue[nextIndex], queue: queue);
  }

  Future<void> playPrevious() async {
    final current = state.nowPlaying;
    final queue = state.queue;

    if (current == null || queue.isEmpty) return;

    final index = queue.indexWhere((item) => item.id == current.id);
    final previousIndex = index <= 0 ? queue.length - 1 : index - 1;

    await playTrack(queue[previousIndex], queue: queue);
  }

  Future<void> setProgress(double value) async {
    if (state.totalDuration.inMilliseconds <= 0) return;

    final percent = value.clamp(0, 100) / 100;
    final targetMilliseconds = (state.totalDuration.inMilliseconds * percent)
        .round();

    await _audioPlayer.seek(Duration(milliseconds: targetMilliseconds));
  }

  Future<void> setVolume(double value) async {
    final safeVolume = value.clamp(0, 100).toDouble();

    final shouldMute = safeVolume == 0 ? true : state.isMuted;

    state = state.copyWith(volume: safeVolume, isMuted: shouldMute);

    if (!state.isMuted) {
      await _audioPlayer.setVolume(safeVolume / 100);
    } else {
      await _audioPlayer.setVolume(0);
    }
  }

  Future<void> setMuted(bool value) async {
    state = state.copyWith(isMuted: value);

    await _audioPlayer.setVolume(value ? 0 : state.volume / 100);
  }
}
