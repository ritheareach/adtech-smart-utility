import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/bill.dart';
import 'home_screen.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final double total;
  final List<Bill> bills;
  final String? tranId;
  final String? approvalCode;

  const PaymentResultScreen({
    super.key,
    this.success = true,
    required this.total,
    required this.bills,
    this.tranId,
    this.approvalCode,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ref = tranId ?? 'TXN-${now.millisecondsSinceEpoch.toString().substring(7)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Status icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: success
                      ? AppColors.green.withValues(alpha: 0.12)
                      : AppColors.red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle : Icons.cancel,
                  color: success ? AppColors.green : AppColors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                success ? 'Payment Successful!' : 'Payment Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: success ? AppColors.textDark : AppColors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                success
                    ? 'Your utility bills have been paid successfully.'
                    : 'The payment was not completed. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      success ? 'Payment Receipt' : 'Transaction Details',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),
                    _Row('Reference', ref),
                    if (approvalCode != null && approvalCode!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _Row('Approval Code', approvalCode!),
                    ],
                    const Divider(height: 20),
                    ...bills.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _Row('${b.type} (${b.period})', '${_fmt(b.amount)} ៛'),
                        )),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        Text(
                          '${_fmt(total)} ៛',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: success ? AppColors.primaryLight : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Row('Date',
                        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}'),
                    _Row('Status', success ? 'Paid' : 'Failed'),
                  ],
                ),
              ),

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
                    backgroundColor: success ? AppColors.primaryLight : AppColors.textGray,
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

  static String _fmt(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)},${(v % 1000).toInt().toString().padLeft(3, '0')}'
      : v.toInt().toString();
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
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
