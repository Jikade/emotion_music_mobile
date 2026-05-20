import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../music/models/track.dart';
import '../../music/providers/music_providers.dart';
import '../data/music_bot_command.dart';

class AssistantMessage {
  final String id;
  final String role;
  final String content;

  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
  });
}

class AIAssistantPanel extends ConsumerStatefulWidget {
  const AIAssistantPanel({super.key});

  @override
  ConsumerState<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends ConsumerState<AIAssistantPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();

  bool _expanded = false;
  bool _speechReady = false;
  bool _isListening = false;

  String _speechLocaleId = 'vi_VN';
  String _interimTranscript = '';
  String? _speechError;

  List<AssistantMessage> _messages = const [
    AssistantMessage(
      id: 'intro',
      role: 'assistant',
      content:
          'KhoaLisa AI sẵn sàng. Bạn có thể nhập hoặc nói để yêu cầu mình phát nhạc theo tên bài, mood, artist hoặc random.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeSpeech);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
      );

      if (!mounted) return;

      setState(() {
        _speechReady = available;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _speechReady = false;
        _speechError =
            'Trình duyệt này chưa hỗ trợ nhận diện giọng nói. Hãy thử Chrome hoặc Edge.';
      });
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;

    final value = status.toLowerCase();

    if (value.contains('listening')) {
      setState(() {
        _isListening = true;
      });
    }

    if (value.contains('notlistening') || value.contains('done')) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;

    setState(() {
      _isListening = false;
      _speechError = _speechErrorMessage(error.errorMsg);
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

    if (value.contains('network')) {
      return 'Không thể kết nối dịch vụ nhận diện giọng nói. Vui lòng kiểm tra mạng.';
    }

    return 'Không thể nhận diện giọng nói ($raw).';
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      setState(() {
        _speechError =
            'Trình duyệt hoặc thiết bị hiện tại chưa hỗ trợ nhận diện giọng nói.';
      });
      return;
    }

    if (_isListening) {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });
      return;
    }

    setState(() {
      _speechError = null;
      _interimTranscript = '';
      _isListening = true;
    });

    try {
      await _speech.listen(
        localeId: _speechLocaleId,
        partialResults: true,
        listenMode: ListenMode.dictation,
        onResult: (result) {
          final words = result.recognizedWords.trim();

          if (!mounted || words.isEmpty) return;

          setState(() {
            _interimTranscript = words;
            _inputController.text = words;
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputController.text.length),
            );
          });

          if (result.finalResult) {
            _respond(words);
            _inputController.clear();

            setState(() {
              _interimTranscript = '';
              _isListening = false;
            });
          }
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isListening = false;
        _speechError =
            'Không thể bắt đầu ghi âm. Hãy kiểm tra quyền microphone.';
      });
    }
  }

  void _toggleSpeechLocale() {
    setState(() {
      _speechLocaleId = _speechLocaleId == 'vi_VN' ? 'en_US' : 'vi_VN';
      _speechError = null;
      _interimTranscript = '';
    });
  }

  void _submit() {
    final text = _inputController.text.trim();

    if (text.isEmpty) return;

    _respond(text);
    _inputController.clear();
  }

  void _respond(String userInput) {
    final tracksAsync = ref.read(tracksProvider);

    final availableSongs = tracksAsync.maybeWhen<List<Track>>(
      data: (tracks) => tracks,
      orElse: () => const <Track>[],
    );

    final playerState = ref.read(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);

    var result = resolveBotMusicCommand(
      userInput,
      availableSongs,
      currentEmotion: playerState.currentEmotion,
      nowPlaying: playerState.nowPlaying,
    );

    if (availableSongs.isEmpty && result.type == BotCommandType.none) {
      result = const BotCommandResult(
        type: BotCommandType.none,
        reply:
            'Mình đang tải danh sách bài hát hoặc backend chưa trả dữ liệu. Hãy thử lại sau vài giây nhé.',
      );
    }

    if (result.type == BotCommandType.play && result.track != null) {
      unawaited(controller.playTrack(result.track!, queue: availableSongs));
    }

    if (result.type == BotCommandType.control) {
      final control = result.control;

      if (control == BotPlayerControl.pause && playerState.isPlaying) {
        unawaited(controller.togglePlayPause());
      }

      if (control == BotPlayerControl.resume && !playerState.isPlaying) {
        unawaited(controller.togglePlayPause());
      }

      if (control == BotPlayerControl.next) {
        unawaited(controller.playNext());
      }

      if (control == BotPlayerControl.previous) {
        unawaited(controller.playPrevious());
      }
    }

    if (result.type == BotCommandType.volume) {
      final volume = result.volume;

      if (volume != null) {
        unawaited(controller.setVolume(volume));
      }

      final muted = result.muted;

      if (muted != null) {
        unawaited(controller.setMuted(muted));
      }
    }

    _pushConversation(userInput, result.reply);
  }

  void _pushConversation(String userInput, String reply) {
    final nextMessages = [
      ..._messages,
      AssistantMessage(id: _makeId(), role: 'user', content: userInput),
      AssistantMessage(id: _makeId(), role: 'assistant', content: reply),
    ];

    setState(() {
      _messages = nextMessages.length > 14
          ? nextMessages.sublist(nextMessages.length - 14)
          : nextMessages;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _makeId() {
    return '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(999999)}';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(musicPlayerProvider);
    final tracksAsync = ref.watch(tracksProvider);

    final availableSongCount = tracksAsync.maybeWhen<int>(
      data: (tracks) => tracks.length,
      orElse: () => 0,
    );

    final isLoadingSongs = tracksAsync.isLoading;
    final nowPlaying = playerState.nowPlaying;

    return IgnorePointer(
      ignoring: false,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _expanded
                ? _AssistantPanel(
                    key: const ValueKey('assistant-panel'),
                    messages: _messages,
                    inputController: _inputController,
                    scrollController: _scrollController,
                    nowPlaying: nowPlaying,
                    isLoadingSongs: isLoadingSongs,
                    availableSongCount: availableSongCount,
                    isSpeechReady: _speechReady,
                    isListening: _isListening,
                    speechLocaleId: _speechLocaleId,
                    interimTranscript: _interimTranscript,
                    speechError: _speechError,
                    onClose: () {
                      setState(() {
                        _expanded = false;
                      });
                    },
                    onSubmit: _submit,
                    onToggleListening: _toggleListening,
                    onToggleSpeechLocale: _toggleSpeechLocale,
                    onQuickPrompt: _respond,
                  )
                : _AssistantOrb(
                    key: const ValueKey('assistant-orb'),
                    hasNowPlaying: nowPlaying != null,
                    onTap: () {
                      setState(() {
                        _expanded = true;
                      });
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _AssistantOrb extends StatelessWidget {
  const _AssistantOrb({
    super.key,
    required this.hasNowPlaying,
    required this.onTap,
  });

  final bool hasNowPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.42),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: hasNowPlaying ? 22 : 17,
                height: hasNowPlaying ? 22 : 17,
                decoration: BoxDecoration(
                  color: hasNowPlaying
                      ? const Color(0xff34d399)
                      : Colors.white.withOpacity(0.42),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: hasNowPlaying
                    ? const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.black,
                        size: 13,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantPanel extends StatelessWidget {
  const _AssistantPanel({
    super.key,
    required this.messages,
    required this.inputController,
    required this.scrollController,
    required this.nowPlaying,
    required this.isLoadingSongs,
    required this.availableSongCount,
    required this.isSpeechReady,
    required this.isListening,
    required this.speechLocaleId,
    required this.interimTranscript,
    required this.speechError,
    required this.onClose,
    required this.onSubmit,
    required this.onToggleListening,
    required this.onToggleSpeechLocale,
    required this.onQuickPrompt,
  });

  final List<AssistantMessage> messages;
  final TextEditingController inputController;
  final ScrollController scrollController;
  final Track? nowPlaying;
  final bool isLoadingSongs;
  final int availableSongCount;
  final bool isSpeechReady;
  final bool isListening;
  final String speechLocaleId;
  final String interimTranscript;
  final String? speechError;

  final VoidCallback onClose;
  final VoidCallback onSubmit;
  final VoidCallback onToggleListening;
  final VoidCallback onToggleSpeechLocale;
  final ValueChanged<String> onQuickPrompt;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final width = math.min(screenSize.width - 32, 390).toDouble();

    final availableHeight = screenSize.height - keyboardInset - 160;
    final maxHeight = availableHeight.clamp(340.0, 620.0).toDouble();

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.88),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 70,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              _PanelHeader(
                nowPlaying: nowPlaying,
                isLoadingSongs: isLoadingSongs,
                onClose: onClose,
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(message: messages[index]);
                  },
                ),
              ),
              _PanelInputArea(
                inputController: inputController,
                isLoadingSongs: isLoadingSongs,
                availableSongCount: availableSongCount,
                isSpeechReady: isSpeechReady,
                isListening: isListening,
                speechLocaleId: speechLocaleId,
                interimTranscript: interimTranscript,
                speechError: speechError,
                onSubmit: onSubmit,
                onToggleListening: onToggleListening,
                onToggleSpeechLocale: onToggleSpeechLocale,
                onQuickPrompt: onQuickPrompt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.nowPlaying,
    required this.isLoadingSongs,
    required this.onClose,
  });

  final Track? nowPlaying;
  final bool isLoadingSongs;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final subtitle = isLoadingSongs
        ? 'Đang tải thư viện nhạc...'
        : nowPlaying != null
        ? '${nowPlaying!.title} · ${nowPlaying!.artist}'
        : 'Điều khiển trình phát nhạc';

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 10, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KhoaLisa AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Thu nhỏ trợ lý',
            onPressed: onClose,
            icon: Icon(
              Icons.remove_rounded,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
          IconButton(
            tooltip: 'Đóng trợ lý',
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.white : Colors.white.withOpacity(0.065),
          borderRadius: BorderRadius.circular(18),
          border: isUser
              ? null
              : Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white.withOpacity(0.86),
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PanelInputArea extends StatelessWidget {
  const _PanelInputArea({
    required this.inputController,
    required this.isLoadingSongs,
    required this.availableSongCount,
    required this.isSpeechReady,
    required this.isListening,
    required this.speechLocaleId,
    required this.interimTranscript,
    required this.speechError,
    required this.onSubmit,
    required this.onToggleListening,
    required this.onToggleSpeechLocale,
    required this.onQuickPrompt,
  });

  final TextEditingController inputController;
  final bool isLoadingSongs;
  final int availableSongCount;
  final bool isSpeechReady;
  final bool isListening;
  final String speechLocaleId;
  final String interimTranscript;
  final String? speechError;

  final VoidCallback onSubmit;
  final VoidCallback onToggleListening;
  final VoidCallback onToggleSpeechLocale;
  final ValueChanged<String> onQuickPrompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: musicBotQuickPrompts.map((item) {
              return ActionChip(
                onPressed: () => onQuickPrompt(item.prompt),
                label: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                backgroundColor: Colors.white.withOpacity(0.045),
                side: BorderSide(color: Colors.white.withOpacity(0.10)),
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.60)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.065),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white.withOpacity(0.35),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: inputController,
                    onSubmitted: (_) => onSubmit(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Nói hoặc nhập: mở bài Lemon Tree...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đổi ngôn ngữ ghi âm Việt/Anh',
                  onPressed: onToggleSpeechLocale,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.055),
                    foregroundColor: Colors.white.withOpacity(0.70),
                    fixedSize: const Size(36, 36),
                  ),
                  icon: Text(
                    speechLocaleId == 'vi_VN' ? 'VI' : 'EN',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: !isSpeechReady
                      ? 'Trình duyệt chưa hỗ trợ nhận diện giọng nói'
                      : isListening
                      ? 'Dừng ghi âm'
                      : 'Bấm để nói',
                  onPressed: isSpeechReady ? onToggleListening : null,
                  style: IconButton.styleFrom(
                    backgroundColor: isListening
                        ? Colors.redAccent.withOpacity(0.18)
                        : Colors.white.withOpacity(0.055),
                    foregroundColor: isListening
                        ? Colors.redAccent.shade100
                        : Colors.white.withOpacity(0.70),
                    fixedSize: const Size(36, 36),
                  ),
                  icon: Icon(
                    isListening
                        ? Icons.mic_off_rounded
                        : Icons.mic_none_rounded,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Gửi lệnh',
                  onPressed: onSubmit,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    fixedSize: const Size(36, 36),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 17),
                ),
              ],
            ),
          ),
          if (isListening) ...[
            const SizedBox(height: 9),
            _StatusBox(
              color: const Color(0xff22d3ee),
              text: interimTranscript.trim().isEmpty
                  ? 'Đang nghe...'
                  : 'Đang nghe: $interimTranscript',
            ),
          ],
          if (speechError != null) ...[
            const SizedBox(height: 9),
            _StatusBox(color: Colors.redAccent, text: speechError!),
          ],
          if (!isSpeechReady) ...[
            const SizedBox(height: 9),
            const _StatusBox(
              color: Color(0xffffd166),
              text:
                  'Trình duyệt này chưa hỗ trợ nhận diện giọng nói. Hãy thử Chrome hoặc Edge.',
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                isLoadingSongs
                    ? Icons.sync_rounded
                    : Icons.library_music_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '$availableSongCount bài có thể phát',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.36),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  speechLocaleId == 'vi_VN' ? 'VOICE VI' : 'VOICE EN',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.36),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.92),
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
