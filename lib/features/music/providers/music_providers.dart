import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;

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

    return value.clamp(0, 100).toDouble();
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
  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;

  int _playRequestId = 0;
  int _toggleRequestId = 0;

  bool _isPreparingSource = false;

  @override
  PlayerState build() {
    Future.microtask(_attachListeners);

    ref.onDispose(() {
      _positionSub?.cancel();
      _durationSub?.cancel();
      _playerStateSub?.cancel();
      _audioPlayer.dispose();
    });

    return const PlayerState();
  }

  void _attachListeners() {
    _positionSub ??= _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(currentTime: position);
    });

    _durationSub ??= _audioPlayer.durationStream.listen((duration) {
      state = state.copyWith(
        totalDuration: duration ?? state.nowPlaying?.duration ?? Duration.zero,
      );
    });

    _playerStateSub ??= _audioPlayer.playerStateStream.listen((audioState) {
      final processingState = audioState.processingState;

      if (processingState == ja.ProcessingState.completed) {
        _isPreparingSource = false;

        state = state.copyWith(
          isPlaying: false,
          isLoading: false,
          currentTime: state.totalDuration,
        );
        return;
      }

      // Không set isPlaying bằng audioState.playing ở đây.
      // isPlaying chỉ được đổi bởi playTrack(), togglePlayPause(), stopPlayback().
      state = state.copyWith(isLoading: _isPreparingSource);
    });
  }

  Future<void> playTrack(Track track, {required List<Track> queue}) async {
    final requestId = ++_playRequestId;
    _toggleRequestId++;

    _isPreparingSource = true;

    final repository = ref.read(trackRepositoryProvider);
    final audioUrl = repository.getAudioUrl(track);

    if (audioUrl.isEmpty) {
      _isPreparingSource = false;

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
      await _audioPlayer.stop();

      if (requestId != _playRequestId) return;

      await _audioPlayer.setAudioSource(
        ja.AudioSource.uri(Uri.parse(audioUrl)),
        preload: true,
      );

      if (requestId != _playRequestId) return;

      final loadedDuration = _audioPlayer.duration;

      _isPreparingSource = false;

      state = state.copyWith(
        nowPlaying: track,
        queue: queue,
        currentTime: Duration.zero,
        totalDuration: loadedDuration ?? track.duration,
        isLoading: false,
        clearError: true,
      );

      await _audioPlayer.setVolume(state.isMuted ? 0 : state.volume / 100);

      if (requestId != _playRequestId) return;

      // Đổi UI ngay sang Pause ||.
      // Nhưng chỉ đổi nếu playTrack này chưa bị togglePlayPause() hủy.
      state = state.copyWith(
        isPlaying: true,
        isLoading: false,
        clearError: true,
      );

      await _audioPlayer.play();

      // Nếu user bấm pause trong lúc await play(),
      // togglePlayPause() đã tăng _playRequestId.
      // Khi đó playTrack cũ không được set UI về Pause || nữa.
      if (requestId != _playRequestId) {
        await _safePause();
        return;
      }

      _isPreparingSource = false;

      state = state.copyWith(
        isPlaying: true,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (requestId != _playRequestId) return;

      _isPreparingSource = false;

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
    if (state.nowPlaying == null) return;

    final shouldPlay = !state.isPlaying;

    // QUAN TRỌNG:
    // Hủy mọi playTrack() đang chạy dở.
    // Nếu không, playTrack() có thể chạy tiếp sau lần bấm pause đầu tiên
    // rồi set lại isPlaying: true, làm icon quay về dấu ||.
    ++_playRequestId;

    final toggleId = ++_toggleRequestId;

    _isPreparingSource = false;

    // Đổi icon ngay lập tức, không chờ just_audio.
    state = state.copyWith(
      isPlaying: shouldPlay,
      isLoading: false,
      clearError: true,
    );

    try {
      if (shouldPlay) {
        if (_audioPlayer.audioSource == null) {
          final track = state.nowPlaying;
          if (track == null) return;

          await playTrack(track, queue: state.queue);
          return;
        }

        await _audioPlayer.play();

        if (toggleId != _toggleRequestId) return;

        state = state.copyWith(
          isPlaying: true,
          isLoading: false,
          clearError: true,
        );
      } else {
        await _audioPlayer.pause();

        if (toggleId != _toggleRequestId) return;

        state = state.copyWith(
          isPlaying: false,
          isLoading: false,
          clearError: true,
        );
      }
    } catch (error) {
      if (toggleId != _toggleRequestId) return;

      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        errorMessage: 'Không thể đổi trạng thái phát nhạc: $error',
      );
    }
  }

  Future<void> stopPlayback() async {
    ++_playRequestId;
    ++_toggleRequestId;

    _isPreparingSource = false;

    state = state.copyWith(
      isPlaying: false,
      isLoading: false,
      clearError: true,
    );

    try {
      await _audioPlayer.pause();

      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        errorMessage: 'Không thể tạm dừng bài hát: $error',
      );
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
    final duration = _audioPlayer.duration ?? state.totalDuration;

    if (duration.inMilliseconds <= 0) return;

    final percent = value.clamp(0, 100) / 100;
    final targetMilliseconds = (duration.inMilliseconds * percent).round();

    await _audioPlayer.seek(Duration(milliseconds: targetMilliseconds));

    state = state.copyWith(
      currentTime: Duration(milliseconds: targetMilliseconds),
      totalDuration: duration,
    );
  }

  Future<void> setVolume(double value) async {
    final safeVolume = value.clamp(0, 100).toDouble();
    final shouldMute = safeVolume <= 0;

    state = state.copyWith(volume: safeVolume, isMuted: shouldMute);

    await _audioPlayer.setVolume(shouldMute ? 0 : safeVolume / 100);
  }

  Future<void> setMuted(bool value) async {
    state = state.copyWith(isMuted: value);

    await _audioPlayer.setVolume(value ? 0 : state.volume / 100);
  }

  Future<void> _safePause() async {
    try {
      await _audioPlayer.pause();
    } catch (_) {}
  }
}
