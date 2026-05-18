import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/providers/music_providers.dart';
import '../data/emotion_repository.dart';

final emotionRepositoryProvider = Provider<EmotionRepository>((ref) {
  return EmotionRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final emotionDetectProvider =
    NotifierProvider<EmotionDetectController, EmotionDetectState>(
      EmotionDetectController.new,
    );

class EmotionDetectState {
  final bool isLoading;
  final EmotionDetectResult? result;
  final String? errorMessage;

  const EmotionDetectState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  EmotionDetectState copyWith({
    bool? isLoading,
    EmotionDetectResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return EmotionDetectState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class EmotionDetectController extends Notifier<EmotionDetectState> {
  late final EmotionRepository _repository;

  @override
  EmotionDetectState build() {
    _repository = ref.watch(emotionRepositoryProvider);
    return const EmotionDetectState();
  }

  Future<void> detect(String text) async {
    state = const EmotionDetectState(isLoading: true);

    try {
      final result = await _repository.detectTextEmotion(text);

      state = EmotionDetectState(result: result);
    } catch (error) {
      state = EmotionDetectState(
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clear() {
    state = const EmotionDetectState();
  }
}
