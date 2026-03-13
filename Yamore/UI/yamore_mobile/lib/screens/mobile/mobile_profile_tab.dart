import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class MobileProfileTab extends StatelessWidget {
  final AuthService authService;
  final AppUser user;
  final VoidCallback onLogout;

  const MobileProfileTab({
    super.key,
    required this.authService,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: Text(
              _initials(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.roles.join(', '),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _infoTile(Icons.email_outlined, 'Email', user.email ?? '—'),
          _infoTile(Icons.phone_outlined, 'Phone', _formatPhone(user.phone)),
          _infoTile(
            Icons.circle,
            'Status',
            (user.status ?? true) ? 'Active' : 'Suspended',
            valueColor: (user.status ?? true) ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials() {
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  String _formatPhone(String? raw) {
    if (raw == null) return '—';
    final digits = raw.replaceAll(RegExp(r'\\D'), '');
    if (digits.length == 9) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return raw;
  }

  Widget _infoTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
