import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/providers/music_providers.dart';
import '../data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(apiClientProvider));
});
