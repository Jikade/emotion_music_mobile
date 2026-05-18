import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/music/models/track.dart';
import '../../features/music/providers/music_providers.dart';

Future<void> showQueueDrawer(BuildContext context, WidgetRef ref) {
  final playerState = ref.read(musicPlayerProvider);
  final queue = playerState.queue;
  final nowPlaying = playerState.nowPlaying;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xff070b12),
    barrierColor: Colors.black.withOpacity(0.65),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.38,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            if (queue.isEmpty) {
              return Center(
                child: Text(
                  'Hàng đợi đang trống.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    'Hàng đợi phát',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                    itemCount: queue.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      final isCurrent = nowPlaying?.id == track.id;

                      return _QueueTrackTile(
                        track: track,
                        queue: queue,
                        isCurrent: isCurrent,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _QueueTrackTile extends ConsumerWidget {
  const _QueueTrackTile({
    required this.track,
    required this.queue,
    required this.isCurrent,
  });

  final Track track;
  final List<Track> queue;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: isCurrent
          ? Colors.white.withOpacity(0.10)
          : Colors.white.withOpacity(0.045),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          backgroundColor: track.palette.primary.withOpacity(0.95),
          child: Icon(
            isCurrent ? Icons.graphic_eq : Icons.music_note,
            color: Colors.white,
          ),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${track.artist} • ${track.moodText}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.55)),
        ),
        trailing: Icon(
          isCurrent ? Icons.pause_circle : Icons.play_circle,
          color: Colors.white.withOpacity(0.75),
        ),
        onTap: () {
          ref.read(musicPlayerProvider.notifier).playTrack(track, queue: queue);

          Navigator.of(context).pop();
        },
      ),
    );
  }
}
