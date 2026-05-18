import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../music/models/track.dart';
import '../../music/providers/music_providers.dart';
import '../data/history_repository.dart';
import '../providers/history_providers.dart';

class LichSuScreen extends ConsumerStatefulWidget {
  const LichSuScreen({super.key});

  @override
  ConsumerState<LichSuScreen> createState() => _LichSuScreenState();
}

class _LichSuScreenState extends ConsumerState<LichSuScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<ListeningHistoryItem> _records = [];
  bool _isLoading = true;
  bool _isClearing = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(historyRepositoryProvider);
      final data = await repository.getListeningHistory(limit: 100);

      if (!mounted) return;

      setState(() {
        _records = data;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff0b1020),
          title: const Text(
            'Xoá lịch sử nghe?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Bạn có chắc muốn xoá toàn bộ lịch sử nghe của tài khoản này không?',
            style: TextStyle(color: Colors.white.withOpacity(0.68)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xoá'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _errorMessage = null;
    });

    try {
      await ref.read(historyRepositoryProvider).clearListeningHistory();

      if (!mounted) return;

      setState(() {
        _records = [];
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isClearing = false;
      });
    }
  }

  void _playRecord(ListeningHistoryItem record) {
    final queue = _records.map((item) => item.track).toList();

    ref
        .read(musicPlayerProvider.notifier)
        .playTrack(record.track, queue: queue);
  }

  List<ListeningHistoryItem> get _filteredRecords {
    final keyword = _searchQuery.trim().toLowerCase();

    if (keyword.isEmpty) return _records;

    return _records.where((record) {
      final title = record.track.title.toLowerCase();
      final artist = record.track.artist.toLowerCase();

      return title.contains(keyword) || artist.contains(keyword);
    }).toList();
  }

  Map<String, List<ListeningHistoryItem>> get _groupedRecords {
    final groups = <String, List<ListeningHistoryItem>>{};

    for (final record in _filteredRecords) {
      final label = _groupLabel(record.createdAt);
      final current = groups[label] ?? <ListeningHistoryItem>[];

      current.add(record);
      groups[label] = current;
    }

    return groups;
  }

  int get _uniqueTrackCount {
    return _records.map((item) => item.trackId).toSet().length;
  }

  int get _totalMinutes {
    final totalMs = _records.fold<int>(0, (sum, item) => sum + item.listenMs);

    return (totalMs / 60000).round();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _filteredRecords;
    final groupedRecords = _groupedRecords;

    return Material(
      color: const Color(0xff05070d),
      child: RefreshIndicator(
        color: const Color(0xff22d3ee),
        backgroundColor: const Color(0xff0b1020),
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HistoryHero(
                    playCount: _records.length,
                    uniqueTrackCount: _uniqueTrackCount,
                    totalMinutes: _totalMinutes,
                    isClearing: _isClearing,
                    canClear: _records.isNotEmpty,
                    onClear: _clearHistory,
                  ),
                  const SizedBox(height: 18),
                  _Toolbar(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onRefresh: _loadHistory,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBox(message: _errorMessage!),
                  ],
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const _LoadingBox()
                  else if (filteredRecords.isEmpty)
                    const _EmptyHistoryBox()
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: groupedRecords.entries.map((entry) {
                        return _HistoryGroup(
                          title: entry.key,
                          records: entry.value,
                          onPlay: _playRecord,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Hôm nay';
    if (diffDays == 1) return 'Hôm qua';
    if (diffDays < 7) return 'Tuần này';

    return '${target.day.toString().padLeft(2, '0')}/'
        '${target.month.toString().padLeft(2, '0')}/'
        '${target.year}';
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({
    required this.playCount,
    required this.uniqueTrackCount,
    required this.totalMinutes,
    required this.isClearing,
    required this.canClear,
    required this.onClear,
  });

  final int playCount;
  final int uniqueTrackCount;
  final int totalMinutes;
  final bool isClearing;
  final bool canClear;
  final VoidCallback onClear;

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
            const Color(0xff22d3ee).withOpacity(0.16),
            const Color(0xff070b12),
            const Color(0xffa78bfa).withOpacity(0.12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;

              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderPill(
                    icon: Icons.history_rounded,
                    label: 'Listening Archive',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lịch sử nghe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mỗi tài khoản có một lịch sử riêng, được lưu trong database và tự cập nhật khi bạn nghe nhạc.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              );

              final clearButton = FilledButton.icon(
                onPressed: canClear && !isClearing ? onClear : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.16),
                  foregroundColor: Colors.redAccent.shade100,
                  disabledBackgroundColor: Colors.white.withOpacity(0.08),
                  disabledForegroundColor: Colors.white.withOpacity(0.34),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.22)),
                  ),
                ),
                icon: isClearing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.redAccent,
                        ),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  'Xoá lịch sử',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 18),
                    clearButton,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 18), clearButton],
              );
            },
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;

              final cards = [
                _StatCard(label: 'Lượt nghe', value: '$playCount'),
                _StatCard(label: 'Bài khác nhau', value: '$uniqueTrackCount'),
                _StatCard(label: 'Phút đã lưu', value: '$totalMinutes'),
              ];

              if (isWide) {
                return Row(
                  children: cards
                      .map(
                        (card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: card,
                          ),
                        ),
                      )
                      .toList(),
                );
              }

              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.onChanged,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;

        final search = TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withOpacity(0.34),
            ),
            hintText: 'Tìm theo tên bài hát hoặc ca sĩ...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.28)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.045),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.30)),
            ),
          ),
        );

        final refresh = OutlinedButton.icon(
          onPressed: onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.78),
            side: BorderSide(color: Colors.white.withOpacity(0.10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(
            'Tải lại',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              refresh,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [search, const SizedBox(height: 12), refresh],
        );
      },
    );
  }
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({
    required this.title,
    required this.records,
    required this.onPlay,
  });

  final String title;
  final List<ListeningHistoryItem> records;
  final ValueChanged<ListeningHistoryItem> onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.34),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.36),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...records.map((record) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryRecordCard(
                record: record,
                onPlay: () => onPlay(record),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HistoryRecordCard extends ConsumerWidget {
  const _HistoryRecordCard({required this.record, required this.onPlay});

  final ListeningHistoryItem record;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = record.track;
    final coverUrl = ref.watch(trackRepositoryProvider).getCoverUrl(track);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          _CoverImage(track: track, coverUrl: coverUrl),
          const SizedBox(width: 13),
          Expanded(
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
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SmallBadge(
                      label: track.moodText,
                      color: track.palette.primary,
                    ),
                    Text(
                      _formatTime(record.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.36),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatDuration(track.duration),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.36),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Phát lại',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              fixedSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.track, required this.coverUrl});

  final Track track;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: track.palette.primary.withOpacity(0.85),
      child: const Icon(Icons.music_note_rounded, color: Colors.white),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.72),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.36),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
        ],
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.26)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyHistoryBox extends StatelessWidget {
  const _EmptyHistoryBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              color: Colors.white.withOpacity(0.24),
              size: 44,
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có lịch sử nghe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy phát một bài hát ít nhất 5 giây, hệ thống sẽ tự lưu vào database cho tài khoản hiện tại.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.46),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
