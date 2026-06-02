import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../models/bill.dart';
import '../../viewmodels/payment_viewmodel.dart';
import '../home/home_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final bool success;
  final double total;
  final List<Bill> bills;
  final String? tranId;
  final String? approvalCode;
  final String? syncError;

  const PaymentResultScreen({
    super.key,
    this.success = true,
    required this.total,
    required this.bills,
    this.tranId,
    this.approvalCode,
    this.syncError,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  String? _syncError;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _syncError = widget.syncError;
  }

  Future<void> _retry() async {
    if (widget.tranId == null) return;
    setState(() => _retrying = true);
    final error = await context.read<PaymentViewModel>().recordPayment(
      tranId: widget.tranId!,
      amount: widget.total,
      billIds: widget.bills.map((b) => b.id).toList(),
    );
    if (mounted) setState(() { _syncError = error; _retrying = false; });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ref = widget.tranId ?? 'TXN-${now.millisecondsSinceEpoch.toString().substring(7)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: widget.success
                      ? AppColors.green.withValues(alpha: 0.12)
                      : AppColors.red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.success ? Icons.check_circle : Icons.cancel,
                  color: widget.success ? AppColors.green : AppColors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.success ? 'Payment Successful!' : 'Payment Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                    color: widget.success ? AppColors.textDark : AppColors.red),
              ),
              const SizedBox(height: 8),
              Text(
                widget.success
                    ? 'Your utility bills have been paid successfully.'
                    : 'The payment was not completed. Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
              const SizedBox(height: 32),

              // Receipt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 14, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.success ? 'Payment Receipt' : 'Transaction Details',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),
                    _Row('Reference', ref),
                    if (widget.approvalCode != null && widget.approvalCode!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _Row('Approval Code', widget.approvalCode!),
                    ],
                    const Divider(height: 20),
                    ...widget.bills.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Row('${b.type} (${b.period})', '${_fmt(b.amount)} ៛'),
                    )),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        Text('${_fmt(widget.total)} ៛',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                color: widget.success ? AppColors.primaryLight : AppColors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Row('Date',
                        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}'),
                    _Row('Status', widget.success ? 'Paid' : 'Failed'),
                  ],
                ),
              ),

              // Sync error banner
              if (widget.success && _syncError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_problem_outlined, size: 18, color: AppColors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Sync failed: $_syncError',
                            style: const TextStyle(fontSize: 12, color: AppColors.orange),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      _retrying
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  color: AppColors.orange))
                          : GestureDetector(
                              onTap: _retry,
                              child: const Text('Retry',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                      color: AppColors.orange)),
                            ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.success ? AppColors.primaryLight : AppColors.textGray,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) {
    final n = v.toInt();
    return n >= 1000
        ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}'
        : n.toString();
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
          Text(value,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
