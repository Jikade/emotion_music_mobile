import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/song_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bảng điều khiển')),
      body: tracksAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(child: Text('Chưa có bài hát trong hệ thống.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              return SongCard(track: tracks[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Lỗi tải bài hát: $error')),
      ),
    );
  }
}
