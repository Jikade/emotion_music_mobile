import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/payment_order_repository.dart';
import '../providers/payment_order_providers.dart';

Future<void> showVipProPaymentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.62),
    builder: (sheetContext) {
      return const VipProPaymentSheet();
    },
  );
}

class VipProPaymentSheet extends ConsumerStatefulWidget {
  const VipProPaymentSheet({super.key});

  @override
  ConsumerState<VipProPaymentSheet> createState() => _VipProPaymentSheetState();
}

class _VipProPaymentSheetState extends ConsumerState<VipProPaymentSheet> {
  bool _showQr = false;
  bool _isLoadingOrders = false;
  bool _isConfirming = false;
  String? _errorMessage;
  PaymentOrder? _order;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadLatestOrder);
  }

  Future<void> _loadLatestOrder() async {
    final authState = ref.read(authControllerProvider);
    final user = authState.user;

    if (!authState.isLoggedIn || user == null || user.email.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoadingOrders = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(paymentOrderRepositoryProvider);
      final orders = await repository.listMyPaymentOrders();

      if (!mounted) return;

      setState(() {
        _order = orders.isNotEmpty ? orders.first : null;
        _showQr = _order != null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(paymentOrderRepositoryProvider);
      final createdOrder = await repository.createPaymentOrder(
        amount: vipProAmount,
      );

      await ref.read(authControllerProvider.notifier).refreshUser();

      if (!mounted) return;

      setState(() {
        _order = createdOrder;
        _showQr = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isLoggedIn = authState.isLoggedIn && user != null;
    final isVip = user?.isVip == true;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 14 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xff070b12).withOpacity(0.98),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.46),
                blurRadius: 46,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xffffd166).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xffffd166).withOpacity(0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xffffd166),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VIP PRO',
                            style: TextStyle(
                              color: Color(0xffffd166),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.6,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nâng cấp tài khoản',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Hãy nâng cấp VIP PRO để có thể tải nhạc độc quyền từ chúng tôi.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (!isLoggedIn)
                  _LoginRequiredBox(
                    onLogin: () {
                      Navigator.of(context).pop();
                      context.go('/dangNhap');
                    },
                  )
                else if (isVip)
                  _VipActiveBox(
                    onRefresh: () {
                      ref.read(authControllerProvider.notifier).refreshUser();
                    },
                  )
                else
                  _PaymentBody(
                    email: user.email,
                    order: _order,
                    showQr: _showQr,
                    isLoadingOrders: _isLoadingOrders,
                    isConfirming: _isConfirming,
                    errorMessage: _errorMessage,
                    onShowQr: () {
                      setState(() {
                        _showQr = true;
                        _errorMessage = null;
                      });
                    },
                    onConfirmPayment: _confirmPayment,
                    onRefreshOrder: _loadLatestOrder,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentBody extends ConsumerWidget {
  const _PaymentBody({
    required this.email,
    required this.order,
    required this.showQr,
    required this.isLoadingOrders,
    required this.isConfirming,
    required this.errorMessage,
    required this.onShowQr,
    required this.onConfirmPayment,
    required this.onRefreshOrder,
  });

  final String email;
  final PaymentOrder? order;
  final bool showQr;
  final bool isLoadingOrders;
  final bool isConfirming;
  final String? errorMessage;
  final VoidCallback onShowQr;
  final VoidCallback onConfirmPayment;
  final VoidCallback onRefreshOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(paymentOrderRepositoryProvider);
    final qrUrl = order?.qrUrl.trim().isNotEmpty == true
        ? order!.qrUrl
        : repository.buildVipQrUrl(email, amount: vipProAmount);

    if (isLoadingOrders) {
      return const _LoadingBox(message: 'Đang tải hóa đơn VIP PRO...');
    }

    if (!showQr && order == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onShowQr,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffffd166),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text(
              'NÂNG CẤP VIP PRO',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(message: errorMessage!),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order == null ? 'Thanh toán VIP PRO' : 'Hóa đơn VIP PRO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tải lại hóa đơn',
                onPressed: onRefreshOrder,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PaymentLine(
            label: 'Giá tiền',
            value: '${vipProAmount.toString()} VND',
            valueColor: const Color(0xffffd166),
          ),
          const SizedBox(height: 6),
          _PaymentLine(label: 'Mã đơn hàng', value: email),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                qrUrl,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    alignment: Alignment.center,
                    child: const Text(
                      'Không tải được QR thanh toán',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (order != null) ...[
            const SizedBox(height: 14),
            _OrderStatusBox(order: order!),
          ] else ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isConfirming ? null : onConfirmPayment,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff34d399),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(
                  0xff34d399,
                ).withOpacity(0.30),
                disabledForegroundColor: Colors.black.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                isConfirming ? 'Đang xác nhận...' : 'Xác nhận thanh toán',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(message: errorMessage!),
          ],
        ],
      ),
    );
  }
}

class _OrderStatusBox extends StatelessWidget {
  const _OrderStatusBox({required this.order});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      PaymentOrderStatus.approved => const Color(0xff34d399),
      PaymentOrderStatus.rejected => Colors.redAccent,
      PaymentOrderStatus.pending => const Color(0xffffd166),
      PaymentOrderStatus.unknown => Colors.white70,
    };

    final description = switch (order.status) {
      PaymentOrderStatus.pending =>
        'Đơn hàng của bạn đang chờ admin kiểm tra và duyệt.',
      PaymentOrderStatus.approved =>
        'Tài khoản của bạn đã được nâng cấp VIP PRO.',
      PaymentOrderStatus.rejected =>
        'Đơn hàng đã bị từ chối. Vui lòng liên hệ admin để được hỗ trợ.',
      PaymentOrderStatus.unknown => 'Không xác định được trạng thái đơn hàng.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.26)),
          ),
          child: Row(
            children: [
              Icon(
                order.status == PaymentOrderStatus.approved
                    ? Icons.verified_rounded
                    : order.status == PaymentOrderStatus.rejected
                    ? Icons.cancel_rounded
                    : Icons.schedule_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trạng thái đơn hàng: ${order.statusLabel}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              _DateRow(
                label: 'Ngày tạo đơn',
                value: _formatDate(order.createdAt),
              ),
              const SizedBox(height: 8),
              _DateRow(
                label: 'Ngày duyệt',
                value: _formatDate(order.approvedAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(
            color: order.status == PaymentOrderStatus.approved
                ? const Color(0xffbbf7d0)
                : order.status == PaymentOrderStatus.rejected
                ? Colors.redAccent.shade100
                : Colors.white.withOpacity(0.52),
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa có';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _VipActiveBox extends StatelessWidget {
  const _VipActiveBox({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xff34d399).withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xff34d399).withOpacity(0.24)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xff34d399)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tài khoản đã được duyệt VIP PRO',
                  style: TextStyle(
                    color: Color(0xffbbf7d0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bạn có thể tải các bài nhạc độc quyền từ chúng tôi.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffbbf7d0),
              side: BorderSide(
                color: const Color(0xff34d399).withOpacity(0.32),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Cập nhật hồ sơ',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginRequiredBox extends StatelessWidget {
  const _LoginRequiredBox({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Text(
            'Bạn cần đăng nhập để tạo mã QR thanh toán theo email tài khoản.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffffd166),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.login_rounded),
            label: const Text(
              'Đăng nhập',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentLine extends StatelessWidget {
  const _PaymentLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.48),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.42),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.w700,
        height: 1.45,
      ),
    );
  }
}
