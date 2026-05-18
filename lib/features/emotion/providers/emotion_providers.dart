import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/providers/music_providers.dart';
import '../data/emotion_repository.dart';

final emotionRepositoryProvider = Provider<EmotionRepository>((ref) {
  return EmotionRepository(ref.watch(apiClientProvider));
});
