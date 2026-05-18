import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/music/providers/player_provider.dart';

class BottomPlayer extends ConsumerWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(musicPlayerProvider);
    final track = playerState.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              ref.read(musicPlayerProvider.notifier).toggle();
            },
          ),
        ],
      ),
    );
  }
}
