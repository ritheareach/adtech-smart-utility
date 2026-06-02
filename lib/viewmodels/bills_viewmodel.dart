import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/bill.dart';

class BillsViewModel extends ChangeNotifier {
  List<Bill> currentBills = [];
  List<Bill> paidBills = [];
  bool loading = false;
  String? error;

  List<MapEntry<String, List<Bill>>> get sortedHistory {
    final grouped = <String, List<Bill>>{};
    for (final b in paidBills) {
      grouped.putIfAbsent(_normalizeMonth(b.period), () => []).add(b);
    }
    return grouped.entries.toList()
      ..sort((a, b) => _periodKey(b.key).compareTo(_periodKey(a.key)));
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        ApiService().getCurrentBills(),
        ApiService().getAllBills(),
      ]);
      final all = results[1] as List<Bill>;
      currentBills = results[0] as List<Bill>;
      paidBills = all.where((b) => b.status == BillStatus.paid).toList();
      loading = false;
    } catch (e) {
      error = e.toString();
      loading = false;
    }
    notifyListeners();
  }

  // Extracts "MMM YYYY" from any period format the backend might return.
  static String _normalizeMonth(String period) {
    const abbr = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const full = ['January','February','March','April','May','June',
                  'July','August','September','October','November','December'];
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(period);
    if (yearMatch == null) return period.trim();
    final year = yearMatch.group(1)!;
    for (int i = 0; i < abbr.length; i++) {
      if (period.contains(abbr[i]) || period.contains(full[i])) {
        return '${abbr[i]} $year';
      }
    }
    final isoMatch = RegExp(r'(?:20\d{2}[/-](\d{2})|(\d{2})[/-]20\d{2})').firstMatch(period);
    if (isoMatch != null) {
      final m = int.tryParse(isoMatch.group(1) ?? isoMatch.group(2) ?? '0') ?? 0;
      if (m >= 1 && m <= 12) return '${abbr[m - 1]} $year';
    }
    return period.trim();
  }

  static int _periodKey(String period) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final parts = period.split(' ');
    if (parts.length < 2) return 0;
    final m = months.indexOf(parts[0]);
    final year = int.tryParse(parts[1]) ?? 0;
    return year * 12 + m;
  }
}
