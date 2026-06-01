import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_colors.dart';
import '../models/usage_data.dart';
import '../models/bill.dart';
import '../services/api_service.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _selectedType = 0; // 0=Electricity,1=Water,2=Gas,3=Cooling
  final _types = ['Electricity', 'Water', 'Gas', 'Cooling'];

  List<MonthlyUsage> _monthly2025 = [];
  List<MonthlyUsage> _monthly2026 = [];
  List<Bill> _billRecords = [];
  bool _loading = true;
  String? _error;

  final int _currentYear  = DateTime.now().year;
  late  int _previousYear = DateTime.now().year - 1;

  @override
  void initState() {
    super.initState();
    _previousYear = _currentYear - 1;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        ApiService().getMonthlyUsage(year: _previousYear),
        ApiService().getMonthlyUsage(year: _currentYear),
        ApiService().getAllBills(),
      ]);
      if (!mounted) return;
      setState(() {
        _monthly2025 = results[0] as List<MonthlyUsage>;
        _monthly2026 = results[1] as List<MonthlyUsage>;
        _billRecords = results[2] as List<Bill>;
        _loading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<double> get _values2025 => _monthly2025.map((m) {
    switch (_selectedType) {
      case 1: return m.water;
      case 2: return m.gas;
      case 3: return m.cooling;
      default: return m.electricity;
    }
  }).toList();

  List<double> get _values2026 => _monthly2026.map((m) {
    switch (_selectedType) {
      case 1: return m.water;
      case 2: return m.gas;
      case 3: return m.cooling;
      default: return m.electricity;
    }
  }).toList();

  String get _unit {
    switch (_selectedType) {
      case 1: return 'm³';
      case 2: return 'L';
      default: return 'kWh';
    }
  }

  Color get _color2025 {
    switch (_selectedType) {
      case 1: return AppColors.water;
      case 2: return AppColors.gas;
      case 3: return AppColors.cooling;
      default: return const Color(0xFF7C3AED); // purple
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textGray),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final data2025 = _values2025;
    final data2026 = _values2026;
    final allVals  = [...data2025, ...data2026];
    final maxY = allVals.isEmpty ? 150.0 : allVals.reduce((a, b) => a > b ? a : b) * 1.1;
    final minY = allVals.isEmpty ? 0.0   : allVals.reduce((a, b) => a < b ? a : b) * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4-tab selector
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [_shadow],
              ),
              child: Row(
                children: List.generate(_types.length, (i) {
                  final selected = i == _selectedType;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selected ? _colorForIndex(i) : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Text(
                            _types[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textGray,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),

            // Chart card
            Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
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
                      Text(
                        'Usage Trend ($_unit)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const Spacer(),
                      // 2025 legend
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: _color2025, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('$_previousYear', style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                      const SizedBox(width: 10),
                      // current year legend
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('$_currentYear', style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                      const SizedBox(width: 10),
                      // Monthly dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Monthly', style: TextStyle(fontSize: 10, color: AppColors.textGray)),
                            SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textGray),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minX: 0, maxX: 11,
                        minY: minY, maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (maxY - minY) / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppColors.border.withValues(alpha: 0.5),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: (maxY - minY) / 4,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(fontSize: 9, color: AppColors.textGray),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (v, _) {
                                const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                                final idx = v.toInt();
                                if (idx < 0 || idx >= months.length) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(months[idx],
                                      style: const TextStyle(fontSize: 9, color: AppColors.textGray)),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // 2025 line
                          LineChartBarData(
                            spots: List.generate(12, (i) => FlSpot(i.toDouble(), data2025[i])),
                            isCurved: true,
                            color: _color2025,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: _color2025,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [_color2025.withValues(alpha: 0.1), _color2025.withValues(alpha: 0.0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // 2026 line
                          LineChartBarData(
                            spots: List.generate(12, (i) => FlSpot(i.toDouble(), data2026[i])),
                            isCurved: true,
                            color: const Color(0xFFF97316),
                            barWidth: 2.5,
                            dashArray: [4, 3],
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFFF97316),
                              ),
                            ),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Usage & Bill Records
            const Text(
              'Usage & Bill Records',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [_shadow],
              ),
              child: Column(
                children: _billRecords.asMap().entries.map((entry) {
                  final i = entry.key;
                  final bill = entry.value;
                  final isPaid = bill.status == BillStatus.paid;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _typeColor(bill.type).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_typeIcon(bill.type), size: 18, color: _typeColor(bill.type)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${bill.type} - ${bill.period}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                  Text('Bill ID: ${bill.id}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('៛ ${_fmt(bill.amount)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                Text('${bill.usage.toInt()} ${bill.unit}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? AppColors.green.withValues(alpha: 0.12)
                                    : AppColors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: isPaid ? null : Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                isPaid ? 'Paid' : 'Unpaid',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isPaid ? AppColors.green : AppColors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isPaid) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 16, color: AppColors.textGray),
                            ],
                          ],
                        ),
                      ),
                      if (i < _billRecords.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                    ],
                  );
                }).toList(),
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
    title: const Text(
      'Analytics',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
    ),
    centerTitle: true,
  );

  Color _colorForIndex(int i) {
    switch (i) {
      case 1: return AppColors.water;
      case 2: return AppColors.gas;
      case 3: return AppColors.cooling;
      default: return const Color(0xFF7C3AED);
    }
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

final _shadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.06),
  blurRadius: 10,
  offset: const Offset(0, 3),
);
