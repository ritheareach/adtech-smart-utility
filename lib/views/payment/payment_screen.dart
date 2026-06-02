import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../models/bill.dart';
import '../../viewmodels/bills_viewmodel.dart';
import 'khqr_screen.dart';
import 'card_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? _selectedBillIndex;

  Bill? get _selectedBill {
    final vm = context.read<BillsViewModel>();
    if (_selectedBillIndex == null || _selectedBillIndex! >= vm.currentBills.length) return null;
    return vm.currentBills[_selectedBillIndex!];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BillsViewModel>();
      if (vm.currentBills.isEmpty) vm.load();
    });
  }

  void _selectMethod(String method) {
    final bill = _selectedBill;
    if (bill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bill first'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (method == 'card') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CardPaymentScreen(bill: bill)));
    } else {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => KhqrScreen(bill: bill, method: method)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillsViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Review and Pay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            centerTitle: true,
          ),
          body: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Bill to Pay:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      const SizedBox(height: 10),

                      ...vm.currentBills.asMap().entries.map((entry) {
                        final i = entry.key;
                        final bill = entry.value;
                        final isSelected = _selectedBillIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedBillIndex = i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryLight : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [_shadow],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 22, height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? AppColors.primaryLight : AppColors.border,
                                              width: 2,
                                            ),
                                            color: isSelected ? AppColors.primaryLight : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.circle, color: Colors.white, size: 10)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(
                                            color: _typeColor(bill.type).withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(_typeIcon(bill.type), size: 18,
                                              color: _typeColor(bill.type)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(bill.type,
                                                  style: const TextStyle(fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textDark)),
                                              Text(bill.period,
                                                  style: const TextStyle(fontSize: 11,
                                                      color: AppColors.textGray)),
                                            ],
                                          ),
                                        ),
                                        Container(width: 1, height: 36, color: AppColors.border),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('៛ ${_fmt(bill.amount)}',
                                                style: const TextStyle(fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textDark)),
                                            Text('${bill.usage.toInt()} ${bill.unit}',
                                                style: const TextStyle(fontSize: 11,
                                                    color: AppColors.textGray)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(height: 1, color: AppColors.border),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: AppColors.orange.withValues(alpha: 0.4)),
                                          ),
                                          child: const Text('Unpaid',
                                              style: TextStyle(fontSize: 10, color: AppColors.orange,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Bill ID: ${bill.id}',
                                            style: const TextStyle(fontSize: 11,
                                                color: AppColors.textGray)),
                                        const Spacer(),
                                        Text('Due on ${bill.dueDate}',
                                            style: const TextStyle(fontSize: 11,
                                                color: AppColors.orange,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      if (_selectedBill != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('You have selected:',
                                        style: TextStyle(fontSize: 12,
                                            color: AppColors.primaryLight,
                                            fontWeight: FontWeight.w600)),
                                    Text('Bill ID: ${_selectedBill!.id}',
                                        style: const TextStyle(fontSize: 12,
                                            color: AppColors.textGray)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Total Amount',
                                      style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                                  Text('៛ ${_fmt(_selectedBill!.amount)}',
                                      style: const TextStyle(fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Text('Select Payment Method:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      const SizedBox(height: 10),

                      _PayMethodRow(
                        icon: const _AbaKhqrIcon(),
                        title: 'ABA KHQR',
                        subtitle: 'Scan to pay with any banking app',
                        onTap: () => _selectMethod('aba_khqr'),
                      ),
                      const SizedBox(height: 10),
                      _PayMethodRow(
                        icon: const _CardIcon(),
                        title: 'Credit/Debit Card',
                        subtitle: 'VISA, Mastercard, UnionPay, JCB',
                        logosWidget: const _CardLogos(),
                        onTap: () => _selectMethod('card'),
                      ),
                      const SizedBox(height: 10),
                      _PayMethodRow(
                        icon: const _AlipayIcon(),
                        title: 'Alipay',
                        subtitle: 'Scan to pay with Alipay',
                        onTap: () => _selectMethod('alipay'),
                      ),
                      const SizedBox(height: 10),
                      _PayMethodRow(
                        icon: const _WechatIcon(),
                        title: 'WeChat',
                        subtitle: 'Scan to pay with WeChat',
                        onTap: () => _selectMethod('wechat'),
                      ),
                      const SizedBox(height: 32),

                      const Center(
                        child: Column(
                          children: [
                            Text('Secured by ABA PayWay',
                                style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ChipBadge('VISA', Color(0xFF1A1F71), Colors.white),
                                SizedBox(width: 6),
                                _ChipBadge('MC', Color(0xFFEB001B), Colors.white),
                                SizedBox(width: 6),
                                _ChipBadge('UPI', Color(0xFF6D1ED4), Colors.white),
                                SizedBox(width: 6),
                                _ChipBadge('JCB', Color(0xFF003087), Colors.white),
                                SizedBox(width: 6),
                                _ChipBadge('KHQR', Color(0xFFCC0000), Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
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

class _PayMethodRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Widget? logosWidget;
  final VoidCallback onTap;

  const _PayMethodRow({
    required this.icon, required this.title, required this.subtitle,
    this.logosWidget, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [_shadow],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  logosWidget ??
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGray, size: 22),
          ],
        ),
      ),
    );
  }
}

class _AbaKhqrIcon extends StatelessWidget {
  const _AbaKhqrIcon();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48, height: 48,
      child: Stack(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFF002B5C),
                borderRadius: BorderRadius.circular(10)),
            child: const Center(
              child: Text('ABA',
                  style: TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: const BoxDecoration(
                color: Color(0xFFCC0000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4), bottomRight: Radius.circular(10),
                ),
              ),
              child: const Text('KHQR',
                  style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  const _CardIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.credit_card, color: Colors.white, size: 26),
  );
}

class _AlipayIcon extends StatelessWidget {
  const _AlipayIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(color: const Color(0xFF1677FF),
        borderRadius: BorderRadius.circular(10)),
    child: const Center(
      child: Text('支', style: TextStyle(color: Colors.white, fontSize: 22,
          fontWeight: FontWeight.bold)),
    ),
  );
}

class _WechatIcon extends StatelessWidget {
  const _WechatIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(color: const Color(0xFF07C160),
        borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.chat_bubble, color: Colors.white, size: 24),
  );
}

class _CardLogos extends StatelessWidget {
  const _CardLogos();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _ChipBadge('VISA', Color(0xFF1A1F71), Colors.white),
      SizedBox(width: 4),
      _ChipBadge('MC', Color(0xFFEB001B), Colors.white),
      SizedBox(width: 4),
      _ChipBadge('UPI', Color(0xFF6D1ED4), Colors.white),
      SizedBox(width: 4),
      _ChipBadge('JCB', Color(0xFF003087), Colors.white),
    ],
  );
}

class _ChipBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _ChipBadge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold)),
  );
}

final _shadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.05),
  blurRadius: 8, offset: const Offset(0, 2),
);
