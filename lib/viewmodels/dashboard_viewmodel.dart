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

  int _loadGen = 0;

  Future<void> load() async {
    final gen = ++_loadGen;
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
      if (gen != _loadGen) return; // a newer load started; discard this stale result
      final chart = results[2] as Map<String, dynamic>;
      bills = results[0] as List<Bill>;
      summaries = results[1] as List<UsageSummary>;
      chartLabels = chart['labels'] as List<String>;
      chartTotals = chart['totals'] as List<double>;
      loading = false;
    } catch (e) {
      if (gen != _loadGen) return;
      error = e.toString();
      loading = false;
    }
    notifyListeners();
  }

  // Immediately removes paid bills from the local list so the UI updates
  // without waiting for the next network load.
  void removePaidBills(List<String> ids) {
    bills = bills.where((b) => !ids.contains(b.id)).toList();
    notifyListeners();
  }
}
