import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
class AdminSettingsScreen extends StatefulWidget {
  final AuthService authService;

  const AdminSettingsScreen({super.key, required this.authService});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
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

  _ConnectionStatus _connectionStatus = _ConnectionStatus.idle;
  String _connectionMessage = '';

  @override
  void initState() {
    super.initState();
    final user = widget.authService.currentUser;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

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

  Future<void> _saveProfile() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      _showErrorDialog('Validation Error', 'First name and last name are required.');
      return;
    }
    setState(() => _profileSaving = true);
    try {
      final updated = await _api.updateProfile(
        userId: widget.authService.currentUser!.userId,
        firstName: firstName,
        lastName: lastName,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      widget.authService.updateCurrentUser(updated);
      if (mounted) {
        setState(() => _profileSaving = false);
        await _showSuccessDialog('Profile Updated', 'Your profile has been updated successfully.');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _profileSaving = false);
        _showErrorDialog('Update Failed', 'Could not update profile.\n\n${e.displayMessage}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _profileSaving = false);
        _showErrorDialog('Error', '$e');
      }
    }
  }

  Future<void> _changePassword() async {
    final oldPw = _oldPasswordCtrl.text;
    final newPw = _newPasswordCtrl.text;
    final confirmPw = _confirmPasswordCtrl.text;

    if (oldPw.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter your current password.');
      return;
    }
    if (newPw.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter a new password.');
      return;
    }
    if (newPw.length < 6) {
      _showErrorDialog('Validation Error', 'New password must be at least 6 characters.');
      return;
    }
    if (newPw != confirmPw) {
      _showErrorDialog('Validation Error', 'Passwords do not match.');
      return;
    }

    setState(() => _passwordSaving = true);
    try {
      await _api.changePassword(
        userId: widget.authService.currentUser!.userId,
        oldPassword: oldPw,
        newPassword: newPw,
      );
      widget.authService.updatePassword(newPw);
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      if (mounted) {
        setState(() => _passwordSaving = false);
        await _showSuccessDialog('Password Changed', 'Your password has been changed successfully.');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _passwordSaving = false);
        _showErrorDialog('Password Change Failed', 'Could not change password.\n\n${e.displayMessage}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _passwordSaving = false);
        _showErrorDialog('Error', '$e');
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionStatus = _ConnectionStatus.testing;
      _connectionMessage = 'Testing connection...';
    });
    try {
      final elapsed = await _api.testConnection();
      if (mounted) {
        setState(() {
          _connectionStatus = _ConnectionStatus.success;
          _connectionMessage = 'Connected successfully (${elapsed.inMilliseconds} ms)';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = _ConnectionStatus.error;
          _connectionMessage = 'Connection failed: ${e.statusCode} ${e.displayMessage}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = _ConnectionStatus.error;
          _connectionMessage = 'Connection failed: $e';
        });
      }
    }
  }

  Future<void> _showSuccessDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 360, vertical: 240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4CAF50),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 360, vertical: 240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade600,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(
              icon: Icons.person_outline,
              title: 'Profile & Security',
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProfileCard(user, textTheme)),
                const SizedBox(width: 16),
                Expanded(child: _buildPasswordCard(textTheme)),
              ],
            ),

            const SizedBox(height: 32),

            _buildSectionHeader(
              icon: Icons.info_outline,
              title: 'Application Info',
            ),
            const SizedBox(height: 16),
            _buildAppInfoCard(textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(AppUser? user, TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    _initials(user),
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.username ?? '',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
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
                label: Text(_profileSaving ? 'Saving...' : 'Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: AppTheme.primaryBlue, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Change Password',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
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
                label:
                    Text(_passwordSaving ? 'Changing...' : 'Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(TextTheme textTheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        icon: Icons.person,
                        label: 'Logged in as',
                        value: widget.authService.currentUser?.displayName ??
                            widget.authService.username ??
                            '—',
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Roles',
                        value: widget.authService.currentUser?.roles.join(', ') ?? '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                _buildConnectionTestPanel(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionTestPanel() {
    Color statusColor;
    IconData statusIcon;
    switch (_connectionStatus) {
      case _ConnectionStatus.idle:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_outlined;
        break;
      case _ConnectionStatus.testing:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case _ConnectionStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done_outlined;
        break;
      case _ConnectionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.cloud_off_outlined;
        break;
    }

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 36, color: statusColor),
          const SizedBox(height: 10),
          Text(
            _connectionStatus == _ConnectionStatus.idle
                ? 'Backend Connection'
                : _connectionMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _connectionStatus == _ConnectionStatus.testing
                  ? null
                  : _testConnection,
              icon: _connectionStatus == _ConnectionStatus.testing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: statusColor,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                _connectionStatus == _ConnectionStatus.testing
                    ? 'Testing...'
                    : 'Test Connection',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(AppUser? user) {
    if (user == null) return '?';
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

enum _ConnectionStatus { idle, testing, success, error }
