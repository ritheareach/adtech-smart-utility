import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/bill.dart';
import '../models/usage_data.dart';

class DashboardViewModel extends ChangeNotifier {
  List<Bill> bills = [];
  List<UsageSummary> summaries = [];
  List<String> chartLabels = [];
  List<double> chartTotals = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        ApiService().getCurrentBills(),
        ApiService().getUsageSummary(period: 'month'),
        ApiService().getMonthlyTotals(),
        ApiService().loadUserProfile(),
      ]);
      final chart = results[2] as Map<String, dynamic>;
      bills = results[0] as List<Bill>;
      summaries = results[1] as List<UsageSummary>;
      chartLabels = chart['labels'] as List<String>;
      chartTotals = chart['totals'] as List<double>;
      loading = false;
    } catch (e) {
      error = e.toString();
      loading = false;
    }
    notifyListeners();
  }
}
