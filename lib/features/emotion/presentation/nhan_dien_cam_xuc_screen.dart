import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/utils/formatters.dart';
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
  static const _examplePrompts = [
    'Tôi cảm thấy rất cô đơn và mệt mỏi, chỉ muốn nghe một bài hát nhẹ nhàng.',
    'Hôm nay tôi vui quá, mọi thứ đều rất tuyệt và tôi muốn nghe nhạc tích cực.',
    'Tôi đang rất bực mình và khó chịu, cần nhạc để giải tỏa năng lượng.',
    'Tôi muốn thư giãn sau một ngày dài, tâm trí cần bình yên hơn.',
  ];

  final TextEditingController _textController = TextEditingController(
    text: _examplePrompts.first,
  );

  final SpeechToText _speech = SpeechToText();

  EmotionDetectResult? _result;
  String? _errorMessage;

  bool _speechSupported = false;
  bool _isListening = false;
  bool _isAnalyzing = false;

  String _speechStatus =
      'Bấm micro để đọc cảm xúc bằng tiếng Việt và tự điền vào ô văn bản.';
  String? _speechLocaleId;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speech.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
      );

      if (!mounted) return;

      if (!available) {
        setState(() {
          _speechSupported = false;
          _speechStatus =
              'Thiết bị hoặc trình duyệt hiện tại chưa hỗ trợ nhận diện giọng nói.';
        });
        return;
      }

      final locales = await _speech.locales();

      final viLocale = locales.cast<dynamic>().firstWhere(
        (locale) => locale.localeId.toString().toLowerCase().startsWith('vi'),
        orElse: () => null,
      );

      setState(() {
        _speechSupported = true;
        _speechLocaleId = viLocale?.localeId?.toString() ?? 'vi_VN';
        _speechStatus =
            'Bấm micro để đọc cảm xúc bằng tiếng Việt và tự điền vào ô văn bản.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _speechSupported = false;
        _speechStatus =
            'Không thể khởi tạo nhận diện giọng nói. Hãy thử Chrome, Edge hoặc thiết bị có microphone.';
      });
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;

    final normalized = status.toLowerCase();

    setState(() {
      if (normalized.contains('listening')) {
        _isListening = true;
        _speechStatus = 'Đang nghe... hãy nói cảm xúc của bạn bằng tiếng Việt.';
      } else if (normalized.contains('notlistening') ||
          normalized.contains('done')) {
        _isListening = false;
        _speechStatus =
            'Đã dừng ghi âm. Bạn có thể chỉnh lại văn bản hoặc bấm phân tích.';
      }
    });
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;

    final message = _speechErrorMessage(error.errorMsg);

    setState(() {
      _isListening = false;
      _speechStatus = message;
      _errorMessage = message;
    });
  }

  String _speechErrorMessage(String raw) {
    final value = raw.toLowerCase();

    if (value.contains('not_allowed') || value.contains('permission')) {
      return 'Bạn chưa cấp quyền microphone. Hãy cho phép app dùng microphone rồi thử lại.';
    }

    if (value.contains('no_speech') || value.contains('no-speech')) {
      return 'Chưa nghe thấy giọng nói. Hãy thử nói gần microphone hơn.';
    }

    if (value.contains('audio') || value.contains('capture')) {
      return 'Không tìm thấy microphone hoặc microphone đang bị ứng dụng khác sử dụng.';
    }

    if (value.contains('network')) {
      return 'Không thể kết nối dịch vụ nhận diện giọng nói. Vui lòng kiểm tra mạng.';
    }

    return 'Không thể nhận diện giọng nói ($raw).';
  }

  Future<void> _toggleListening() async {
    if (!_speechSupported) {
      setState(() {
        _speechStatus =
            'Trình duyệt hoặc thiết bị hiện tại chưa hỗ trợ ghi âm chuyển thành văn bản.';
        _errorMessage = _speechStatus;
      });
      return;
    }

    if (_isListening) {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
        _speechStatus =
            'Đã dừng ghi âm. Bạn có thể chỉnh lại văn bản hoặc bấm phân tích.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isListening = true;
      _speechStatus = 'Đang xin quyền microphone...';
      _textController.clear();
    });

    try {
      await _speech.listen(
        localeId: _speechLocaleId ?? 'vi_VN',
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        ),
        onResult: (result) {
          if (!mounted) return;

          final words = result.recognizedWords.trim();

          if (words.isEmpty) return;

          setState(() {
            _textController.text = words;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );

            _speechStatus = result.finalResult
                ? 'Đã nhận diện xong một đoạn. Bạn có thể nói tiếp hoặc dừng ghi âm.'
                : 'Đang nhận diện tạm thời...';
          });
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isListening = false;
        _speechStatus =
            'Không thể bắt đầu ghi âm. Vui lòng kiểm tra quyền microphone và thử lại.';
        _errorMessage = _speechStatus;
      });
    }
  }

  void _selectExamplePrompt(String prompt) {
    if (_isListening) {
      _speech.stop();
    }

    setState(() {
      _isListening = false;
      _errorMessage = null;
      _speechStatus = 'Đã chọn ví dụ mẫu.';
      _textController.text = prompt;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  Future<void> _analyzeEmotion() async {
    if (_isListening) {
      await _speech.stop();
    }

    final cleanText = _textController.text.trim();

    if (cleanText.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập nội dung cảm xúc trước khi phân tích.';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _isListening = false;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(emotionRepositoryProvider);

      final data = await repository.detectTextEmotion(cleanText, limit: 9);

      if (!mounted) return;

      setState(() {
        _result = data;

        // Quan trọng:
        // Tắt loading ngay sau khi đã chẩn đoán xong cảm xúc.
        // Không chờ player phát nhạc xong.
        _isAnalyzing = false;
      });

      final autoSong = data.autoPlaySong;

      if (autoSong != null) {
        final queue = data.recommendedSongs.map((item) => item.track).toList();

        // Quan trọng:
        // Không await playTrack ở đây.
        // Nếu await, nút "Phân tích cảm xúc" sẽ loading tới khi nhạc pause/stop.
        unawaited(
          ref
              .read(musicPlayerProvider.notifier)
              .playTrack(autoSong.track, queue: queue),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final detectedEmotion = result?.emotion ?? NlpEmotion.relaxed;
    final confidencePercent = result?.confidencePercent ?? 75;
    final probabilities = result?.probabilities ?? _defaultProbabilities;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroSection(
                emotion: detectedEmotion,
                confidencePercent: confidencePercent,
                hasResult: result != null,
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 10,
                          child: _InputSection(
                            controller: _textController,
                            isListening: _isListening,
                            isAnalyzing: _isAnalyzing,
                            speechSupported: _speechSupported,
                            speechStatus: _speechStatus,
                            errorMessage: _errorMessage,
                            examplePrompts: _examplePrompts,
                            onToggleListening: _toggleListening,
                            onAnalyze: _analyzeEmotion,
                            onExampleSelected: _selectExamplePrompt,
                            onTextChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 11,
                          child: _ResultSection(
                            result: result,
                            emotion: detectedEmotion,
                            probabilities: probabilities,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _InputSection(
                        controller: _textController,
                        isListening: _isListening,
                        isAnalyzing: _isAnalyzing,
                        speechSupported: _speechSupported,
                        speechStatus: _speechStatus,
                        errorMessage: _errorMessage,
                        examplePrompts: _examplePrompts,
                        onToggleListening: _toggleListening,
                        onAnalyze: _analyzeEmotion,
                        onExampleSelected: _selectExamplePrompt,
                        onTextChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      _ResultSection(
                        result: result,
                        emotion: detectedEmotion,
                        probabilities: probabilities,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              _RecommendationSection(result: result),
            ],
          ),
        ),
      ),
    );
  }

  Map<NlpEmotion, double> get _defaultProbabilities {
    return {
      NlpEmotion.happy: 0.25,
      NlpEmotion.sad: 0.25,
      NlpEmotion.angry: 0.25,
      NlpEmotion.relaxed: 0.25,
    };
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.emotion,
    required this.confidencePercent,
    required this.hasResult,
  });

  final NlpEmotion emotion;
  final int confidencePercent;
  final bool hasResult;

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
            _emotionColor(emotion).withOpacity(0.22),
            const Color(0xff070b12),
            const Color(0xff0891b2).withOpacity(0.10),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 46,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: _BlurCircle(
              color: _emotionColor(emotion).withOpacity(0.28),
              size: 180,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SmallPill(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Emotion AI / NLP tiếng Việt',
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Nhận diện cảm xúc từ văn bản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nhập vài câu mô tả tâm trạng. Backend sẽ dự đoán cảm xúc, lọc bài hát theo mood trong database và tự động phát bài phù hợp nhất.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 245,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasResult ? 'Cảm xúc hiện tại' : 'Cảm xúc mặc định',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _EmotionBadge(emotion: emotion, large: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            emotion.labelVi,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Độ tin cậy',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$confidencePercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.controller,
    required this.isListening,
    required this.isAnalyzing,
    required this.speechSupported,
    required this.speechStatus,
    required this.errorMessage,
    required this.examplePrompts,
    required this.onToggleListening,
    required this.onAnalyze,
    required this.onExampleSelected,
    required this.onTextChanged,
  });

  final TextEditingController controller;
  final bool isListening;
  final bool isAnalyzing;
  final bool speechSupported;
  final String speechStatus;
  final String? errorMessage;
  final List<String> examplePrompts;
  final VoidCallback onToggleListening;
  final VoidCallback onAnalyze;
  final ValueChanged<String> onExampleSelected;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.psychology_alt_rounded,
            title: 'Văn bản đầu vào',
            subtitle: 'Hỗ trợ tiếng Việt có dấu hoặc không dấu.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 8,
            minLines: 8,
            onChanged: onTextChanged,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.55,
            ),
            decoration: InputDecoration(
              hintText:
                  'Ví dụ: Tôi cảm thấy rất cô đơn và mệt mỏi, chỉ muốn nghe một bài hát nhẹ nhàng...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.32)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: Color(0xff67e8f9)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SpeechBox(
            isListening: isListening,
            isAnalyzing: isAnalyzing,
            speechSupported: speechSupported,
            speechStatus: speechStatus,
            onToggleListening: onToggleListening,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: examplePrompts.map((prompt) {
              return ActionChip(
                onPressed: () => onExampleSelected(prompt),
                label: Text(
                  prompt.length > 42 ? '${prompt.substring(0, 42)}...' : prompt,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.white.withOpacity(0.05),
                side: BorderSide(color: Colors.white.withOpacity(0.10)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(),
          ),
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.28)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: isAnalyzing || isListening ? null : onAnalyze,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff67e8f9),
                foregroundColor: const Color(0xff020617),
                disabledBackgroundColor: Colors.white.withOpacity(0.14),
                disabledForegroundColor: Colors.white.withOpacity(0.42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xff020617),
                      ),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: Text(
                isListening
                    ? 'Dừng ghi âm trước khi phân tích'
                    : isAnalyzing
                    ? 'AI đang phân tích...'
                    : 'Phân tích cảm xúc',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBox extends StatelessWidget {
  const _SpeechBox({
    required this.isListening,
    required this.isAnalyzing,
    required this.speechSupported,
    required this.speechStatus,
    required this.onToggleListening,
  });

  final bool isListening;
  final bool isAnalyzing;
  final bool speechSupported;
  final String speechStatus;
  final VoidCallback onToggleListening;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isListening
                      ? Colors.redAccent.withOpacity(0.15)
                      : const Color(0xff22d3ee).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isListening
                        ? Colors.redAccent.withOpacity(0.28)
                        : const Color(0xff22d3ee).withOpacity(0.28),
                  ),
                ),
                child: Icon(
                  isListening ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                  color: isListening
                      ? Colors.redAccent
                      : const Color(0xffa5f3fc),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi âm giọng nói',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Ngôn ngữ nhận diện: Tiếng Việt — vi-VN',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: !speechSupported || isAnalyzing
                    ? null
                    : onToggleListening,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isListening
                      ? Colors.redAccent
                      : const Color(0xffa5f3fc),
                  side: BorderSide(
                    color: isListening
                        ? Colors.redAccent.withOpacity(0.34)
                        : const Color(0xff22d3ee).withOpacity(0.34),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  isListening ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                  size: 18,
                ),
                label: Text(
                  isListening ? 'Dừng ghi âm' : 'Bắt đầu ghi âm',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              speechStatus,
              style: TextStyle(
                color: isListening
                    ? const Color(0xffcffafe)
                    : Colors.white.withOpacity(0.55),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          if (isListening) ...[const SizedBox(height: 12), const _WaveBars()],
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.result,
    required this.emotion,
    required this.probabilities,
  });

  final EmotionDetectResult? result;
  final NlpEmotion emotion;
  final Map<NlpEmotion, double> probabilities;

  @override
  Widget build(BuildContext context) {
    final rows = NlpEmotion.values;

    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.analytics_rounded,
            title: 'Kết quả NLP',
            subtitle: 'Xác suất từng cảm xúc được chuẩn hóa về 100%.',
            trailing: result == null ? null : _EmotionBadge(emotion: emotion),
          ),
          const SizedBox(height: 18),
          ...rows.map((item) {
            final value = probabilities[item] ?? 0;
            final percent = (value * 100).round();
            final isTop = result?.emotion == item;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProbabilityTile(
                emotion: item,
                percent: percent,
                isTop: isTop,
              ),
            );
          }),
          if (result?.rationale != null &&
              result!.rationale!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.22),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                result!.rationale!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  height: 1.55,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.result});

  final EmotionDetectResult? result;

  @override
  Widget build(BuildContext context) {
    final songs = result?.recommendedSongs ?? const <RecommendedTrack>[];
    final topSong = result?.autoPlaySong;

    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.music_note_rounded,
                  title: 'Bài hát đề xuất',
                  subtitle:
                      'Bài có điểm cao nhất sẽ được đưa vào player và phát tự động.',
                  eyebrow: 'Recommendation',
                ),
              ),
              if (topSong != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff34d399).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xff34d399).withOpacity(0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: const Color(0xff34d399),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-play: ${topSong.track.title}',
                        style: const TextStyle(
                          color: const Color(0xff34d399),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (songs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.16),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                'Nhập văn bản và bấm “Phân tích cảm xúc” để nhận danh sách bài hát phù hợp.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  height: 1.5,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 980
                    ? 3
                    : width >= 650
                    ? 2
                    : 1;

                return GridView.builder(
                  itemCount: songs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: crossAxisCount == 1 ? 2.85 : 1.75,
                  ),
                  itemBuilder: (context, index) {
                    return _RecommendationCard(
                      item: songs[index],
                      queue: songs.map((item) => item.track).toList(),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({required this.item, required this.queue});

  final RecommendedTrack item;
  final List<Track> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = item.track;
    final coverUrl = ref.watch(trackRepositoryProvider).getCoverUrl(track);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        ref.read(musicPlayerProvider.notifier).playTrack(track, queue: queue);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              height: 78,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: coverUrl.isEmpty
                    ? Container(
                        color: track.palette.primary.withOpacity(0.75),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return Container(
                            color: track.palette.primary.withOpacity(0.75),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mood DB: ${item.moodText}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.48),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${item.recommendationScore.round()}%',
                        style: const TextStyle(
                          color: Color(0xffa5f3fc),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityTile extends StatelessWidget {
  const _ProbabilityTile({
    required this.emotion,
    required this.percent,
    required this.isTop,
  });

  final NlpEmotion emotion;
  final int percent;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final color = _emotionColor(emotion);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop ? color.withOpacity(0.14) : Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTop
              ? color.withOpacity(0.38)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  emotion.labelVi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.eyebrow,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xff22d3ee).withOpacity(0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: const Color(0xffa5f3fc)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: const TextStyle(
                    color: Color(0xffa5f3fc),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.6,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.56),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.84), size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionBadge extends StatelessWidget {
  const _EmotionBadge({required this.emotion, this.large = false});

  final NlpEmotion emotion;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = _emotionColor(emotion);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 9 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_emotionIcon(emotion), color: color, size: large ? 20 : 16),
          const SizedBox(width: 7),
          Text(
            emotion.labelVi,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(18, (index) {
          final height = 10 + ((index % 6) + 1) * 4.0;

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.45, end: 1),
              duration: Duration(milliseconds: 520 + index * 18),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  width: 5,
                  height: height * value,
                  decoration: BoxDecoration(
                    color: const Color(0xffa5f3fc).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

Color _emotionColor(NlpEmotion emotion) {
  switch (emotion) {
    case NlpEmotion.happy:
      return const Color(0xffffd166);
    case NlpEmotion.sad:
      return const Color(0xff60a5fa);
    case NlpEmotion.angry:
      return const Color(0xfffb7185);
    case NlpEmotion.relaxed:
      return const Color(0xff34d399);
  }
}

IconData _emotionIcon(NlpEmotion emotion) {
  switch (emotion) {
    case NlpEmotion.happy:
      return Icons.sentiment_very_satisfied_rounded;
    case NlpEmotion.sad:
      return Icons.sentiment_dissatisfied_rounded;
    case NlpEmotion.angry:
      return Icons.local_fire_department_rounded;
    case NlpEmotion.relaxed:
      return Icons.spa_rounded;
  }
}
