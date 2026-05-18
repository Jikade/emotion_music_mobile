import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/lyrics.dart';
import '../providers/music_providers.dart';

class DangPhatScreen extends ConsumerWidget {
  const DangPhatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);
    final nowPlaying = playerState.nowPlaying;

    if (nowPlaying == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 60,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: const Text(
            'Hiện tại không có bài nào đang phát',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final trackRepository = ref.watch(trackRepositoryProvider);
    final coverUrl = trackRepository.getCoverUrl(nowPlaying);
    final palette = nowPlaying.palette;

    final parsedLyrics = parseLyrics(nowPlaying.lyrics);
    final currentLyric = getCurrentLyricLine(
      parsedLyrics,
      playerState.currentTime,
    );

    final errorMessage = playerState.errorMessage;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: [
                  palette.primary.withOpacity(0.28),
                  const Color(0xff05070d),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -90,
          top: -80,
          child: _BlurCircle(
            color: palette.primary.withOpacity(0.30),
            size: 240,
          ),
        ),
        Positioned(
          right: -120,
          bottom: -120,
          child: _BlurCircle(
            color: palette.secondary.withOpacity(0.24),
            size: 300,
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xff070b12).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: Colors.white.withOpacity(0.09)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 90,
                      offset: const Offset(0, 28),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _CoverArt(
                              coverUrl: coverUrl,
                              title: nowPlaying.title,
                              isPlaying: playerState.isPlaying,
                              palette: palette,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            flex: 7,
                            child: _PlayerInfoAndControls(
                              title: nowPlaying.title,
                              artist: nowPlaying.artist,
                              mood: playerState.currentEmotion,
                              palette: palette,
                              progress: playerState.progress,
                              currentTime: playerState.currentTime,
                              totalDuration: playerState.totalDuration,
                              isPlaying: playerState.isPlaying,
                              volume: playerState.volume,
                              isMuted: playerState.isMuted,
                              currentLyric: currentLyric?.text,
                              errorMessage: errorMessage,
                              onProgressChanged: controller.setProgress,
                              onTogglePlay: () => controller.togglePlayPause(),
                              onPrevious: () => controller.playPrevious(),
                              onNext: () => controller.playNext(),
                              onVolumeChanged: controller.setVolume,
                              onMutedChanged: controller.setMuted,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _CoverArt(
                          coverUrl: coverUrl,
                          title: nowPlaying.title,
                          isPlaying: playerState.isPlaying,
                          palette: palette,
                        ),
                        const SizedBox(height: 28),
                        _PlayerInfoAndControls(
                          title: nowPlaying.title,
                          artist: nowPlaying.artist,
                          mood: playerState.currentEmotion,
                          palette: palette,
                          progress: playerState.progress,
                          currentTime: playerState.currentTime,
                          totalDuration: playerState.totalDuration,
                          isPlaying: playerState.isPlaying,
                          volume: playerState.volume,
                          isMuted: playerState.isMuted,
                          currentLyric: currentLyric?.text,
                          errorMessage: errorMessage,
                          onProgressChanged: controller.setProgress,
                          onTogglePlay: () => controller.togglePlayPause(),
                          onPrevious: () => controller.playPrevious(),
                          onNext: () => controller.playNext(),
                          onVolumeChanged: controller.setVolume,
                          onMutedChanged: controller.setMuted,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverArt extends StatelessWidget {
  const _CoverArt({
    required this.coverUrl,
    required this.title,
    required this.isPlaying,
    required this.palette,
  });

  final String coverUrl;
  final String title;
  final bool isPlaying;
  final dynamic palette;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withOpacity(0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.42),
                    blurRadius: 70,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: coverUrl.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.primary.withOpacity(0.9),
                            palette.secondary.withOpacity(0.75),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 88,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                palette.primary.withOpacity(0.9),
                                palette.secondary.withOpacity(0.75),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 88,
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (isPlaying)
            Positioned(
              left: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Row(
                  children: [
                    _PulseBar(height: 14),
                    SizedBox(width: 4),
                    _PulseBar(height: 20),
                    SizedBox(width: 4),
                    _PulseBar(height: 11),
                    SizedBox(width: 4),
                    _PulseBar(height: 17),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseBar extends StatelessWidget {
  const _PulseBar({required this.height});

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

class _PlayerInfoAndControls extends StatelessWidget {
  const _PlayerInfoAndControls({
    required this.title,
    required this.artist,
    required this.mood,
    required this.palette,
    required this.progress,
    required this.currentTime,
    required this.totalDuration,
    required this.isPlaying,
    required this.volume,
    required this.isMuted,
    required this.currentLyric,
    required this.errorMessage,
    required this.onProgressChanged,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
    required this.onVolumeChanged,
    required this.onMutedChanged,
  });

  final String title;
  final String artist;
  final String mood;
  final dynamic palette;
  final double progress;
  final Duration currentTime;
  final Duration totalDuration;
  final bool isPlaying;
  final double volume;
  final bool isMuted;
  final String? currentLyric;
  final String? errorMessage;

  final ValueChanged<double> onProgressChanged;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onMutedChanged;

  @override
  Widget build(BuildContext context) {
    final safeDuration = totalDuration == Duration.zero
        ? const Duration(seconds: 1)
        : totalDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ĐANG PHÁT',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          artist.isEmpty ? 'Unknown Artist' : artist,
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 18),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: Text(
            'Mood: $mood',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 30),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            activeTrackColor: palette.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.10),
            thumbColor: Colors.white,
          ),
          child: Slider(
            min: 0,
            max: 100,
            value: progress.clamp(0, 100).toDouble(),
            onChanged: onProgressChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(currentTime),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.42),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatDuration(safeDuration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.42),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (currentLyric != null && currentLyric!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: palette.primary.withOpacity(0.18),
              border: Border.all(color: palette.primary.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withOpacity(0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Text(
              currentLyric!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleButton(
              icon: Icons.skip_previous,
              size: 52,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withOpacity(0.35),
                      blurRadius: 45,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
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
                      isPlaying ? 'dangphat-pause-icon' : 'dangphat-play-icon',
                    ),
                    color: Colors.black,
                    size: 42,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            _CircleButton(icon: Icons.skip_next, size: 52, onPressed: onNext),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.045),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => onMutedChanged(!isMuted),
                icon: Icon(
                  isMuted || volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: Colors.white.withOpacity(0.78),
                    inactiveTrackColor: Colors.white.withOpacity(0.10),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0,
                    max: 100,
                    value: isMuted ? 0.0 : volume.clamp(0, 100).toDouble(),
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '${isMuted ? 0 : volume.round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: IconButton.styleFrom(
        fixedSize: Size(size, size),
        backgroundColor: Colors.white.withOpacity(0.05),
        foregroundColor: Colors.white.withOpacity(0.7),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
