import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/payway_config.dart';
import '../../models/bill.dart';
import '../../viewmodels/payment_viewmodel.dart';
import '../../core/services/payway_service.dart';
import 'payment_result_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  final Bill bill;
  const CardPaymentScreen({super.key, required this.bill});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  late final String _tranId;
  late final WebViewController _controller;
  bool _loading = true;
  bool _preparing = true;

  @override
  void initState() {
    super.initState();
    _tranId = DateTime.now().millisecondsSinceEpoch.toString();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (req) {
          if (req.url.startsWith(PayWayConfig.returnScheme)) {
            _handleResult(req.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _loadCheckout();
  }

  Future<void> _loadCheckout() async {
    try {
      final html = await PayWayService().buildCardCheckoutHtmlAsync(
        tranId: _tranId,
        amount: widget.bill.amount,
        firstName: 'ADTech',
        lastName: 'Customer',
        phone: '012000000',
        currency: 'KHR',
        returnParams: widget.bill.id,
      );
      await _controller.loadHtmlString(
        html,
        baseUrl: PayWayConfig.isSandbox
            ? 'https://checkout-sandbox.payway.com.kh/'
            : 'https://checkout.payway.com.kh/',
      );
      if (mounted) setState(() => _preparing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load checkout: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleResult(String url) async {
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'] ?? '';
    final apv = uri.queryParameters['apv'];
    final success = status == '0' || status == '00' || status == '1';

    String? syncError;
    if (success) {
      syncError = await context.read<PaymentViewModel>().recordPayment(
        tranId: _tranId,
        amount: widget.bill.amount,
        billIds: [widget.bill.id],
      );
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => PaymentResultScreen(
        success: success,
        tranId: _tranId,
        approvalCode: apv,
        total: widget.bill.amount,
        bills: [widget.bill],
        syncError: syncError,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pay by Card',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        centerTitle: true,
        bottom: (_loading || _preparing)
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.border,
                  color: AppColors.primaryLight,
                ),
              )
            : null,
      ),
      body: _preparing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryLight),
                  SizedBox(height: 16),
                  Text('Loading checkout...', style: TextStyle(color: AppColors.textGray)),
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
