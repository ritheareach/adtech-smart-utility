import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  static const _items = [
    _NotifItem(
      icon: Icons.warning_amber_rounded,
      color: AppColors.orange,
      bgColor: Color(0xFFFFF7ED),
      title: 'Payment Due Soon',
      body: 'Your May 2025 bill of ៛247,500 is due in 8 days.',
      time: '2 hours ago',
      unread: true,
    ),
    _NotifItem(
      icon: Icons.receipt_long,
      color: AppColors.primaryLight,
      bgColor: Color(0xFFEFF6FF),
      title: 'New Bill Generated',
      body: 'Your May 2025 utility bill has been generated.',
      time: '1 day ago',
      unread: true,
    ),
    _NotifItem(
      icon: Icons.check_circle,
      color: AppColors.green,
      bgColor: Color(0xFFF0FDF4),
      title: 'Payment Confirmed',
      body: 'Your Apr 2025 bill payment of ៛199,500 was successful.',
      time: '32 days ago',
      unread: false,
    ),
    _NotifItem(
      icon: Icons.bolt,
      color: AppColors.electricity,
      bgColor: Color(0xFFFFFBEB),
      title: 'High Electricity Usage',
      body: 'Your electricity usage is 0.2% higher than last month.',
      time: '5 days ago',
      unread: false,
    ),
    _NotifItem(
      icon: Icons.water_drop,
      color: AppColors.water,
      bgColor: Color(0xFFEFF6FF),
      title: 'Water Usage Alert',
      body: 'Water usage increased by 5.6% compared to last week.',
      time: '6 days ago',
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read',
                style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final item = _items[i];
          return Container(
            decoration: BoxDecoration(
              color: item.unread ? const Color(0xFFF0F7FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: item.unread
                  ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: item.unread ? FontWeight.bold : FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  if (item.unread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
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
                  Text(item.time,
                      style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String body;
  final String time;
  final bool unread;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
}
