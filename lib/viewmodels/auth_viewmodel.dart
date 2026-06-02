import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  bool loading = false;
  String? error;
  String? devOtp;

  Future<bool> sendOtp(String phone) async {
    loading = true;
    error = null;
    devOtp = null;
    notifyListeners();
    try {
      final res = await ApiService().sendOtp(phone);
      devOtp = res['otp'] as String?;
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await ApiService().verifyOtp(phone, code);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    ApiService().clearToken();
    notifyListeners();
  }
}
