import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/payway_config.dart';

class PayWayService {
  static final PayWayService _instance = PayWayService._();
  PayWayService._();
  factory PayWayService() => _instance;

  String _reqTime() => DateFormat('yyyyMMddHHmmss').format(DateTime.now());

  // PayWay requires fields concatenated in this exact fixed order.
  // Empty string is used for any field not provided.
  static const List<String> _hashFieldOrder = [
    'req_time',
    'merchant_id',
    'tran_id',
    'amount',
    'items',
    'shipping',
    'firstname',
    'lastname',
    'email',
    'phone',
    'type',
    'payment_option',
    'return_url',
    'cancel_url',
    'continue_success_url',
    'return_deeplink',
    'currency',
    'custom_fields',
    'return_params',
    'payout',
    'lifetime',
    'additional_params',
    'google_pay_token',
    'skip_success_page',
  ];

  /// Concatenate fields in PayWay's required order, then HMAC-SHA512 + base64.
  String generateHash(Map<String, String> params) {
    final payload = _hashFieldOrder
        .map((field) => params[field] ?? '')
        .join('');
    final key = utf8.encode(PayWayConfig.apiKey);
    final digest = Hmac(sha512, key).convert(utf8.encode(payload));
    return base64.encode(digest.bytes);
  }

  // ── Create transaction ─────────────────────────────────────────────────────

  /// POSTs to PayWay and returns parsed checkout data (qrImage, deeplink, etc.)
  Future<PayWayCheckout> createTransaction({
    required String tranId,
    required double amount,
    required String firstName,
    required String lastName,
    required String phone,
    String paymentOption = '',
    String currency = 'USD',
    String? returnParams,
  }) async {
    final reqTime = _reqTime();
    final amountStr = amount.toStringAsFixed(2);

    final params = <String, String>{
      'req_time': reqTime,
      'merchant_id': PayWayConfig.merchantId,
      'tran_id': tranId,
      'amount': amountStr,
      'firstname': firstName,
      'lastname': lastName,
      'phone': phone,
      'return_deeplink': PayWayConfig.returnDeeplink,
    };

    if (paymentOption.isNotEmpty) params['payment_option'] = paymentOption;
    if (currency.isNotEmpty) params['currency'] = currency;
    if (returnParams != null && returnParams.isNotEmpty) {
      params['return_params'] = returnParams;
    }

    params['hash'] = generateHash(params);

    try {
      final response = await http.post(
        Uri.parse(PayWayConfig.checkoutUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: params,
      );

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as Map<String, dynamic>?;
      final code = status?['code'] as String? ?? '';

      if (code == '00') {
        return PayWayCheckout(
          tranId: tranId,
          amount: amount,
          currency: currency,
          qrImage: data['qrImage'] as String? ?? '',
          qrString: data['qrString'] as String? ?? '',
          abaPayDeeplink: data['abapay_deeplink'] as String? ?? '',
          playStoreUrl: data['play_store'] as String? ?? '',
          appStoreUrl: data['app_store'] as String? ?? '',
        );
      }

      throw Exception(status?['message'] ?? 'Payment failed (code: $code)');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ── Card checkout HTML (hosted WebView) ───────────────────────────────────

  /// Builds a self-submitting form loaded in a WebView with a real browser
  /// User-Agent — PayWay returns their hosted HTML checkout page for browsers.
  Future<String> buildCardCheckoutHtmlAsync({
    required String tranId,
    required double amount,
    required String firstName,
    required String lastName,
    required String phone,
    String currency = 'USD',
    String? returnParams,
  }) async {
    final reqTime = _reqTime();
    final amountStr = amount.toStringAsFixed(2);

    final params = <String, String>{
      'req_time': reqTime,
      'merchant_id': PayWayConfig.merchantId,
      'tran_id': tranId,
      'amount': amountStr,
      'firstname': firstName,
      'lastname': lastName,
      'phone': phone,
      'return_deeplink': PayWayConfig.returnDeeplink,
    };

    if (currency.isNotEmpty) params['currency'] = currency;
    if (returnParams != null && returnParams.isNotEmpty) {
      params['return_params'] = returnParams;
    }

    final hash = generateHash(params);
    final fields = params.entries
        .map((e) =>
            '<input type="hidden" name="${e.key}" value="${e.value.replaceAll('"', '&quot;')}" />')
        .join('\n    ');

    return '''<!DOCTYPE html>
<html>
<head><meta name="viewport" content="width=device-width,initial-scale=1.0">
<style>body{margin:0;background:#f5f5f5;}</style></head>
<body>
  <form id="f" method="POST" action="${PayWayConfig.checkoutUrl}" target="_self">
    $fields
    <input type="hidden" name="hash" value="$hash" />
    <input type="hidden" name="view_type" value="hosted" />
  </form>
  <script>document.getElementById('f').submit();</script>
</body>
</html>''';
  }

  // ── Check transaction ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> checkTransaction(String tranId) async {
    final reqTime = _reqTime();
    final params = <String, String>{
      'req_time': reqTime,
      'merchant_id': PayWayConfig.merchantId,
      'tran_id': tranId,
    };
    final hash = generateHash(params);

    try {
      final response = await http.post(
        Uri.parse(PayWayConfig.checkTransactionUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {...params, 'hash': hash},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'status': decoded};
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Callback verification ──────────────────────────────────────────────────

  /// Verify the X_PAYWAY_HMAC_SHA512 header from PayWay's callback.
  bool verifyCallback(Map<String, dynamic> payload, String receivedSignature) {
    final sorted = Map.fromEntries(
      payload.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final data = sorted.values
        .map((v) => v is Map ? json.encode(v) : v.toString())
        .join('');
    final key = utf8.encode(PayWayConfig.apiKey);
    final digest = Hmac(sha512, key).convert(utf8.encode(data));
    return base64.encode(digest.bytes) == receivedSignature;
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class PayWayCheckout {
  final String tranId;
  final double amount;
  final String currency;
  final String qrImage;
  final String qrString;
  final String abaPayDeeplink;
  final String playStoreUrl;
  final String appStoreUrl;

  const PayWayCheckout({
    required this.tranId,
    required this.amount,
    required this.currency,
    required this.qrImage,
    required this.qrString,
    required this.abaPayDeeplink,
    required this.playStoreUrl,
    required this.appStoreUrl,
  });

  // Base64 portion of the qrImage data URI
  String get qrImageBase64 {
    const prefix = 'data:image/png;base64,';
    return qrImage.startsWith(prefix) ? qrImage.substring(prefix.length) : qrImage;
  }
}
