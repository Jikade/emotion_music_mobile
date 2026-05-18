import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/providers/music_providers.dart';
import '../data/recommendation_repository.dart';

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  return RecommendationRepository(
    ref.watch(apiClientProvider),
    ref.watch(trackRepositoryProvider),
  );
});
