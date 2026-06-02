import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/bill.dart';
import '../models/usage_data.dart';

class AnalyticsViewModel extends ChangeNotifier {
  int selectedType = 0;
  static const List<String> types = ['Electricity', 'Water', 'Gas', 'Cooling'];

  List<MonthlyUsage> monthly2025 = [];
  List<MonthlyUsage> monthly2026 = [];
  List<Bill> billRecords = [];
  bool loading = false;
  String? error;

  final int _currentYear = DateTime.now().year;
  int get currentYear => _currentYear;
  int get previousYear => _currentYear - 1;

  void selectType(int index) {
    selectedType = index;
    notifyListeners();
  }

  List<double> get values2025 => _extractValues(monthly2025);
  List<double> get values2026 => _extractValues(monthly2026);

  List<double> _extractValues(List<MonthlyUsage> data) => data.map((m) {
    switch (selectedType) {
      case 1: return m.water;
      case 2: return m.gas;
      case 3: return m.cooling;
      default: return m.electricity;
    }
  }).toList();

  String get unit {
    switch (selectedType) {
      case 1: return 'm³';
      case 2: return 'L';
      default: return 'kWh';
    }
  }

  List<Bill> get filteredBillRecords =>
      billRecords.where((b) => b.type == types[selectedType]).toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        ApiService().getMonthlyUsage(year: previousYear),
        ApiService().getMonthlyUsage(year: currentYear),
        ApiService().getAllBills(),
      ]);
      monthly2025 = results[0] as List<MonthlyUsage>;
      monthly2026 = results[1] as List<MonthlyUsage>;
      billRecords = results[2] as List<Bill>;
      loading = false;
    } catch (e) {
      error = e.toString();
      loading = false;
    }
    notifyListeners();
  }
}
