import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/payway_config.dart';
import '../../models/bill.dart';
import '../../viewmodels/payment_viewmodel.dart';
import '../../core/services/payway_service.dart';
import 'payment_result_screen.dart';

class KhqrScreen extends StatefulWidget {
  final List<Bill> bills;
  final String method;

  const KhqrScreen({super.key, required this.bills, required this.method});

  @override
  State<KhqrScreen> createState() => _KhqrScreenState();
}

class _KhqrScreenState extends State<KhqrScreen> with WidgetsBindingObserver {
  late final String _tranId;
  PayWayCheckout? _checkout;
  String? _error;
  bool _loading = true;
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 60;

  double get _totalAmount => widget.bills.fold(0.0, (s, b) => s + b.amount);
  List<String> get _billIds => widget.bills.map((b) => b.id).toList();

  String get _paymentOption {
    switch (widget.method) {
      case 'alipay': return 'alipay';
      case 'wechat': return 'wechat';
      default: return '';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tranId = DateTime.now().millisecondsSinceEpoch.toString();
    _createTransaction();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _checkout != null &&
        (_pollTimer == null || !_pollTimer!.isActive) &&
        _pollCount < _maxPolls) {
      _startPolling();
    }
  }

  Future<void> _createTransaction() async {
    setState(() { _loading = true; _error = null; });
    try {
      final checkout = await PayWayService().createTransaction(
        tranId: _tranId,
        amount: _totalAmount,
        firstName: 'ADTech',
        lastName: 'Customer',
        phone: '012000000',
        paymentOption: _paymentOption,
        currency: 'KHR',
        returnParams: _billIds.join(','),
      );
      setState(() { _checkout = checkout; _loading = false; });
      _startPolling();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    _pollCount++;
    if (_pollCount >= _maxPolls) { _pollTimer?.cancel(); return; }
    try {
      final result = await PayWayService().checkTransaction(_tranId);
      if (!mounted) return;

      if (PayWayConfig.isSandbox) {
        debugPrint('[PayWay] poll #$_pollCount | raw: $result');
      }

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final statusRaw = data['status'];
        final String code = statusRaw is Map
            ? statusRaw['code']?.toString() ?? ''
            : statusRaw?.toString() ?? '';
        final String paymentStatus =
            (data['payment_status'] as String? ?? '').toUpperCase();

        if (PayWayConfig.isSandbox) {
          debugPrint('[PayWay] status.code="$code" payment_status="$paymentStatus"');
        }

        const successCodes = {'0', '00', '1'};
        const successStatuses = {'PAID', 'APPROVED', 'SUCCESS'};
        const failCodes = {'200', '201'};
        const failStatuses = {'FAILED', 'CANCELLED', 'CANCELED', 'DECLINED'};

        final isSuccess = successCodes.contains(code) || successStatuses.contains(paymentStatus);
        final isFail = failCodes.contains(code) || failStatuses.contains(paymentStatus);

        if (isSuccess) {
          _pollTimer?.cancel();
          await _navigateToResult(success: true);
        } else if (isFail) {
          _pollTimer?.cancel();
          await _navigateToResult(success: false);
        }
      }
    } catch (_) {}
  }

  Future<void> _navigateToResult({required bool success}) async {
    String? syncError;
    if (success) {
      syncError = await context.read<PaymentViewModel>().recordPayment(
        tranId: _tranId,
        amount: _totalAmount,
        billIds: _billIds,
        paymentOption: _paymentOption,
      );
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => PaymentResultScreen(
        success: success,
        tranId: _tranId,
        total: _totalAmount,
        bills: widget.bills,
        syncError: syncError,
      ),
    ));
  }

  Future<void> _openAbaApp() async {
    final deeplink = _checkout?.abaPayDeeplink ?? '';
    if (deeplink.isEmpty) return;
    final uri = Uri.parse(deeplink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final store = _checkout?.playStoreUrl ?? '';
      if (store.isNotEmpty) await launchUrl(Uri.parse(store));
    }
  }

  String get _title {
    switch (widget.method) {
      case 'alipay': return 'Alipay';
      case 'wechat': return 'WeChat Pay';
      default: return 'ABA KHQR';
    }
  }

  String get _instruction {
    switch (widget.method) {
      case 'alipay': return 'Open Alipay app and scan the QR code below to complete your payment.';
      case 'wechat': return 'Open WeChat app, go to Scan, and scan the QR code below.';
      default: return 'Open ABA Mobile App or any KHQR-supported banking app and scan the QR code.';
    }
  }

  Color get _accentColor {
    switch (widget.method) {
      case 'alipay': return const Color(0xFF1677FF);
      case 'wechat': return const Color(0xFF07C160);
      default: return const Color(0xFF002B5C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryLight),
            SizedBox(height: 16),
            Text('Generating QR code...', style: TextStyle(color: AppColors.textGray)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              const Text('Failed to Create Payment',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _createTransaction,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
              ),
            ],
          ),
        ),
      );
    }
    return _CheckoutView(
      checkout: _checkout!,
      bills: widget.bills,
      totalAmount: _totalAmount,
      method: widget.method,
      accentColor: _accentColor,
      instruction: _instruction,
      pollCount: _pollCount,
      maxPolls: _maxPolls,
      onOpenAba: widget.method == 'aba_khqr' ? _openAbaApp : null,
      onSimulate: () async {
        _pollTimer?.cancel();
        setState(() => _loading = true);
        final vm = context.read<PaymentViewModel>();
        final sandboxError = await vm.sandboxComplete(_billIds);
        if (!mounted) return;
        if (sandboxError == null) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => PaymentResultScreen(
              success: true,
              tranId: _tranId,
              total: _totalAmount,
              bills: widget.bills,
            ),
          ));
        } else {
          debugPrint('[Sandbox] sandboxComplete failed: $sandboxError — falling back to createPayment');
          await _navigateToResult(success: true);
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  final PayWayCheckout checkout;
  final List<Bill> bills;
  final double totalAmount;
  final String method;
  final Color accentColor;
  final String instruction;
  final int pollCount;
  final int maxPolls;
  final VoidCallback? onOpenAba;
  final VoidCallback onSimulate;
  final VoidCallback onCancel;

  const _CheckoutView({
    required this.checkout, required this.bills, required this.totalAmount,
    required this.method, required this.accentColor, required this.instruction,
    required this.pollCount, required this.maxPolls,
    this.onOpenAba, required this.onSimulate, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final qrBytes = base64Decode(checkout.qrImageBase64);
    final secondsLeft = ((maxPolls - pollCount) * 3).clamp(0, maxPolls * 3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: accentColor, borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  bills.length > 1 ? 'Total Amount (${bills.length} bills)' : 'Amount to Pay',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text('${_fmtKhr(totalAmount)} ៛',
                    style: const TextStyle(color: Colors.white, fontSize: 30,
                        fontWeight: FontWeight.bold)),
                Text('≈ \$${(totalAmount / 4100).toStringAsFixed(2)} USD',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                if (bills.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: bills.map((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(b.type,
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                const Text('Scan to Pay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(
                  method == 'aba_khqr'
                      ? 'ABA Mobile, any KHQR-supported app'
                      : method == 'alipay' ? 'Open Alipay → Scan' : 'Open WeChat → Scan',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.memory(qrBytes, width: 200, height: 200),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: AppColors.primaryLight)),
                    const SizedBox(width: 6),
                    const Text('Waiting for payment... ',
                        style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                    const Icon(Icons.timer_outlined, size: 13, color: AppColors.textGray),
                    const SizedBox(width: 3),
                    Text('${secondsLeft}s',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: secondsLeft < 30 ? AppColors.orange : AppColors.textGray)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(instruction, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.5)),
          const SizedBox(height: 20),

          if (onOpenAba != null && checkout.abaPayDeeplink.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenAba,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open ABA Mobile App',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF002B5C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge('KHQR'), SizedBox(width: 8),
              _Badge('ABA Pay'), SizedBox(width: 8),
              _Badge('WeChat'), SizedBox(width: 8),
              _Badge('Alipay'),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textGray,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 15)),
            ),
          ),

          if (PayWayConfig.isSandbox) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            Text('SANDBOX TESTING',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                    color: Colors.orange[700], letterSpacing: 1.2)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSimulate,
                icon: const Icon(Icons.science_outlined, size: 16),
                label: const Text('Simulate Payment (use ABA sandbox)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  side: BorderSide(color: Colors.orange[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtKhr(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)},${(v % 1000).toInt().toString().padLeft(3, '0')}'
      : v.toInt().toString();
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
  );
}
