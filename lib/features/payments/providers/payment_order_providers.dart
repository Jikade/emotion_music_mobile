import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/providers/music_providers.dart';
import '../data/payment_order_repository.dart';

final paymentOrderRepositoryProvider = Provider<PaymentOrderRepository>((ref) {
  return PaymentOrderRepository(ref.watch(apiClientProvider));
});
