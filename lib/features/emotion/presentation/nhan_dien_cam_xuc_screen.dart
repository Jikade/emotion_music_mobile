import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/models/track.dart';
import '../../music/providers/music_providers.dart';
import '../data/emotion_repository.dart';
import '../providers/emotion_providers.dart';

class NhanDienCamXucScreen extends ConsumerStatefulWidget {
  const NhanDienCamXucScreen({super.key});

  @override
  ConsumerState<NhanDienCamXucScreen> createState() =>
      _NhanDienCamXucScreenState();
}

class _NhanDienCamXucScreenState extends ConsumerState<NhanDienCamXucScreen> {
  final _textController = TextEditingController(
    text: 'vui vẻ hạnh phúc quá nhưng cũng cảm thấy hơi cô đơn và buồn chán',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    await ref.read(emotionDetectProvider.notifier).detect(_textController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emotionDetectProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nhận diện cảm xúc')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'AI cảm xúc',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tìm nhạc theo tâm trạng của cậu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nhập cảm xúc bằng tiếng Việt hoặc tiếng Anh. Hệ thống sẽ phân tích local trước, sau đó gọi backend để lấy đề xuất.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Bạn đang cảm thấy thế nào?',
              hintText: 'Ví dụ: Hôm nay vui nhưng hơi cô đơn...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _detect,
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              state.isLoading ? 'Đang phân tích...' : 'Nhận diện cảm xúc',
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 18),
            _ErrorCard(message: state.errorMessage!),
          ],
          if (state.result != null) ...[
            const SizedBox(height: 24),
            _EmotionResultCard(result: state.result!),
            const SizedBox(height: 24),
            _RecommendedTracks(result: state.result!),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmotionResultCard extends StatelessWidget {
  const _EmotionResultCard({required this.result});

  final EmotionDetectResult result;

  @override
  Widget build(BuildContext context) {
    final label =
        EmotionRepository.labels[result.emotion]?['vi'] ?? result.emotion;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết quả cảm xúc',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$label • ${result.confidencePercent}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (result.rationale != null) ...[
            const SizedBox(height: 8),
            Text(
              result.rationale!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...NlpEmotion.values.map((emotion) {
            final value = result.probabilities[emotion] ?? 0;
            final emotionLabel =
                EmotionRepository.labels[emotion]?['vi'] ?? emotion;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProbabilityBar(label: emotionLabel, value: value),
            );
          }),
        ],
      ),
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  const _ProbabilityBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.08),
          ),
        ),
      ],
    );
  }
}

class _RecommendedTracks extends ConsumerWidget {
  const _RecommendedTracks({required this.result});

  final EmotionDetectResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = result.recommendedSongs;
    final queue = recommendations.map((item) => item.track).toList();

    if (recommendations.isEmpty) {
      return Text(
        'Chưa có bài hát đề xuất.',
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bài hát đề xuất',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((item) {
          return _RecommendedTrackTile(item: item, queue: queue);
        }),
      ],
    );
  }
}

class _RecommendedTrackTile extends ConsumerWidget {
  const _RecommendedTrackTile({required this.item, required this.queue});

  final RecommendedTrack item;
  final List<Track> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = item.track;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: track.palette.primary.withOpacity(0.9),
          child: const Icon(Icons.music_note, color: Colors.white),
        ),
        title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${track.artist} • ${track.moodText} • ${item.recommendationScore.round()}%',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton.filled(
          onPressed: () {
            ref
                .read(musicPlayerProvider.notifier)
                .playTrack(track, queue: queue);
          },
          icon: const Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}
