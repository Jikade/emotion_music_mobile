import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/song_card.dart';
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
                    _RecommendationGrid(songs: _songs),
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
              Text(
                'Gợi ý dành riêng cho cậu',
                maxLines: isWide ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 42 : 31,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hệ thống ưu tiên bài hát dựa trên lịch sử nghe, thời lượng nghe, mood gần đây, like/skip và gu nghệ sĩ của tài khoản hiện tại.',
                maxLines: isWide ? 4 : 6,
                overflow: TextOverflow.ellipsis,
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
  const _RecommendationGrid({required this.songs});

  final List<Track> songs;

  int _crossAxisCount(double width) {
    if (width >= 1100) return 5;
    if (width >= 850) return 4;
    if (width >= 620) return 3;
    if (width >= 420) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _crossAxisCount(constraints.maxWidth);

        return GridView.builder(
          itemCount: songs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            return SongCard(track: songs[index], queue: songs);
          },
        );
      },
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
              textAlign: TextAlign.center,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withOpacity(0.68),
          fontSize: 12,
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
      constraints: const BoxConstraints(maxWidth: double.infinity),
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.66),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
