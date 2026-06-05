import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../models/notification_item.dart';
import '../../viewmodels/notifications_viewmodel.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<NotificationsViewModel>();
      if (vm.items.isEmpty && !vm.loading) vm.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            centerTitle: true,
            actions: [
              if (vm.hasUnread)
                TextButton(
                  onPressed: vm.markAllRead,
                  child: const Text('Mark all read',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
                ),
            ],
          ),
          body: _buildBody(context, vm),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationsViewModel vm) {
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textGray),
              const SizedBox(height: 12),
              Text(vm.error!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: vm.load,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryLight),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, size: 56, color: AppColors.textGray),
            SizedBox(height: 12),
            Text('No notifications yet',
                style: TextStyle(fontSize: 14, color: AppColors.textGray)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final item = vm.items[i];
          return _NotifCard(
            item: item,
            onTap: () => vm.markRead(item.id),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  const _NotifCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(item.type);
    final bgColor = _bgColorForType(item.type);
    final icon = _iconForType(item.type);
    final time = _relativeTime(item.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.read ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          border: item.read
              ? null
              : Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(item.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: item.read ? FontWeight.w600 : FontWeight.bold,
                        color: AppColors.textDark)),
              ),
              if (!item.read)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryLight, shape: BoxShape.circle),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(item.body,
                  style: const TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.4)),
              const SizedBox(height: 4),
              Text(time,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    final months = diff.inDays ~/ 30;
    return '$months month${months == 1 ? '' : 's'} ago';
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'payment_due': return Icons.warning_amber_rounded;
      case 'payment_overdue': return Icons.error_rounded;
      case 'bill_generated': return Icons.receipt_long;
      case 'payment_confirmed': return Icons.check_circle;
      case 'usage_high': return Icons.trending_up;
      case 'usage_low': return Icons.trending_down;
      default: return Icons.notifications;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'payment_due': return AppColors.orange;
      case 'payment_overdue': return AppColors.red;
      case 'bill_generated': return AppColors.primaryLight;
      case 'payment_confirmed': return AppColors.green;
      case 'usage_high': return AppColors.electricity;
      case 'usage_low': return AppColors.green;
      default: return AppColors.textGray;
    }
  }

  static Color _bgColorForType(String type) {
    switch (type) {
      case 'payment_due': return const Color(0xFFFFF7ED);
      case 'payment_overdue': return const Color(0xFFFEF2F2);
      case 'bill_generated': return const Color(0xFFEFF6FF);
      case 'payment_confirmed': return const Color(0xFFF0FDF4);
      case 'usage_high': return const Color(0xFFFFFBEB);
      case 'usage_low': return const Color(0xFFF0FDF4);
      default: return const Color(0xFFF3F4F6);
    }
  }
}
