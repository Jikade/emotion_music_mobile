import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../features/music/models/track.dart';
import '../../features/music/providers/player_provider.dart';

class SongCard extends ConsumerWidget {
  const SongCard({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(trackRepositoryProvider);
    final coverUrl = repo.coverUrl(track);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: coverUrl.isEmpty
              ? const Icon(Icons.music_note, size: 44)
              : CachedNetworkImage(
                  imageUrl: coverUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
        ),
        title: Text(track.title),
        subtitle: Text(
          '${track.artist} • ${track.emotionLabelVi ?? track.emotion ?? ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            ref.read(musicPlayerProvider.notifier).play(track);
          },
        ),
      ),
    );
  }
}
