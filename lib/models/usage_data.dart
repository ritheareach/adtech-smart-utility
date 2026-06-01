class UsageSummary {
  final String type;
  final double value;
  final String unit;
  final double changePercent;
  final bool isUp;

  const UsageSummary({
    required this.type,
    required this.value,
    required this.unit,
    required this.changePercent,
    required this.isUp,
  });
}

class MonthlyUsage {
  final String month;
  final double water;
  final double electricity;
  final double gas;
  final double cooling;
  // 2026 comparison data
  final double electricity2026;
  final double water2026;
  final double gas2026;
  final double cooling2026;

  const MonthlyUsage({
    required this.month,
    required this.water,
    required this.electricity,
    required this.gas,
    required this.cooling,
    required this.electricity2026,
    required this.water2026,
    required this.gas2026,
    required this.cooling2026,
  });
}

class MockData {
  static const weekSummaries = [
    UsageSummary(type: 'Water', value: 8, unit: 'm³', changePercent: 5.6, isUp: true),
    UsageSummary(type: 'Electricity', value: 45, unit: 'kWh', changePercent: 0.2, isUp: true),
    UsageSummary(type: 'Gas', value: 4, unit: 'L', changePercent: 1.2, isUp: false),
    UsageSummary(type: 'Cooling', value: 25, unit: 'kWh', changePercent: 1.2, isUp: false),
  ];

  static const monthSummaries = [
    UsageSummary(type: 'Water', value: 25, unit: 'm³', changePercent: 5.6, isUp: true),
    UsageSummary(type: 'Electricity', value: 122, unit: 'kWh', changePercent: 0.2, isUp: true),
    UsageSummary(type: 'Gas', value: 18, unit: 'L', changePercent: 1.2, isUp: false),
    UsageSummary(type: 'Cooling', value: 215, unit: 'kWh', changePercent: 0.2, isUp: true),
  ];

  static const monthlyHistory = [
    MonthlyUsage(month: 'Jan', water: 22, electricity: 110, gas: 15, cooling: 200, electricity2026: 120, water2026: 24, gas2026: 16, cooling2026: 210),
    MonthlyUsage(month: 'Feb', water: 20, electricity: 118, gas: 17, cooling: 205, electricity2026: 124, water2026: 22, gas2026: 17, cooling2026: 215),
    MonthlyUsage(month: 'Mar', water: 26, electricity: 125, gas: 16, cooling: 198, electricity2026: 126, water2026: 27, gas2026: 15, cooling2026: 205),
    MonthlyUsage(month: 'Apr', water: 24, electricity: 130, gas: 14, cooling: 210, electricity2026: 122, water2026: 25, gas2026: 14, cooling2026: 208),
    MonthlyUsage(month: 'May', water: 25, electricity: 122, gas: 18, cooling: 215, electricity2026: 128, water2026: 26, gas2026: 17, cooling2026: 220),
    MonthlyUsage(month: 'Jun', water: 28, electricity: 135, gas: 19, cooling: 222, electricity2026: 130, water2026: 28, gas2026: 19, cooling2026: 225),
    MonthlyUsage(month: 'Jul', water: 30, electricity: 140, gas: 17, cooling: 230, electricity2026: 125, water2026: 29, gas2026: 18, cooling2026: 218),
    MonthlyUsage(month: 'Aug', water: 27, electricity: 128, gas: 16, cooling: 218, electricity2026: 122, water2026: 26, gas2026: 16, cooling2026: 212),
    MonthlyUsage(month: 'Sep', water: 23, electricity: 115, gas: 15, cooling: 205, electricity2026: 120, water2026: 24, gas2026: 15, cooling2026: 208),
    MonthlyUsage(month: 'Oct', water: 21, electricity: 112, gas: 14, cooling: 195, electricity2026: 118, water2026: 22, gas2026: 14, cooling2026: 200),
    MonthlyUsage(month: 'Nov', water: 24, electricity: 118, gas: 16, cooling: 200, electricity2026: 122, water2026: 25, gas2026: 16, cooling2026: 205),
    MonthlyUsage(month: 'Dec', water: 26, electricity: 122, gas: 18, cooling: 210, electricity2026: 124, water2026: 27, gas2026: 18, cooling2026: 215),
  ];

  // Monthly bill totals for the Total Bills chart
  static const monthlyBillTotals = [
    199500.0, 220000.0, 198500.0, 215000.0, 277500.0,
    285000.0, 290000.0, 275000.0, 260000.0, 255000.0, 265000.0, 272000.0,
  ];
}
