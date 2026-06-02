import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';

class PaymentViewModel extends ChangeNotifier {
  bool retrying = false;
  String? syncError;

  Future<String?> recordPayment({
    required String tranId,
    required double amount,
    required List<String> billIds,
    String paymentOption = '',
  }) async {
    String? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await ApiService().createPayment(
          tranId: tranId,
          amount: amount,
          currency: 'KHR',
          paymentOption: paymentOption,
          billIds: billIds,
          paid: true,
        );
        return null;
      } catch (e) {
        lastError = e.toString();
        debugPrint('[Payment] backend sync attempt ${attempt + 1}/3 failed: $lastError');
        if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
      }
    }
    return lastError;
  }

  Future<String?> sandboxComplete(List<String> billIds) async {
    try {
      await ApiService().sandboxCompleteBill(billIds);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> retry({
    required String tranId,
    required double amount,
    required List<String> billIds,
  }) async {
    retrying = true;
    notifyListeners();
    final err = await recordPayment(tranId: tranId, amount: amount, billIds: billIds);
    syncError = err;
    retrying = false;
    notifyListeners();
  }

  void clearSyncError() {
    syncError = null;
    notifyListeners();
  }
}
