import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../features/music/models/track.dart';
import '../../features/music/providers/music_providers.dart';
import 'song_card.dart';

class SongGrid extends ConsumerStatefulWidget {
  const SongGrid({
    super.key,
    required this.emptyMessage,
    this.forceLikedOnly = false,
  });

  final String emptyMessage;
  final bool forceLikedOnly;

  @override
  ConsumerState<SongGrid> createState() => _SongGridState();
}

class _SongGridState extends ConsumerState<SongGrid> {
  final _searchController = TextEditingController();

  String _query = '';
  String _selectedMood = 'Tất cả';
  bool _likedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _buildMoods(List<Track> tracks) {
    final moods = tracks
        .map((track) => track.moodText)
        .where((mood) => mood.trim().isNotEmpty)
        .toSet()
        .toList();

    moods.sort();

    return ['Tất cả', ...moods];
  }

  List<Track> _filterTracks({
    required List<Track> tracks,
    required Set<int> likedIds,
  }) {
    final query = normalizeText(_query);
    final shouldShowLikedOnly = widget.forceLikedOnly || _likedOnly;

    return tracks.where((track) {
      final text = normalizeText(
        '${track.title} ${track.artist} ${track.moodText}',
      );

      final matchesQuery = query.isEmpty || text.contains(query);
      final matchesMood =
          _selectedMood == 'Tất cả' || track.moodText == _selectedMood;
      final matchesLiked = !shouldShowLikedOnly || likedIds.contains(track.id);

      return matchesQuery && matchesMood && matchesLiked;
    }).toList();
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 5;
    if (width >= 850) return 4;
    if (width >= 620) return 3;
    if (width >= 420) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);
    final likedIds = ref.watch(likedTracksProvider);

    return tracksAsync.when(
      data: (tracks) {
        final moods = _buildMoods(tracks);
        final filteredTracks = _filterTracks(
          tracks: tracks,
          likedIds: likedIds,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _query = value);
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm bài hát, nghệ sĩ hoặc mood...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: moods.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(width: 8);
                      },
                      itemBuilder: (context, index) {
                        final mood = moods[index];
                        final selected = mood == _selectedMood;

                        return ChoiceChip(
                          label: Text(mood),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedMood = mood);
                          },
                        );
                      },
                    ),
                  ),
                  if (!widget.forceLikedOnly) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _likedOnly,
                      onChanged: (value) {
                        setState(() => _likedOnly = value);
                      },
                      title: const Text('Chỉ xem bài đã thích'),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: filteredTracks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          widget.emptyMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _crossAxisCount(
                                  constraints.maxWidth,
                                ),
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.68,
                              ),
                          itemCount: filteredTracks.length,
                          itemBuilder: (context, index) {
                            return SongCard(
                              track: filteredTracks[index],
                              queue: filteredTracks,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              'Lỗi tải danh sách bài hát:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
      },
    );
  }
}
