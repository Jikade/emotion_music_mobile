import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

const int vipProAmount = 1000;
const String vipProPackageName = 'VIP PRO';

enum PaymentOrderStatus {
  pending,
  approved,
  rejected,
  unknown;

  static PaymentOrderStatus fromString(String? value) {
    final raw = value?.trim().toLowerCase();

    if (raw == 'pending') return PaymentOrderStatus.pending;
    if (raw == 'approved') return PaymentOrderStatus.approved;
    if (raw == 'rejected') return PaymentOrderStatus.rejected;

    return PaymentOrderStatus.unknown;
  }
}

class PaymentOrder {
  final int id;
  final String orderCode;
  final int userId;
  final String userEmail;
  final String packageName;
  final int amount;
  final String qrUrl;
  final PaymentOrderStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;

  const PaymentOrder({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.userEmail,
    required this.packageName,
    required this.amount,
    required this.qrUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: _toInt(json['id']),
      orderCode: json['order_code']?.toString() ?? '',
      userId: _toInt(json['user_id']),
      userEmail: json['user_email']?.toString() ?? '',
      packageName: json['package_name']?.toString() ?? vipProPackageName,
      amount: _toInt(json['amount']),
      qrUrl: json['qr_url']?.toString() ?? '',
      status: PaymentOrderStatus.fromString(json['status']?.toString()),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
      approvedAt: _toDate(json['approved_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case PaymentOrderStatus.pending:
        return 'Chờ xử lý';
      case PaymentOrderStatus.approved:
        return 'Đã duyệt';
      case PaymentOrderStatus.rejected:
        return 'Đã từ chối';
      case PaymentOrderStatus.unknown:
        return 'Không xác định';
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    final raw = value?.toString();

    if (raw == null || raw.trim().isEmpty) return null;

    return DateTime.tryParse(raw)?.toLocal();
  }
}

class PaymentOrderRepository {
  PaymentOrderRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PaymentOrder>> listMyPaymentOrders() async {
    try {
      final response = await _apiClient.dio.get('/payment-orders/me');
      final data = response.data;

      if (data is! List) return [];

      final orders = data
          .whereType<Map>()
          .map((item) => PaymentOrder.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      orders.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return right.compareTo(left);
      });

      return orders;
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    } catch (error) {
      throw Exception('Không thể tải hóa đơn VIP PRO: $error');
    }
  }

  Future<PaymentOrder> createPaymentOrder({int amount = vipProAmount}) async {
    try {
      final response = await _apiClient.dio.post(
        '/payment-orders',
        data: {'amount': amount, 'package_name': vipProPackageName},
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return PaymentOrder.fromJson(data);
      }

      if (data is Map) {
        return PaymentOrder.fromJson(Map<String, dynamic>.from(data));
      }

      throw Exception('Backend trả dữ liệu hóa đơn không hợp lệ.');
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    } catch (error) {
      throw Exception('Không thể xác nhận thanh toán: $error');
    }
  }

  String buildVipQrUrl(String email, {int amount = vipProAmount}) {
    return 'https://img.vietqr.io/image/momo-0983947901-qr_only.png'
        '?amount=$amount'
        '&addInfo=${Uri.encodeComponent(email)}';
  }

  String _readableError(DioException error) {
    final data = error.response?.data;

    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];

      if (detail is List) {
        return detail.map((item) => item.toString()).join('\n');
      }

      return detail.toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Không kết nối được backend. Kiểm tra API_BASE_URL và Docker backend.';
    }

    return error.message ?? 'Có lỗi xảy ra khi gọi API thanh toán.';
  }
}
