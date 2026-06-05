import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/bill.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class BillsTab extends StatefulWidget {
  const BillsTab({super.key});

  @override
  State<BillsTab> createState() => _BillsTabState();
}

class _BillsTabState extends State<BillsTab> {
  List<Bill> _currentBills = [];
  List<Bill> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        ApiService().getCurrentBills(),
        ApiService().getBillHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _currentBills = results[0] as List<Bill>;
        _history      = results[1] as List<Bill>;
        _loading      = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total     = _currentBills.fold<double>(0, (s, b) => s + b.amount);
    final firstBill = _currentBills.isNotEmpty ? _currentBills.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () {},
        ),
        title: const Text(
          'Bills',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current bill header card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [_shadow],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    firstBill != null ? '${firstBill.period} Bill' : 'Current Bill',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                                    ),
                                    child: const Text('Unpaid',
                                        style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total Amount',
                                            style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                                        const SizedBox(height: 4),
                                        Text('៛ ${_fmt(total)}',
                                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                      ],
                                    ),
                                  ),
                                  if (firstBill != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Due Date',
                                            style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                                        const SizedBox(height: 4),
                                        Text(firstBill.dueDate,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _currentBills.isEmpty
                                      ? null
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const PaymentScreen()),
                                          ).then((_) => _load()),
                                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                                  label: const Text('Review and Pay',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Billing Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [_shadow],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Billing Summary',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              const SizedBox(height: 12),
                              ..._currentBills.asMap().entries.map((entry) {
                                final i    = entry.key;
                                final bill = entry.value;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        children: [
                                          Icon(_typeIcon(bill.type), size: 22, color: _typeColor(bill.type)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(bill.type,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('៛ ${_fmt(bill.amount)}',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                              Text('${bill.usage.toInt()} ${bill.unit}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
                                            ],
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.orange.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                                            ),
                                            child: const Text('Unpaid',
                                                style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (i < _currentBills.length - 1)
                                      const Divider(height: 1, color: AppColors.border),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recent Payments
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [_shadow],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recent Payments',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              const SizedBox(height: 8),
                              if (_history.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('No payment history yet.',
                                      style: TextStyle(fontSize: 13, color: AppColors.textGray)),
                                )
                              else
                                ..._history.asMap().entries.map((entry) {
                                  final i    = entry.key;
                                  final bill = entry.value;
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(bill.period,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                                            ),
                                            Text('៛ ${_fmt(bill.amount)}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.green.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: const Text('Paid',
                                                  style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.chevron_right, size: 18, color: AppColors.textGray),
                                          ],
                                        ),
                                      ),
                                      if (i < _history.length - 1)
                                        const Divider(height: 1, color: AppColors.border),
                                    ],
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  static String _fmt(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)},${(v % 1000).toInt().toString().padLeft(3, '0')}'
      : v.toInt().toString();

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'Water': return Icons.water_drop;
      case 'Electricity': return Icons.bolt;
      case 'Cooling': return Icons.ac_unit;
      default: return Icons.local_fire_department;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'Water': return AppColors.water;
      case 'Electricity': return AppColors.electricity;
      case 'Cooling': return AppColors.cooling;
      default: return AppColors.gas;
    }
  }
}

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textGray),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

final _shadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.06),
  blurRadius: 10,
  offset: const Offset(0, 3),
);
