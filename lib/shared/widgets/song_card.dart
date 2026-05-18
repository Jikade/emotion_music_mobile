import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/music/models/track.dart';
import '../../features/music/providers/music_providers.dart';

class SongCard extends ConsumerWidget {
  const SongCard({super.key, required this.track, required this.queue});

  final Track track;
  final List<Track> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackRepository = ref.watch(trackRepositoryProvider);
    final likedIds = ref.watch(likedTracksProvider);
    final isLiked = likedIds.contains(track.id);

    final coverUrl = trackRepository.getCoverUrl(track);
    final palette = track.palette;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        ref.read(musicPlayerProvider.notifier).playTrack(track, queue: queue);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.045),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(0.08),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.primary.withOpacity(0.8),
                            palette.secondary.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 54,
                        color: Colors.white,
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                palette.primary.withOpacity(0.8),
                                palette.secondary.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            size: 54,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton.filledTonal(
                      onPressed: () {
                        ref
                            .read(likedTracksProvider.notifier)
                            .toggleLike(track.id);
                      },
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.pinkAccent : Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        ref
                            .read(musicPlayerProvider.notifier)
                            .playTrack(track, queue: queue);
                        context.go('/dangPhat');
                      },
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.52),
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  track.moodText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
