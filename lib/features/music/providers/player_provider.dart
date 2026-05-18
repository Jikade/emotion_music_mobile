import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/providers.dart';
import '../models/track.dart';

class MusicPlayerState {
  final Track? currentTrack;
  final bool isPlaying;

  const MusicPlayerState({this.currentTrack, this.isPlaying = false});

  MusicPlayerState copyWith({Track? currentTrack, bool? isPlaying}) {
    return MusicPlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class MusicPlayerController extends StateNotifier<MusicPlayerState> {
  MusicPlayerController(this._ref) : super(const MusicPlayerState());

  final Ref _ref;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> play(Track track) async {
    final repo = _ref.read(trackRepositoryProvider);
    final url = repo.audioUrl(track);

    if (url.isEmpty) return;

    await _audioPlayer.setUrl(url);
    await _audioPlayer.play();

    state = MusicPlayerState(currentTrack: track, isPlaying: true);
  }

  Future<void> toggle() async {
    if (state.isPlaying) {
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _audioPlayer.play();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = const MusicPlayerState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

final musicPlayerProvider =
    StateNotifierProvider<MusicPlayerController, MusicPlayerState>((ref) {
      return MusicPlayerController(ref);
    });
