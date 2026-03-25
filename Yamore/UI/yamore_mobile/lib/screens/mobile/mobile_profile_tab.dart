import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../models/notification.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class MobileProfileTab extends StatefulWidget {
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
  State<MobileProfileTab> createState() => _MobileProfileTabState();
}

class _MobileProfileTabState extends State<MobileProfileTab> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _profileSaving = false;

  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _passwordSaving = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _notificationsLoading = false;
  List<NotificationModel> _notifications = const [];
  String? _notificationsError;

  AppUser get _user => widget.user;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: _user.firstName);
    _lastNameCtrl = TextEditingController(text: _user.lastName);
    _emailCtrl = TextEditingController(text: _user.email ?? '');
    _phoneCtrl = TextEditingController(text: _user.phone ?? '');

    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    if (_notificationsLoading) return;
    setState(() {
      _notificationsLoading = true;
      _notificationsError = null;
    });
    try {
      final paged = await _api.getNotifications(
        userId: _user.userId,
        page: 0,
        pageSize: 10,
        isRead: false,
      );
      if (!mounted) return;
      setState(() {
        _notifications = paged.resultList;
        _notificationsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationsLoading = false;
        _notificationsError = e.body;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationsLoading = false;
        _notificationsError = '$e';
      });
    }
  }

  String _formatDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.'
      '${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String _initials() {
    final f = _user.firstName.isNotEmpty ? _user.firstName[0] : '';
    final l = _user.lastName.isNotEmpty ? _user.lastName[0] : '';
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

  Future<void> _saveProfile() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      _showError('Validation error', 'First name and last name are required.');
      return;
    }
    setState(() => _profileSaving = true);
    try {
      final updated = await _api.updateProfile(
        userId: _user.userId,
        firstName: firstName,
        lastName: lastName,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      widget.authService.updateCurrentUser(updated);
      if (!mounted) return;
      setState(() => _profileSaving = false);
      _showSuccess('Profile updated', 'Your profile has been updated.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _profileSaving = false);
      _showError('Update failed', e.body);
    } catch (e) {
      if (!mounted) return;
      setState(() => _profileSaving = false);
      _showError('Error', '$e');
    }
  }

  Future<void> _changePassword() async {
    final oldPw = _oldPasswordCtrl.text;
    final newPw = _newPasswordCtrl.text;
    final confirmPw = _confirmPasswordCtrl.text;

    if (oldPw.isEmpty) {
      _showError('Validation error', 'Please enter your current password.');
      return;
    }
    if (newPw.isEmpty) {
      _showError('Validation error', 'Please enter a new password.');
      return;
    }
    if (newPw.length < 6) {
      _showError('Validation error', 'New password must be at least 6 characters.');
      return;
    }
    if (newPw != confirmPw) {
      _showError('Validation error', 'Passwords do not match.');
      return;
    }

    setState(() => _passwordSaving = true);
    try {
      await _api.changePassword(
        userId: _user.userId,
        oldPassword: oldPw,
        newPassword: newPw,
      );
      widget.authService.updatePassword(newPw);
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      if (!mounted) return;
      setState(() => _passwordSaving = false);
      _showSuccess('Password changed', 'Your password has been changed.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _passwordSaving = false);
      _showError('Password change failed', e.body);
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordSaving = false);
      _showError('Error', '$e');
    }
  }

  void _showError(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
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
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Profile',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _profileSaving ? null : _saveProfile,
              icon: _profileSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_profileSaving ? 'Saving...' : 'Save profile'),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Security',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Change password',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _oldPasswordCtrl,
                    obscureText: !_showOldPassword,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.key_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showOldPassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showOldPassword = !_showOldPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPasswordCtrl,
                    obscureText: !_showNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showNewPassword = !_showNewPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: !_showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _passwordSaving ? null : _changePassword,
                      icon: _passwordSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_reset, size: 18),
                      label: Text(
                        _passwordSaving ? 'Changing...' : 'Change password',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Notifications',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _notificationsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notificationsError != null
                      ? Text(
                          'Failed to load notifications: $_notificationsError',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        )
                      : _notifications.isEmpty
                          ? const Text('No new notifications.')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_notifications.length} new notification${_notifications.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ..._notifications.map(
                                  (n) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.notifications_active_outlined,
                                          color: AppTheme.primaryBlue),
                                      title: Text(
                                        n.message,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: n.createdAt != null
                                          ? Text(_formatDateTime(n.createdAt!))
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Account',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _infoTile(Icons.email_outlined, 'Email', user.email ?? '—'),
          _infoTile(Icons.phone_outlined, 'Phone', _formatPhone(user.phone)),
          _infoTile(
            Icons.circle,
            'Status',
            (user.status ?? true) ? 'Active' : 'Suspended',
            valueColor: (user.status ?? true) ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
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
      ),
    );
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
