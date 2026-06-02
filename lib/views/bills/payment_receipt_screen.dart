import 'package:flutter/material.dart';
import '../../core/config/app_colors.dart';
import '../../models/bill.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final String period;
  final List<Bill> bills;

  const PaymentReceiptScreen({
    super.key,
    required this.period,
    required this.bills,
  });

  double get _total => bills.fold(0, (s, b) => s + b.amount);
  String get _dueDate => bills.isNotEmpty ? bills.first.dueDate : '—';

  String get _receiptNo {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final clean = period.replaceAll(' Bill', '').trim().split(' ');
    if (clean.length >= 2) {
      final mIdx = months.indexOf(clean[0]);
      final yr = clean[1].length >= 4 ? clean[1].substring(2) : clean[1];
      final m = (mIdx + 1).toString().padLeft(2, '0');
      return 'REC-$yr$m';
    }
    return 'REC-000';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Receipt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textDark),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share coming soon'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [_shadow],
              ),
              child: Column(
                children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12), shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 38, color: AppColors.green),
                  ),
                  const SizedBox(height: 12),
                  const Text('Payment Successful',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(period, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
                  const SizedBox(height: 18),
                  Text('៛ ${_fmt(_total)}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.green),
                        SizedBox(width: 6),
                        Text('Paid',
                            style: TextStyle(fontSize: 13, color: AppColors.green,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Utility breakdown
            const Text('Breakdown',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [_shadow],
              ),
              child: bills.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No detail available.',
                            style: TextStyle(fontSize: 13, color: AppColors.textGray)),
                      ),
                    )
                  : Column(
                      children: bills.asMap().entries.map((entry) {
                        final i = entry.key;
                        final bill = entry.value;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: _typeColor(bill.type).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_typeIcon(bill.type), size: 20,
                                        color: _typeColor(bill.type)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(bill.type,
                                            style: const TextStyle(fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark)),
                                        if (bill.usage > 0 && bill.unit.isNotEmpty)
                                          Text('${bill.usage.toInt()} ${bill.unit}',
                                              style: const TextStyle(fontSize: 11,
                                                  color: AppColors.textGray)),
                                      ],
                                    ),
                                  ),
                                  Text('៛ ${_fmt(bill.amount)}',
                                      style: const TextStyle(fontSize: 15,
                                          fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                ],
                              ),
                            ),
                            if (i < bills.length - 1)
                              const Divider(height: 1, indent: 16, endIndent: 16,
                                  color: AppColors.border),
                          ],
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 20),

            // Receipt details
            const Text('Receipt Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
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
                  _detailRow('Receipt No', _receiptNo),
                  const _Divider(),
                  _detailRow('Period', period.replaceAll(' Bill', '')),
                  const _Divider(),
                  _detailRow('Due Date', _dueDate),
                  const _Divider(),
                  _detailRow('Status', 'Paid', valueColor: AppColors.green),
                  if (bills.isNotEmpty) ...[
                    const _Divider(),
                    const Text('Bill IDs',
                        style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                    const SizedBox(height: 8),
                    ...bills.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(_typeIcon(b.type), size: 14, color: _typeColor(b.type)),
                          const SizedBox(width: 8),
                          Text(b.id,
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark,
                                  fontFeatures: [FontFeature.tabularFigures()])),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF download coming soon'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2)),
                ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download Receipt',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textDark)),
      ],
    ),
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

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 20, color: AppColors.border);
}

final _shadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.06),
  blurRadius: 10,
  offset: const Offset(0, 3),
);
