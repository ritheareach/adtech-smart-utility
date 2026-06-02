import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../models/usage_data.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/adtech_logo.dart';
import '../payment/payment_screen.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback? onGoToNotifications;
  const DashboardTab({super.key, this.onGoToNotifications});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<DashboardViewModel>();
      if (!vm.loading) vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
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

  Widget _buildContent(BuildContext context, DashboardViewModel vm) {
    final totalDue = vm.bills.fold<double>(0, (s, b) => s + b.amount);
    final nonZero = vm.chartTotals.where((v) => v > 0).toList();
    final chartMax = nonZero.isEmpty ? 310000.0 : nonZero.reduce((a, b) => a > b ? a : b) * 1.2;
    final chartMin = nonZero.isEmpty ? 0.0 : nonZero.reduce((a, b) => a < b ? a : b) * 0.8;

    const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final periodLabel = '${monthNames[prevMonth - 1]} $prevYear';

    final hour = now.hour;
    final tod = hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : 'Evening';
    final greeting = 'Good $tod, ${ApiService().userName}!';

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
              // Greeting card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [_shadow],
                ),
                child: Row(
                  children: [
                    const AdtechLogo(size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(
                            ApiService().unitNumber.isNotEmpty
                                ? 'Unit ${ApiService().unitNumber} • Phnom Penh'
                                : 'Phnom Penh',
                            style: const TextStyle(fontSize: 11, color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Payment alert
              if (vm.bills.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PaymentScreen()))
                    .then((_) { if (context.mounted) vm.load(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, size: 18, color: AppColors.orange),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment Alert!',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                      color: AppColors.orange)),
                              Text('You have payments due. Please review.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.orange, size: 20),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),

              // Usage Overview
              const Text('Usage Overview',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 10),
              if (vm.summaries.isNotEmpty)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: vm.summaries
                      .map((s) => _UsageCard(summary: s, periodLabel: periodLabel))
                      .toList(),
                ),
              const SizedBox(height: 18),

              // Usage this Month + Amount Due
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [_shadow],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Usage — $periodLabel',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 10),
                          ...vm.summaries.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(_typeIcon(s.type), size: 16, color: _typeColor(s.type)),
                                const SizedBox(width: 6),
                                Text('${s.value.toInt()} ${s.unit}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                                const SizedBox(width: 4),
                                Icon(s.isUp ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 10, color: s.isUp ? AppColors.red : AppColors.green),
                                Text('${s.changePercent}%',
                                    style: TextStyle(fontSize: 10,
                                        color: s.isUp ? AppColors.red : AppColors.green,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 110, color: AppColors.border),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount Due',
                            style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                        const SizedBox(height: 4),
                        Text('៛ ${_fmt(totalDue)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const PaymentScreen()))
                            .then((_) { if (context.mounted) vm.load(); }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Pay Now',
                                style: TextStyle(fontSize: 12, color: AppColors.orange,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Total Bills chart
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
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E), shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.attach_money, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Bills',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                      color: AppColors.textDark)),
                              Text('Last 12 Months',
                                  style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '៛ ${_fmt(vm.chartTotals.fold(0.0, (s, v) => s + v))}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  color: AppColors.green),
                            ),
                            const Text('total paid',
                                style: TextStyle(fontSize: 10, color: AppColors.textGray)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (vm.chartLabels.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (vm.chartLabels.length - 1).toDouble(),
                            minY: chartMin, maxY: chartMax,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= vm.chartLabels.length) return const SizedBox();
                                    if (idx % 2 != 0) return const SizedBox();
                                    return Text(vm.chartLabels[idx],
                                        style: const TextStyle(fontSize: 9, color: AppColors.textGray));
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(vm.chartLabels.length,
                                    (i) => FlSpot(i.toDouble(), vm.chartTotals[i])),
                                isCurved: true,
                                color: AppColors.green,
                                barWidth: 2,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                    radius: 3, color: AppColors.green,
                                    strokeWidth: 0, strokeColor: AppColors.green,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.green.withValues(alpha: 0.15),
                                      AppColors.green.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
    title: const Text('Dashboard',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    centerTitle: true,
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark),
        onPressed: widget.onGoToNotifications,
      ),
    ],
  );

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'Water': return Icons.water_drop_outlined;
      case 'Electricity': return Icons.bolt;
      case 'Cooling': return Icons.ac_unit;
      default: return Icons.local_fire_department_outlined;
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

  static String _fmt(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _UsageCard extends StatelessWidget {
  final UsageSummary summary;
  final String periodLabel;
  const _UsageCard({required this.summary, this.periodLabel = 'Last month'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_icon, size: 20, color: _color),
              const SizedBox(width: 6),
              Text(summary.type,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              const Spacer(),
              Text('${summary.value.toInt()} ${summary.unit}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(periodLabel, style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
              const SizedBox(width: 4),
              Icon(summary.isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 10, color: summary.isUp ? AppColors.red : AppColors.green),
              Text('${summary.changePercent}%',
                  style: TextStyle(fontSize: 10,
                      color: summary.isUp ? AppColors.red : AppColors.green,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (summary.type) {
      case 'Water': return Icons.water_drop;
      case 'Electricity': return Icons.bolt;
      case 'Cooling': return Icons.ac_unit;
      default: return Icons.local_fire_department;
    }
  }

  Color get _color {
    switch (summary.type) {
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
