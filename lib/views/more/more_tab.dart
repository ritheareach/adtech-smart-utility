import 'package:flutter/material.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/api_service.dart';
import '../auth/login_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = ApiService().userName;
    final unitNumber = ApiService().unitNumber;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('More',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1121), Color(0xFFAE162B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: const TextStyle(color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      if (unitNumber.isNotEmpty)
                        Text('Unit $unitNumber',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      const Text('Phnom Penh',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const _MenuSection(title: 'Account', items: [
              _MenuItem(icon: Icons.person_outline, label: 'Profile'),
              _MenuItem(icon: Icons.lock_outline, label: 'Change Password'),
              _MenuItem(icon: Icons.notifications_outlined, label: 'Notification Settings'),
            ]),
            const SizedBox(height: 16),
            const _MenuSection(title: 'Utility', items: [
              _MenuItem(icon: Icons.receipt_long_outlined, label: 'Payment History'),
              _MenuItem(icon: Icons.download_outlined, label: 'Download Bills'),
              _MenuItem(icon: Icons.support_agent_outlined, label: 'Support'),
            ]),
            const SizedBox(height: 16),
            const _MenuSection(title: 'App', items: [
              _MenuItem(icon: Icons.info_outline, label: 'About ADTech'),
              _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy'),
            ]),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppColors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('ADTech v1.0.0',
                style: TextStyle(fontSize: 12, color: AppColors.textGray)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                  color: AppColors.textGray)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 18, color: AppColors.primaryLight),
                    ),
                    title: Text(item.label,
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                    trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textGray),
                    onTap: () {},
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 68, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}
