import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/providers.dart';

class EmotionDetectScreen extends ConsumerStatefulWidget {
  const EmotionDetectScreen({super.key});

  @override
  ConsumerState<EmotionDetectScreen> createState() =>
      _EmotionDetectScreenState();
}

class _EmotionDetectScreenState extends ConsumerState<EmotionDetectScreen> {
  final _controller = TextEditingController();
  final _speech = SpeechToText();

  bool _listening = false;
  bool _loading = false;
  String? _result;

  Future<void> _toggleSpeech() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) return;

    setState(() => _listening = true);

    await _speech.listen(
      localeId: 'vi_VN',
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _detect() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final repo = ref.read(emotionRepositoryProvider);
      final data = await repo.detectTextEmotion(text);

      setState(() {
        _result = data.toString();
      });
    } catch (e) {
      setState(() {
        _result = 'Lỗi nhận diện: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhận diện cảm xúc')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Nhập hoặc ghi âm cảm xúc của bạn',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toggleSpeech,
                  icon: Icon(_listening ? Icons.stop : Icons.mic),
                  label: Text(_listening ? 'Dừng ghi âm' : 'Ghi âm'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _detect,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Nhận diện'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_result != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_result!),
              ),
            ),
        ],
      ),
    );
  }
}
