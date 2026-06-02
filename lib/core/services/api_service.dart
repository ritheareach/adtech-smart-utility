import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/bill.dart';
import '../../models/notification_item.dart';
import '../../models/usage_data.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  ApiService._();
  factory ApiService() => _instance;

  static const String _base = 'http://intranet-macmini.local:3001/api';

  String? _token;
  String? _userName;
  String? _unitNumber;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  bool get isLoggedIn => _token != null;
  String get userName => _userName ?? 'User';
  String get unitNumber => _unitNumber ?? '';

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: _headers,
      body: jsonEncode({'phone': phone}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final res = await http.post(
      Uri.parse('$_base/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    final data = _decode(res);
    if (data['token'] != null) setToken(data['token'] as String);
    final u = data['user'] as Map<String, dynamic>?;
    if (u != null) {
      _userName = u['name'] as String?;
      _unitNumber = u['unitNumber'] as String?;
    }
    return data;
  }

  Future<void> loadUserProfile() async {
    final res = await http.get(Uri.parse('$_base/auth/me'), headers: _headers);
    final data = _decode(res);
    _userName = data['name'] as String?;
    _unitNumber = data['unitNumber'] as String?;
  }

  // ── Bills ─────────────────────────────────────────────────────────────────

  Future<List<Bill>> getCurrentBills() async {
    final res = await http.get(Uri.parse('$_base/bills'), headers: _headers);
    final data = _decode(res);
    return (data['bills'] as List)
        .map((j) => _billFromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Bill>> getBillHistory({int limit = 20, int offset = 0}) async {
    final res = await http.get(
      Uri.parse('$_base/bills/history?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    final data = _decode(res);
    return (data['bills'] as List)
        .map((j) => _billFromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Bill>> getAllBills({int limit = 100}) async {
    final res = await http.get(
      Uri.parse('$_base/bills/records?limit=$limit'),
      headers: _headers,
    );
    final data = _decode(res);
    return (data['bills'] as List)
        .map((j) => _billFromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Usage ─────────────────────────────────────────────────────────────────

  Future<List<UsageSummary>> getUsageSummary({String period = 'month'}) async {
    final res = await http.get(
      Uri.parse('$_base/usage/summary?period=$period'),
      headers: _headers,
    );
    final data = _decode(res);
    return (data['summaries'] as List)
        .map((j) => _summaryFromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<MonthlyUsage>> getMonthlyUsage({int? year}) async {
    final y = year ?? DateTime.now().year;
    final res = await http.get(
      Uri.parse('$_base/usage/monthly?year=$y'),
      headers: _headers,
    );
    final data = _decode(res);
    return (data['monthly'] as List)
        .map((j) => _monthlyFromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createPayment({
    required String tranId,
    required double amount,
    String currency = 'KHR',
    String paymentOption = '',
    List<String> billIds = const [],
    bool paid = false,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/payments'),
      headers: _headers,
      body: jsonEncode({
        'tran_id': tranId,
        'amount': amount,
        'currency': currency,
        if (paymentOption.isNotEmpty) 'payment_option': paymentOption,
        'bill_ids': billIds,
        if (paid) 'paid': true,
      }),
    );
    return _decode(res);
  }

  Future<void> sandboxCompleteBill(List<String> billIds) async {
    final res = await http.post(
      Uri.parse('$_base/payments/sandbox/complete'),
      headers: _headers,
      body: jsonEncode({'bill_ids': billIds}),
    );
    _decode(res);
  }

  Future<Map<String, dynamic>> getMonthlyTotals() async {
    final res = await http.get(
      Uri.parse('$_base/bills/monthly-totals'),
      headers: _headers,
    );
    final data = _decode(res);
    return {
      'labels': List<String>.from(data['months'] as List),
      'totals': (data['totals'] as List).map((v) => double.parse(v.toString())).toList(),
    };
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<NotificationItem>> getNotifications() async {
    final res = await http.get(Uri.parse('$_base/notifications'), headers: _headers);
    final data = _decode(res);
    return (data['notifications'] as List)
        .map((j) => NotificationItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await http.patch(
      Uri.parse('$_base/notifications/${Uri.encodeComponent(id)}/read'),
      headers: _headers,
    );
  }

  Future<void> markAllNotificationsRead(List<String> ids) async {
    await http.patch(
      Uri.parse('$_base/notifications/read-all'),
      headers: _headers,
      body: jsonEncode({'ids': ids}),
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final res = await http.get(Uri.parse('$_base/payments'), headers: _headers);
    final data = _decode(res);
    return List<Map<String, dynamic>>.from(data['payments'] as List);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _decode(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    if (!ct.contains('application/json')) {
      throw Exception('HTTP ${res.statusCode} — server returned non-JSON. Restart the backend.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Request failed (${res.statusCode})');
    }
    return body;
  }

  Bill _billFromJson(Map<String, dynamic> j) => Bill(
        id: j['id'] as String,
        type: j['type'] as String,
        period: j['period'] as String,
        amount: double.parse(j['amount'].toString()),
        usage: double.parse(j['usage'].toString()),
        unit: j['unit'] as String,
        dueDate: j['due_date'] as String,
        status: _parseStatus(j['status'] as String),
      );

  BillStatus _parseStatus(String s) {
    switch (s) {
      case 'paid':
        return BillStatus.paid;
      case 'overdue':
        return BillStatus.overdue;
      default:
        return BillStatus.unpaid;
    }
  }

  UsageSummary _summaryFromJson(Map<String, dynamic> j) => UsageSummary(
        type: j['type'] as String,
        value: double.parse(j['value'].toString()),
        unit: j['unit'] as String,
        changePercent: double.parse(j['changePercent'].toString()),
        isUp: j['isUp'] as bool,
      );

  MonthlyUsage _monthlyFromJson(Map<String, dynamic> j) => MonthlyUsage(
        month: j['month'] as String,
        water: double.parse(j['water'].toString()),
        electricity: double.parse(j['electricity'].toString()),
        gas: double.parse(j['gas'].toString()),
        cooling: double.parse(j['cooling'].toString()),
        electricity2026: double.parse((j['electricity2026'] ?? 0).toString()),
        water2026: double.parse((j['water2026'] ?? 0).toString()),
        gas2026: double.parse((j['gas2026'] ?? 0).toString()),
        cooling2026: double.parse((j['cooling2026'] ?? 0).toString()),
      );
}
