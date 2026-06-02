import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/notification_item.dart';

class NotificationsViewModel extends ChangeNotifier {
  List<NotificationItem> items = [];
  bool loading = false;
  String? error;

  bool get hasUnread => items.any((n) => !n.read);
  int get unreadCount => items.where((n) => !n.read).length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await ApiService().getNotifications();
      loading = false;
    } catch (e) {
      error = e.toString();
      loading = false;
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final idx = items.indexWhere((n) => n.id == id);
    if (idx == -1 || items[idx].read) return;
    items[idx] = items[idx].copyWith(read: true);
    notifyListeners();
    try {
      await ApiService().markNotificationRead(id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (!hasUnread) return;
    final unreadIds = items.where((n) => !n.read).map((n) => n.id).toList();
    for (int i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(read: true);
    }
    notifyListeners();
    try {
      await ApiService().markAllNotificationsRead(unreadIds);
    } catch (_) {}
  }
}
