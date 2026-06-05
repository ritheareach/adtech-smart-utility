import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../auth/login_screen.dart';

class MoreTab extends StatelessWidget {
  final Function(int) onNavigate;
  const MoreTab({super.key, required this.onNavigate});

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
            GestureDetector(
              onTap: () => _showProfile(context, userName, unitNumber),
              child: Container(
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
                    Expanded(
                      child: Column(
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
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _MenuSection(title: 'Account', items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => _showProfile(context, userName, unitNumber),
              ),
              _MenuItem(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => _showComingSoon(context, 'Change Password'),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notification Settings',
                onTap: () => onNavigate(3),
              ),
            ]),
            const SizedBox(height: 16),
            _MenuSection(title: 'Utility', items: [
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                label: 'Payment History',
                onTap: () => onNavigate(2),
              ),
              _MenuItem(
                icon: Icons.download_outlined,
                label: 'Download Bills',
                onTap: () => _showComingSoon(context, 'Download Bills'),
              ),
              _MenuItem(
                icon: Icons.support_agent_outlined,
                label: 'Support',
                onTap: () => _showSupport(context),
              ),
            ]),
            const SizedBox(height: 16),
            _MenuSection(title: 'App', items: [
              _MenuItem(
                icon: Icons.info_outline,
                label: 'About ADTech',
                onTap: () => _showAbout(context),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => _showComingSoon(context, 'Privacy Policy'),
              ),
            ]),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => _signOut(context),
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

  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotificationsViewModel>().reset();
              context.read<AuthViewModel>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showProfile(BuildContext context, String name, String unit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primaryLight, size: 40),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            if (unit.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Unit $unit',
                  style: const TextStyle(fontSize: 14, color: AppColors.textGray)),
            ],
            const SizedBox(height: 4),
            const Text('Phnom Penh, Cambodia',
                style: TextStyle(fontSize: 13, color: AppColors.textGray)),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const _ProfileRow(icon: Icons.home_outlined, label: 'Location', value: 'Phnom Penh'),
            if (unit.isNotEmpty)
              _ProfileRow(icon: Icons.door_back_door_outlined, label: 'Unit Number', value: unit),
            const _ProfileRow(icon: Icons.verified_user_outlined, label: 'Account Status', value: 'Active'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ADTech',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 ADTech Smart Utility Management',
      children: const [
        SizedBox(height: 12),
        Text('ADTech is a smart utility management system that helps you monitor usage, '
            'manage bills and make secure payments for your utility services.',
            style: TextStyle(fontSize: 13)),
      ],
    );
  }

  void _showSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            const _SupportRow(icon: Icons.phone_outlined, label: 'Phone', value: '+855 23 000 000'),
            const Divider(),
            const _SupportRow(icon: Icons.email_outlined, label: 'Email', value: 'support@adtech.kh'),
            const Divider(),
            const _SupportRow(icon: Icons.access_time_outlined, label: 'Hours', value: 'Mon–Fri, 8am–5pm'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textGray),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.textDark)),
      ],
    ),
  );
}

class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SupportRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryLight),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
          ],
        ),
      ],
    ),
  );
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
                    onTap: item.onTap,
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
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, this.onTap});
}
