import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../music/models/track.dart';
import '../../music/providers/music_providers.dart';
import '../providers/recommendation_providers.dart';

class GoiYScreen extends ConsumerStatefulWidget {
  const GoiYScreen({super.key});

  @override
  ConsumerState<GoiYScreen> createState() => _GoiYScreenState();
}

class _GoiYScreenState extends ConsumerState<GoiYScreen> {
  List<Track> _songs = [];
  String? _rationale;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRecommendations);
  }

  Future<void> _loadRecommendations() async {
    final currentEmotion = ref.read(musicPlayerProvider).currentEmotion;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(recommendationRepositoryProvider);

      final result = await repository.getPersonalRecommendations(
        limit: 24,
        emotion: currentEmotion,
      );

      if (!mounted) return;

      setState(() {
        _songs = result.tracks;
        _rationale = result.rationale;
      });
    } catch (_) {
      try {
        final repository = ref.read(recommendationRepositoryProvider);
        final fallbackSongs = await repository.getFallbackTracks();

        if (!mounted) return;

        setState(() {
          _songs = fallbackSongs;
          _rationale = null;
          _errorMessage =
              'Chưa thể tải gợi ý cá nhân hóa. Đang hiển thị thư viện bài hát.';
        });
      } catch (songsError) {
        if (!mounted) return;

        setState(() {
          _songs = [];
          _rationale = null;
          _errorMessage = songsError.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playTrack(Track track) {
    ref.read(musicPlayerProvider.notifier).playTrack(track, queue: _songs);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      musicPlayerProvider.select((state) => state.currentEmotion),
      (previous, next) {
        if (previous != null && previous != next) {
          _loadRecommendations();
        }
      },
    );

    final currentEmotion = ref.watch(musicPlayerProvider).currentEmotion;

    return Material(
      color: const Color(0xff05070d),
      child: RefreshIndicator(
        color: const Color(0xff22d3ee),
        backgroundColor: const Color(0xff0b1020),
        onRefresh: _loadRecommendations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RecommendationHero(
                    currentEmotion: currentEmotion,
                    onRefresh: _loadRecommendations,
                  ),
                  if (_rationale != null && _rationale!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoBox(
                      icon: Icons.auto_awesome_rounded,
                      message: _rationale!,
                      color: const Color(0xff22d3ee),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _InfoBox(
                      icon: Icons.warning_amber_rounded,
                      message: _errorMessage!,
                      color: Colors.amberAccent,
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const _RecommendationLoadingBox()
                  else if (_songs.isEmpty)
                    const _EmptyRecommendationBox()
                  else
                    _RecommendationGrid(songs: _songs, onPlay: _playTrack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationHero extends StatelessWidget {
  const _RecommendationHero({
    required this.currentEmotion,
    required this.onRefresh,
  });

  final String currentEmotion;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffa78bfa).withOpacity(0.18),
            const Color(0xff070b12),
            const Color(0xff22d3ee).withOpacity(0.10),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderPill(
                icon: Icons.psychology_rounded,
                label: 'Cá nhân hóa theo tài khoản',
              ),
              const SizedBox(height: 16),
              const Text(
                'Gợi ý dành riêng cho cậu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hệ thống ưu tiên bài hát dựa trên lịch sử nghe, thời lượng nghe, mood gần đây, like/skip và gu nghệ sĩ của tài khoản hiện tại.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MoodChip(label: 'Mood hiện tại: $currentEmotion'),
                  const _MoodChip(label: 'Nguồn: goiY'),
                  const _MoodChip(label: 'Limit: 24 bài'),
                ],
              ),
            ],
          );

          final refreshButton = FilledButton.icon(
            onPressed: onRefresh,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Tạo lại gợi ý',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: title),
                const SizedBox(width: 18),
                refreshButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 18), refreshButton],
          );
        },
      ),
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  const _RecommendationGrid({required this.songs, required this.onPlay});

  final List<Track> songs;
  final ValueChanged<Track> onPlay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1050
            ? 4
            : width >= 780
            ? 3
            : width >= 520
            ? 2
            : 1;

        return GridView.builder(
          itemCount: songs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 1.85 : 0.78,
          ),
          itemBuilder: (context, index) {
            return _RecommendationCard(
              track: songs[index],
              index: index,
              onPlay: () => onPlay(songs[index]),
            );
          },
        );
      },
    );
  }
}

class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({
    required this.track,
    required this.index,
    required this.onPlay,
  });

  final Track track;
  final int index;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = ref.watch(trackRepositoryProvider).getCoverUrl(track);
    final likedIds = ref.watch(likedTracksProvider);
    final isLiked = likedIds.contains(track.id);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onPlay,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: coverUrl.isEmpty
                          ? _FallbackCover(track: track)
                          : CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) {
                                return _FallbackCover(track: track);
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.46),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.42),
                        foregroundColor: isLiked
                            ? Colors.redAccent
                            : Colors.white,
                      ),
                      onPressed: () {
                        ref
                            .read(likedTracksProvider.notifier)
                            .toggleLike(track.id);
                      },
                      icon: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        fixedSize: const Size(50, 50),
                      ),
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.46),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MoodBadge(
                          label: track.moodText,
                          color: track.palette.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDuration(track.duration),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            track.palette.primary.withOpacity(0.85),
            track.palette.secondary.withOpacity(0.72),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationLoadingBox extends StatelessWidget {
  const _RecommendationLoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Đang tạo gợi ý theo lịch sử nghe của bạn...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecommendationBox extends StatelessWidget {
  const _EmptyRecommendationBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Center(
        child: Text(
          'Chưa có bài hát nào để gợi ý. Hãy thêm bài hát trong trang quản lý bài hát trước.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.54), height: 1.5),
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.68),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withOpacity(0.72),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.76), size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );
  }
}
