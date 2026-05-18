import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import 'storage/token_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/music/data/track_repository.dart';

import '../features/emotion/data/emotion_repository.dart';

final emotionRepositoryProvider = Provider<EmotionRepository>((ref) {
  return EmotionRepository(ref.watch(apiClientProvider));
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository(ref.watch(apiClientProvider));
});

final tracksProvider = FutureProvider((ref) async {
  return ref.watch(trackRepositoryProvider).getTracks();
});
