import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../models/notification.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/form_validators.dart';
import '../../widgets/user_notifications_inbox.dart';

class MobileProfileTab extends StatefulWidget {
  final AuthService authService;
  final AppUser user;
  final VoidCallback onLogout;
  /// Called after profile fields are saved so the shell can rebuild with [AuthService.currentUser].
  final VoidCallback? onProfileUpdated;

  const MobileProfileTab({
    super.key,
    required this.authService,
    required this.user,
    required this.onLogout,
    this.onProfileUpdated,
  });

  @override
  State<MobileProfileTab> createState() => _MobileProfileTabState();
}

class _MobileProfileTabState extends State<MobileProfileTab>
    with WidgetsBindingObserver {
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
  /// When false, password fields are hidden; profile save never requires a password.
  bool _wantsChangePassword = false;

  String? _errFirstName;
  String? _errLastName;
  String? _errEmail;
  String? _errPhone;
  String? _errOldPassword;
  String? _errNewPassword;
  String? _errConfirmPassword;

  bool _notificationsLoading = false;
  List<NotificationModel> _notifications = const [];
  String? _notificationsError;
  Timer? _notificationPoll;
  bool _notifInFlight = false;
  static const int _notifPageSize = 15;
  int? _notifTotalCount;
  int _notifNextPage = 0;
  bool _notifHasMore = false;
  bool _notifLoadingMore = false;
  int? _markingNotificationId;

  AppUser get _user => widget.user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _firstNameCtrl = TextEditingController(text: _user.firstName);
    _lastNameCtrl = TextEditingController(text: _user.lastName);
    _emailCtrl = TextEditingController(text: _user.email ?? '');
    _phoneCtrl = TextEditingController(text: _user.phone ?? '');

    _loadNotifications();
    _notificationPoll = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _loadNotifications(silent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications(silent: true);
    }
  }

  void _applyUserToControllers(AppUser u) {
    _firstNameCtrl.text = u.firstName;
    _lastNameCtrl.text = u.lastName;
    _emailCtrl.text = u.email ?? '';
    _phoneCtrl.text = u.phone ?? '';
  }

  @override
  void didUpdateWidget(covariant MobileProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = oldWidget.user;
    final n = widget.user;
    if (o.userId == n.userId &&
        (o.firstName != n.firstName ||
            o.lastName != n.lastName ||
            o.email != n.email ||
            o.phone != n.phone)) {
      _applyUserToControllers(n);
    }
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!mounted) return;
    if (_notifInFlight) return;
    _notifInFlight = true;
    if (!silent) {
      setState(() {
        _notificationsLoading = true;
        _notificationsError = null;
      });
    }
    try {
      final paged = await _api.getNotifications(
        userId: _user.userId,
        page: 0,
        pageSize: _notifPageSize,
      );
      if (!mounted) return;
      setState(() {
        _notifications = paged.resultList;
        _notifNextPage = 1;
        _notifTotalCount = paged.count;
        final t = paged.count;
        if (t != null) {
          _notifHasMore = _notifications.length < t;
        } else {
          _notifHasMore = paged.resultList.isNotEmpty &&
              paged.resultList.length >= _notifPageSize;
        }
        _notificationsError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _notificationsError = e.displayMessage;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _notificationsError = '$e';
        }
      });
    } finally {
      _notifInFlight = false;
      if (mounted) {
        setState(() {
          if (!silent) _notificationsLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (!mounted) return;
    if (_notifLoadingMore || _notifInFlight || !_notifHasMore) return;
    _notifInFlight = true;
    setState(() => _notifLoadingMore = true);
    try {
      final paged = await _api.getNotifications(
        userId: _user.userId,
        page: _notifNextPage,
        pageSize: _notifPageSize,
      );
      if (!mounted) return;
      setState(() {
        _notifications = [..._notifications, ...paged.resultList];
        _notifTotalCount = paged.count ?? _notifTotalCount;
        final t = paged.count;
        if (t != null) {
          _notifHasMore = _notifications.length < t;
        } else {
          _notifHasMore = paged.resultList.isNotEmpty &&
              paged.resultList.length >= _notifPageSize;
        }
        _notifNextPage = _notifNextPage + 1;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load more: ${e.displayMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load more: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _notifLoadingMore = false;
          _notifInFlight = false;
        });
      }
    }
  }

  Future<void> _markNotificationRead(NotificationModel n) async {
    if (n.isRead == true) return;
    if (!mounted) return;
    setState(() => _markingNotificationId = n.notificationId);
    try {
      await _api.markNotificationRead(n.notificationId);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map(
              (x) => x.notificationId == n.notificationId
                  ? x.copyWith(isRead: true)
                  : x,
            )
            .toList();
        _markingNotificationId = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _markingNotificationId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark as read: ${e.displayMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _markingNotificationId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark as read: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime d) {
    final local = notificationDisplayTime(d);
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  void _messageBelowFields(String text, {required bool isError}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _notificationPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() {
      _errFirstName = FormValidators.firstNameError(firstName);
      _errLastName = FormValidators.lastNameError(lastName);
      _errEmail = FormValidators.emailError(email);
      _errPhone = FormValidators.phoneError(phone);
    });
    if (_errFirstName != null ||
        _errLastName != null ||
        _errEmail != null ||
        _errPhone != null) {
      return;
    }

    setState(() => _profileSaving = true);
    try {
      final updated = await _api.updateProfile(
        userId: _user.userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );
      widget.authService.updateCurrentUser(updated);
      _applyUserToControllers(updated);
      if (!mounted) return;
      setState(() => _profileSaving = false);
      widget.onProfileUpdated?.call();
      _messageBelowFields(
        'Profile saved. Your name, email, and phone on file were updated.',
        isError: false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _profileSaving = false);
      _messageBelowFields(
        e.displayMessage,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _profileSaving = false);
      _messageBelowFields('Could not save profile: $e', isError: true);
    }
  }

  Future<void> _changePassword() async {
    if (!_wantsChangePassword) return;

    final oldPw = _oldPasswordCtrl.text;
    final newPw = _newPasswordCtrl.text;
    final confirmPw = _confirmPasswordCtrl.text;

    String? eOld;
    String? eNew;
    String? eConfirm;
    if (oldPw.isEmpty) {
      eOld = 'Enter your current password to confirm it is you.';
    }
    if (newPw.isEmpty) {
      eNew = 'Enter a new password, or turn off "I want to change my password" above to skip.';
    } else {
      eNew = FormValidators.newPasswordError(newPw);
    }
    if (newPw.isNotEmpty) {
      if (confirmPw.isEmpty) {
        eConfirm = 'Re-enter the new password in the confirmation field.';
      } else if (confirmPw != newPw) {
        eConfirm = 'Re-enter the same new password in both fields.';
      }
    }

    setState(() {
      _errOldPassword = eOld;
      _errNewPassword = eNew;
      _errConfirmPassword = eConfirm;
    });
    if (eOld != null || eNew != null || eConfirm != null) {
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
      setState(() {
        _passwordSaving = false;
        _wantsChangePassword = false;
        _errOldPassword = _errNewPassword = _errConfirmPassword = null;
      });
      _messageBelowFields(
        'Your password was changed. Use the new password next time you sign in.',
        isError: false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _passwordSaving = false);
      _messageBelowFields(e.displayMessage, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordSaving = false);
      _messageBelowFields('Password change failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return RefreshIndicator(
      onRefresh: () => _loadNotifications(silent: false),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'First name',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _errFirstName,
                  ),
                  onChanged: (_) => setState(() => _errFirstName = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lastNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Last name',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _errLastName,
                  ),
                  onChanged: (_) => setState(() => _errLastName = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: 'Email (optional)',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              errorText: _errEmail,
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _errEmail = null),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            decoration: InputDecoration(
              labelText: 'Phone (optional)',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              errorText: _errPhone,
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() => _errPhone = null),
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
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Password',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saving your profile (above) never changes your password. To change it, use the options below.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: _wantsChangePassword,
                    onChanged: _passwordSaving
                        ? null
                        : (v) {
                            setState(() {
                              _wantsChangePassword = v ?? false;
                              if (!_wantsChangePassword) {
                                _oldPasswordCtrl.clear();
                                _newPasswordCtrl.clear();
                                _confirmPasswordCtrl.clear();
                                _errOldPassword =
                                    _errNewPassword = _errConfirmPassword = null;
                              }
                            });
                          },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('I want to change my password'),
                  ),
                  if (_wantsChangePassword) ...[
                    const SizedBox(height: 4),
                    Text(
                      'You must enter your current password. The new password must be 8–128 characters and include upper, lower, a digit, and a special character (e.g. !@#).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _oldPasswordCtrl,
                      obscureText: !_showOldPassword,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: _errOldPassword,
                        prefixIcon: const Icon(Icons.key_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showOldPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showOldPassword = !_showOldPassword),
                        ),
                      ),
                      onChanged: (_) => setState(() => _errOldPassword = null),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPasswordCtrl,
                      obscureText: !_showNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: _errNewPassword,
                        prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showNewPassword = !_showNewPassword),
                        ),
                      ),
                      onChanged: (_) => setState(() => _errNewPassword = null),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordCtrl,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: _errConfirmPassword,
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
                      onChanged: (_) => setState(() => _errConfirmPassword = null),
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
                          _passwordSaving ? 'Changing...' : 'Update password',
                        ),
                      ),
                    ),
                  ],
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
              child: UserNotificationsInbox(
                  loading: _notificationsLoading,
                  error: _notificationsError,
                  notifications: _notifications,
                  formatDateTime: _formatDateTime,
                  markingNotificationId: _markingNotificationId,
                  onMarkRead: _markNotificationRead,
                  totalCount: _notifTotalCount,
                  hasMore: _notifHasMore,
                  loadingMore: _notifLoadingMore,
                  onLoadMore: _loadMoreNotifications,
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
