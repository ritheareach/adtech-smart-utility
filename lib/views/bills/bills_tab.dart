import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../viewmodels/bills_viewmodel.dart';
import '../payment/payment_screen.dart';
import 'payment_receipt_screen.dart';

class BillsTab extends StatefulWidget {
  const BillsTab({super.key});

  @override
  State<BillsTab> createState() => _BillsTabState();
}

class _BillsTabState extends State<BillsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillsViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FC),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (vm.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            appBar: _buildAppBar(),
            body: _ErrorBody(error: vm.error!, onRetry: () => vm.load()),
          );
        }
        return _buildContent(context, vm);
      },
    );
  }

  Widget _buildContent(BuildContext context, BillsViewModel vm) {
    final total = vm.currentBills.fold<double>(0, (s, b) => s + b.amount);
    final firstBill = vm.currentBills.isNotEmpty ? vm.currentBills.first : null;
    final months = vm.sortedHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () => vm.load(),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
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
                              style: TextStyle(fontSize: 12, color: AppColors.orange,
                                  fontWeight: FontWeight.w600)),
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
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                                      color: AppColors.textDark)),
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
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AppColors.textDark)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: vm.currentBills.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PaymentScreen()),
                                ).then((_) {
                                  if (!mounted) return;
                                  vm.load();
                                }),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height: 12),
                    ...vm.currentBills.asMap().entries.map((entry) {
                      final i = entry.key;
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
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                                          color: AppColors.textDark)),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('៛ ${_fmt(bill.amount)}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                            color: AppColors.textDark)),
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
                                      style: TextStyle(fontSize: 11, color: AppColors.orange,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          if (i < vm.currentBills.length - 1)
                            const Divider(height: 1, color: AppColors.border),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment History — grouped by month
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [_shadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text('Payment History',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                    ),
                    if (months.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Text('No payment history yet.',
                            style: TextStyle(fontSize: 13, color: AppColors.textGray)),
                      )
                    else
                      ...months.asMap().entries.map((entry) {
                        final i = entry.key;
                        final period = entry.value.key;
                        final bills = entry.value.value;
                        final rowTotal = bills.fold<double>(0, (s, b) => s + b.amount);
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentReceiptScreen(period: period, bills: bills),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.green.withValues(alpha: 0.10),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.receipt_long_outlined, size: 18,
                                          color: AppColors.green),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(period,
                                              style: const TextStyle(fontSize: 14,
                                                  fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                          Text(
                                            '${bills.length} ${bills.length == 1 ? 'utility' : 'utilities'}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textGray),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text('៛ ${_fmt(rowTotal)}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                            color: AppColors.textDark)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.green.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('Paid',
                                          style: TextStyle(fontSize: 11, color: AppColors.green,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textGray),
                                  ],
                                ),
                              ),
                            ),
                            if (i < months.length - 1)
                              const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                          ],
                        );
                      }),
                    const SizedBox(height: 4),
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

  AppBar _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.menu, color: AppColors.textDark),
      onPressed: () {},
    ),
    title: const Text('Bills',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    centerTitle: true,
  );

  static String _fmt(double v) {
    final n = v.toInt();
    return n >= 1000
        ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}'
        : n.toString();
  }

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
