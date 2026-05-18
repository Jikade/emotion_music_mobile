import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/download/download_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/lyrics.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/music/models/track.dart';
import '../../features/music/providers/music_providers.dart';
import 'queue_drawer.dart';

const vipDownloadMessage =
    'Hãy mua gói VIP PRO để tải nhạc độc quyền từ chúng tôi';

enum BottomRepeatMode { off, all, one }

class BottomMiniPlayer extends ConsumerStatefulWidget {
  const BottomMiniPlayer({super.key});

  @override
  ConsumerState<BottomMiniPlayer> createState() => _BottomMiniPlayerState();
}

class _BottomMiniPlayerState extends ConsumerState<BottomMiniPlayer> {
  bool _isHidden = false;
  bool _shuffle = false;
  bool _isLikeSaving = false;
  String? _message;
  BottomRepeatMode _repeatMode = BottomRepeatMode.off;

  void _showMessage(String value) {
    setState(() {
      _message = value;
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;

      setState(() {
        _message = null;
      });
    });
  }

  Future<void> _toggleLike(Track track) async {
    if (_isLikeSaving) return;

    setState(() {
      _isLikeSaving = true;
    });

    try {
      await ref.read(likedTracksProvider.notifier).toggleLike(track.id);
    } catch (_) {
      _showMessage('Không lưu được trạng thái thích bài hát.');
    } finally {
      if (!mounted) return;

      setState(() {
        _isLikeSaving = false;
      });
    }
  }

  String _buildDownloadFileName(Track track) {
    final raw = '${track.title}-${track.artist}';

    final safe = raw
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll('Đ', 'D')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return '${safe.isEmpty ? 'bai-hat' : safe}.mp3';
  }

  Future<void> _downloadTrack(Track track) async {
    final authState = ref.read(authControllerProvider);
    final isVip = authState.isLoggedIn && authState.user?.isVip == true;

    if (!isVip) {
      _showMessage(vipDownloadMessage);
      return;
    }

    final audioUrl = ref.read(trackRepositoryProvider).getAudioUrl(track);

    if (audioUrl.isEmpty) {
      _showMessage('Bài hát này chưa có file audio để tải.');
      return;
    }

    try {
      await downloadFromUrl(audioUrl, _buildDownloadFileName(track));
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Unsupported operation: ', ''),
      );
    }
  }

  void _toggleRepeat() {
    setState(() {
      if (_repeatMode == BottomRepeatMode.off) {
        _repeatMode = BottomRepeatMode.all;
      } else if (_repeatMode == BottomRepeatMode.all) {
        _repeatMode = BottomRepeatMode.one;
      } else {
        _repeatMode = BottomRepeatMode.off;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);
    final track = playerState.nowPlaying;

    if (track == null) {
      return const SizedBox.shrink();
    }

    final likedIds = ref.watch(likedTracksProvider);
    final isLiked = likedIds.contains(track.id);

    final authState = ref.watch(authControllerProvider);
    final canDownloadVipPro =
        authState.isLoggedIn && authState.user?.isVip == true;

    final parsedLyrics = parseLyrics(track.lyrics);
    final currentLyric = getCurrentLyricLine(
      parsedLyrics,
      playerState.currentTime,
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HideButton(
            isHidden: _isHidden,
            onTap: () {
              setState(() {
                _isHidden = !_isHidden;
              });
            },
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            crossFadeState: _isHidden
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _FullBottomPlayer(
              track: track,
              isPlaying: playerState.isPlaying,
              progress: playerState.progress,
              currentTime: playerState.currentTime,
              totalDuration: playerState.totalDuration,
              volume: playerState.volume,
              isMuted: playerState.isMuted,
              isLiked: isLiked,
              isLikeSaving: _isLikeSaving,
              shuffle: _shuffle,
              repeatMode: _repeatMode,
              message: _message,
              currentLyric: currentLyric?.text,
              canDownloadVipPro: canDownloadVipPro,
              onToggleLike: () => _toggleLike(track),
              onToggleShuffle: () {
                setState(() {
                  _shuffle = !_shuffle;
                });
              },
              onToggleRepeat: _toggleRepeat,
              onPrevious: () => controller.playPrevious(),
              onNext: () => controller.playNext(),
              onTogglePlay: () => controller.togglePlayPause(),
              onProgressChanged: controller.setProgress,
              onVolumeChanged: controller.setVolume,
              onMutedChanged: controller.setMuted,
              onDownload: () => _downloadTrack(track),
              onOpenQueue: () => showQueueDrawer(context, ref),
              onOpenNowPlaying: () => context.go('/dangPhat'),
              onMic: () => context.go('/nhanDienCamXuc'),
            ),
            secondChild: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HideButton extends StatelessWidget {
  const _HideButton({required this.isHidden, required this.onTap});

  final bool isHidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 1),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xff070b12).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Icon(
            isHidden
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

class _FullBottomPlayer extends ConsumerWidget {
  const _FullBottomPlayer({
    required this.track,
    required this.isPlaying,
    required this.progress,
    required this.currentTime,
    required this.totalDuration,
    required this.volume,
    required this.isMuted,
    required this.isLiked,
    required this.isLikeSaving,
    required this.shuffle,
    required this.repeatMode,
    required this.message,
    required this.currentLyric,
    required this.canDownloadVipPro,
    required this.onToggleLike,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlay,
    required this.onProgressChanged,
    required this.onVolumeChanged,
    required this.onMutedChanged,
    required this.onDownload,
    required this.onOpenQueue,
    required this.onOpenNowPlaying,
    required this.onMic,
  });

  final Track track;
  final bool isPlaying;
  final double progress;
  final Duration currentTime;
  final Duration totalDuration;
  final double volume;
  final bool isMuted;
  final bool isLiked;
  final bool isLikeSaving;
  final bool shuffle;
  final BottomRepeatMode repeatMode;
  final String? message;
  final String? currentLyric;
  final bool canDownloadVipPro;

  final VoidCallback onToggleLike;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onMutedChanged;
  final VoidCallback onDownload;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenNowPlaying;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackRepository = ref.watch(trackRepositoryProvider);
    final coverUrl = trackRepository.getCoverUrl(track);
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff070b12).withOpacity(0.96),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: 38,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: (progress / 100).clamp(0, 1).toDouble(),
            minHeight: 3,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(track.palette.primary),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, isWide ? 10 : 12),
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _SongInfo(
                          track: track,
                          coverUrl: coverUrl,
                          isPlaying: isPlaying,
                          isLiked: isLiked,
                          isLikeSaving: isLikeSaving,
                          onToggleLike: onToggleLike,
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: _CenterControls(
                          track: track,
                          isPlaying: isPlaying,
                          progress: progress,
                          currentTime: currentTime,
                          totalDuration: totalDuration,
                          shuffle: shuffle,
                          repeatMode: repeatMode,
                          currentLyric: currentLyric,
                          onToggleShuffle: onToggleShuffle,
                          onToggleRepeat: onToggleRepeat,
                          onPrevious: onPrevious,
                          onNext: onNext,
                          onTogglePlay: onTogglePlay,
                          onProgressChanged: onProgressChanged,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: _ExtraControls(
                          volume: volume,
                          isMuted: isMuted,
                          canDownloadVipPro: canDownloadVipPro,
                          message: message,
                          onVolumeChanged: onVolumeChanged,
                          onMutedChanged: onMutedChanged,
                          onDownload: onDownload,
                          onOpenQueue: onOpenQueue,
                          onOpenNowPlaying: onOpenNowPlaying,
                          onMic: onMic,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SongInfo(
                              track: track,
                              coverUrl: coverUrl,
                              isPlaying: isPlaying,
                              isLiked: isLiked,
                              isLikeSaving: isLikeSaving,
                              onToggleLike: onToggleLike,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Mở trang đang phát',
                            onPressed: onOpenNowPlaying,
                            icon: const Icon(Icons.open_in_full),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CenterControls(
                        track: track,
                        isPlaying: isPlaying,
                        progress: progress,
                        currentTime: currentTime,
                        totalDuration: totalDuration,
                        shuffle: shuffle,
                        repeatMode: repeatMode,
                        currentLyric: currentLyric,
                        onToggleShuffle: onToggleShuffle,
                        onToggleRepeat: onToggleRepeat,
                        onPrevious: onPrevious,
                        onNext: onNext,
                        onTogglePlay: onTogglePlay,
                        onProgressChanged: onProgressChanged,
                      ),
                      const SizedBox(height: 8),
                      _ExtraControls(
                        volume: volume,
                        isMuted: isMuted,
                        canDownloadVipPro: canDownloadVipPro,
                        message: message,
                        onVolumeChanged: onVolumeChanged,
                        onMutedChanged: onMutedChanged,
                        onDownload: onDownload,
                        onOpenQueue: onOpenQueue,
                        onOpenNowPlaying: onOpenNowPlaying,
                        onMic: onMic,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({
    required this.track,
    required this.coverUrl,
    required this.isPlaying,
    required this.isLiked,
    required this.isLikeSaving,
    required this.onToggleLike,
  });

  final Track track;
  final String coverUrl;
  final bool isPlaying;
  final bool isLiked;
  final bool isLikeSaving;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CoverThumb(
          coverUrl: coverUrl,
          title: track.title,
          isPlaying: isPlaying,
          color: track.palette.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.52),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: track.palette.primary.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: track.palette.primary.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    track.moodText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.74),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: isLiked ? 'Bỏ thích bài hát' : 'Thích bài hát',
          onPressed: isLikeSaving ? null : onToggleLike,
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.redAccent : Colors.white.withOpacity(0.72),
          ),
        ),
      ],
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({
    required this.coverUrl,
    required this.title,
    required this.isPlaying,
    required this.color,
  });

  final String coverUrl;
  final String title;
  final bool isPlaying;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: coverUrl.isEmpty
                ? Container(
                    color: color.withOpacity(0.85),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  )
                : CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return Container(
                        color: color.withOpacity(0.85),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
          ),
          if (isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MusicBar(height: 12),
                        SizedBox(width: 3),
                        _MusicBar(height: 18),
                        SizedBox(width: 3),
                        _MusicBar(height: 14),
                        SizedBox(width: 3),
                        _MusicBar(height: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MusicBar extends StatelessWidget {
  const _MusicBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _CenterControls extends StatelessWidget {
  const _CenterControls({
    required this.track,
    required this.isPlaying,
    required this.progress,
    required this.currentTime,
    required this.totalDuration,
    required this.shuffle,
    required this.repeatMode,
    required this.currentLyric,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlay,
    required this.onProgressChanged,
  });

  final Track track;
  final bool isPlaying;
  final double progress;
  final Duration currentTime;
  final Duration totalDuration;
  final bool shuffle;
  final BottomRepeatMode repeatMode;
  final String? currentLyric;

  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final safeDuration = totalDuration == Duration.zero
        ? track.duration
        : totalDuration;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconControlButton(
              icon: Icons.shuffle,
              selected: shuffle,
              onPressed: onToggleShuffle,
            ),
            _IconControlButton(
              icon: Icons.skip_previous,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: isPlaying ? 'Tạm dừng' : 'Phát tiếp',
              style: IconButton.styleFrom(
                fixedSize: const Size(48, 48),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: onTogglePlay,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey<String>(
                    isPlaying ? 'bottom-pause-icon' : 'bottom-play-icon',
                  ),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _IconControlButton(icon: Icons.skip_next, onPressed: onNext),
            _RepeatButton(repeatMode: repeatMode, onPressed: onToggleRepeat),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                formatDuration(currentTime),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.46),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  activeTrackColor: track.palette.primary,
                  inactiveTrackColor: Colors.white.withOpacity(0.10),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: progress.clamp(0, 100).toDouble(),
                  min: 0,
                  max: 100,
                  onChanged: onProgressChanged,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                formatDuration(safeDuration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.46),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (currentLyric != null && currentLyric!.trim().isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: track.palette.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: track.palette.primary.withOpacity(0.35),
              ),
            ),
            child: Text(
              currentLyric!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _ExtraControls extends StatelessWidget {
  const _ExtraControls({
    required this.volume,
    required this.isMuted,
    required this.canDownloadVipPro,
    required this.message,
    required this.onVolumeChanged,
    required this.onMutedChanged,
    required this.onDownload,
    required this.onOpenQueue,
    required this.onOpenNowPlaying,
    required this.onMic,
  });

  final double volume;
  final bool isMuted;
  final bool canDownloadVipPro;
  final String? message;

  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onMutedChanged;
  final VoidCallback onDownload;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenNowPlaying;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        Row(
          mainAxisAlignment: isWide
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: canDownloadVipPro
                  ? 'Tải bài hát về máy'
                  : 'Cần VIP PRO để tải nhạc',
              onPressed: onDownload,
              icon: Icon(
                Icons.download_rounded,
                color: canDownloadVipPro
                    ? Colors.white.withOpacity(0.72)
                    : Colors.amberAccent,
              ),
            ),
            IconButton(
              tooltip: 'Nhận diện cảm xúc',
              onPressed: onMic,
              icon: Icon(
                Icons.mic_none_rounded,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
            IconButton(
              tooltip: 'Hàng đợi',
              onPressed: onOpenQueue,
              icon: Icon(
                Icons.queue_music_rounded,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
            if (isWide)
              SizedBox(
                width: 122,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: isMuted ? 'Bật âm lượng' : 'Tắt âm lượng',
                      onPressed: () => onMutedChanged(!isMuted),
                      icon: Icon(
                        isMuted || volume == 0
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          activeTrackColor: Colors.white.withOpacity(0.80),
                          inactiveTrackColor: Colors.white.withOpacity(0.10),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: isMuted
                              ? 0.0
                              : volume.clamp(0, 100).toDouble(),
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            onVolumeChanged(value);

                            if (value > 0) {
                              onMutedChanged(false);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              IconButton(
                tooltip: isMuted ? 'Bật âm lượng' : 'Tắt âm lượng',
                onPressed: () => onMutedChanged(!isMuted),
                icon: Icon(
                  isMuted || volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            IconButton(
              tooltip: 'Mở trang đang phát',
              onPressed: onOpenNowPlaying,
              icon: Icon(
                Icons.open_in_full_rounded,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ],
        ),
        if (message != null)
          Positioned(
            right: 8,
            bottom: 54,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xff111827).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.amberAccent.withOpacity(0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  message!,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IconControlButton extends StatelessWidget {
  const _IconControlButton({
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  const _RepeatButton({required this.repeatMode, required this.onPressed});

  final BottomRepeatMode repeatMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final selected = repeatMode != BottomRepeatMode.off;

    return IconButton(
      onPressed: onPressed,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.repeat_rounded,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
          if (repeatMode == BottomRepeatMode.one)
            const Positioned(
              top: 4,
              child: Text(
                '1',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }
}
