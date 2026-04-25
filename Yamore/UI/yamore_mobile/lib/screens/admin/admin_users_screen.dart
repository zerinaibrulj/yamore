import 'package:flutter/material.dart';
import '../../constants/app_role_names.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/form_validators.dart';

class AdminUsersScreen extends StatefulWidget {
  final AuthService authService;

  const AdminUsersScreen({super.key, required this.authService});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    auth: widget.authService,
  );

  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  List<AppUser> _users = [];
  int? _totalCount;
  int _currentPage = 0;
  final int _pageSize = 10;
  int? _selectedUserId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final name = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      String? roleName;
      switch (_roleFilter) {
        case 'Guests':
          roleName = ApiRoleNames.user;
          break;
        case 'Yacht owners':
          roleName = ApiRoleNames.yachtOwner;
          break;
        case 'Admins':
          roleName = ApiRoleNames.admin;
          break;
        default:
          roleName = null;
      }
      bool? status;
      switch (_statusFilter) {
        case 'Active':
          status = true;
          break;
        case 'Suspended':
          status = false;
          break;
        default:
          status = null;
      }

      final paged = await _api.getUsers(
        page: _currentPage,
        pageSize: _pageSize,
        name: name,
        roleName: roleName,
        status: status,
      );
      setState(() {
        _users = paged.resultList;
        _totalCount = paged.count;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = '${e.statusCode}: ${e.displayMessage}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'User review',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _openAddUserDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add User'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(context),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _roleFilter,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All roles')),
                  DropdownMenuItem(value: 'Guests', child: Text('Guests')),
                  DropdownMenuItem(
                      value: 'Yacht owners', child: Text('Yacht owners')),
                  DropdownMenuItem(value: 'Admins', child: Text('Admins')),
                ],
                onChanged: (val) {
                  setState(() {
                    _roleFilter = val ?? 'All';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(
                      value: 'Suspended', child: Text('Suspended')),
                ],
                onChanged: (val) {
                  setState(() {
                    _statusFilter = val ?? 'All';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () {
                _currentPage = 0;
                _loadUsers();
              },
              icon: const Icon(Icons.filter_list),
              label: const Text('Apply'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _roleFilter = 'All';
                  _statusFilter = 'All';
                  _currentPage = 0;
                });
                _loadUsers();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadUsers, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    final total = _totalCount ?? _users.length;
    final start = total == 0 ? 0 : _currentPage * _pageSize + 1;
    final end = (_currentPage * _pageSize + _users.length).clamp(0, total);
    final totalPages =
        total == 0 ? 1 : ((total + _pageSize - 1) / _pageSize).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(AppTheme.primaryBlue),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                columns: const [
                  DataColumn(label: Text('No.')),
                  DataColumn(label: Text('First Name')),
                  DataColumn(label: Text('Last Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Roles')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('')),
                ],
                rows: _users
                    .asMap()
                    .entries
                    .map(
                      (entry) {
                        final index = entry.key;
                        final u = entry.value;
                        final displayIndex =
                            _currentPage * _pageSize + index + 1;
                        return DataRow(
                        selected: _selectedUserId == u.userId,
                        onSelectChanged: (selected) {
                          setState(() {
                            _selectedUserId =
                                selected == true ? u.userId : null;
                          });
                        },
                        cells: [
                          DataCell(Text('$displayIndex.')),
                          DataCell(Text(u.firstName)),
                          DataCell(Text(u.lastName)),
                          DataCell(Text(u.email ?? '—')),
                          DataCell(Text(_formatPhone(u.phone))),
                          DataCell(
                            Wrap(
                              spacing: 4,
                              runSpacing: -8,
                              children: u.roles
                                  .map(
                                    (r) => Chip(
                                      label: Text(
                                        r,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          DataCell(
                            Text(
                              (u.status ?? true) ? 'Active' : 'Suspended',
                              style: TextStyle(
                                color: (u.status ?? true)
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit',
                                  onPressed: () => _openEditUserDialog(u),
                                ),
                                IconButton(
                                  icon: Icon(
                                    (u.status ?? true)
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                    color: (u.status ?? true)
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                  tooltip: (u.status ?? true)
                                      ? 'Suspend user'
                                      : 'Activate user',
                                  onPressed: () => _toggleStatus(u),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.warning_amber_outlined,
                                      color: Colors.amber),
                                  tooltip: 'Send warning',
                                  onPressed: () => _sendWarning(u),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteUser(u),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    total == 0
                        ? 'No records'
                        : 'Showing $start–$end of $total',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (total > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Page ${_currentPage + 1} of $totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    'Rows per page: $_pageSize',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadUsers();
                          }
                        : null,
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (_currentPage + 1) < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadUsers();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOperationSnackBar(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(AppUser user) async {
    final active = user.status ?? true;
    try {
      if (active) {
        await _api.suspendUser(user.userId);
        await _loadUsers();
        if (!mounted) return;
        _showOperationSnackBar(
          'User suspended',
          '${user.displayName} has been suspended successfully.',
        );
      } else {
        await _api.activateUser(user.userId);
        await _loadUsers();
        if (!mounted) return;
        _showOperationSnackBar(
          'User restored',
          '${user.displayName} has been restored successfully.',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _openAddUserDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _UserDialog(
          onSave: (firstName, lastName, email, phone, username, password,
              status, roleName) async {
            await _api.createUser(
              firstName: firstName,
              lastName: lastName,
              email: email,
              phone: phone,
              username: username,
              password: password,
              status: status,
              roleName: roleName,
            );
          },
        );
      },
    );
    if (created == true) {
      await _loadUsers();
      if (mounted) {
        _showOperationSnackBar(
          'User created',
          'The new user was added. They can sign in with the username and password you set.',
        );
      }
    }
  }

  Future<void> _openEditUserDialog(AppUser user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _UserDialog(
          existingUser: user,
          onSave: (firstName, lastName, email, phone, username, password,
              status, roleName) async {
            await _api.updateUser(
              userId: user.userId,
              firstName: firstName,
              lastName: lastName,
              email: email,
              phone: phone,
              status: status,
              password: password.isEmpty ? null : password,
            );
          },
        );
      },
    );
    if (updated == true) {
      await _loadUsers();
      if (mounted) {
        _showOperationSnackBar(
          'User updated',
          'The user account changes were saved.',
        );
      }
    }
  }

  Future<void> _sendWarning(AppUser user) async {
    final messageController = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('Send Warning'),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a warning notification to ${user.displayName}.',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Warning message',
                  hintText: 'Enter the warning message to send...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
    if (sent == true && messageController.text.trim().isNotEmpty) {
      try {
        await _api.sendWarningToUserAndOwners(
          userId: user.userId,
          message: messageController.text.trim(),
        );
        if (mounted) {
          _showOperationSnackBar(
            'Warning sent',
            'The warning has been sent to ${user.displayName}.',
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send warning: $e')),
          );
        }
      }
    }
    messageController.dispose();
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
            'Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteUser(user.userId);
        await _loadUsers();
        if (mounted) {
          _showOperationSnackBar(
            'User deleted',
            'The user was removed and can no longer sign in.',
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }
}

String _formatPhone(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= 3) return digits;
  if (digits.length <= 6) {
    return '${digits.substring(0, 3)}-${digits.substring(3)}';
  }
  final first = digits.substring(0, 3);
  final second = digits.substring(3, 6);
  final third = digits.substring(6);
  return '$first-$second-$third';
}

class _UserDialog extends StatefulWidget {
  final AppUser? existingUser;
  final Future<void> Function(String firstName, String lastName, String? email,
      String? phone, String username, String password, bool status, String? roleName) onSave;

  const _UserDialog({
    this.existingUser,
    required this.onSave,
  });

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController _firstNameController =
      TextEditingController(text: widget.existingUser?.firstName ?? '');
  late final TextEditingController _lastNameController =
      TextEditingController(text: widget.existingUser?.lastName ?? '');
  late final TextEditingController _emailController =
      TextEditingController(text: widget.existingUser?.email ?? '');
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.existingUser?.phone ?? '');
  late final TextEditingController _usernameController =
      TextEditingController(text: widget.existingUser?.username ?? '');
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _status = true;
  bool _saving = false;
  String _selectedRole = ApiRoleNames.user;
  /// Edit user only: when true, new password + confirm are shown and validated.
  bool _changeUserPassword = false;

  String? _eFirst;
  String? _eLast;
  String? _eEmail;
  String? _ePhone;
  String? _eUsername;
  String? _ePassword;
  String? _eConfirm;

  @override
  void initState() {
    super.initState();
    _status = widget.existingUser?.status ?? true;
    if (widget.existingUser != null) {
      if (widget.existingUser!.isAdmin) {
        _selectedRole = ApiRoleNames.admin;
      } else if (widget.existingUser!.isYachtOwner) {
        _selectedRole = ApiRoleNames.yachtOwner;
      } else {
        _selectedRole = ApiRoleNames.user;
      }
    } else {
      _selectedRole = ApiRoleNames.user;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateAndSetErrors() {
    final isEdit = widget.existingUser != null;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pw = _passwordController.text;
    final cfm = _confirmPasswordController.text;

    String? pErr;
    String? cErr;

    if (isEdit && !_changeUserPassword) {
      pErr = null;
      cErr = null;
    } else if (!isEdit) {
      pErr = FormValidators.createPasswordError(pw);
      if (pw != cfm) {
        cErr = 'Re-enter the same password to confirm. Both fields must match exactly.';
      }
    } else {
      if (pw.isEmpty && cfm.isEmpty) {
        pErr = 'Enter a new password in both fields, or turn off "Change password" to keep the current one.';
        cErr = null;
      } else if (pw.isNotEmpty && cfm.isEmpty) {
        cErr = 'Re-enter the new password in the confirmation field.';
        pErr = FormValidators.newPasswordError(pw);
      } else if (pw.isEmpty && cfm.isNotEmpty) {
        pErr = 'Enter the new password above, or turn off "Change password" to keep the current one.';
        cErr = null;
      } else {
        pErr = FormValidators.newPasswordError(pw);
        if (pw != cfm) {
          cErr = 'Re-enter the same new password in both fields.';
        }
      }
    }

    setState(() {
      _eFirst = FormValidators.firstNameError(firstName);
      _eLast = FormValidators.lastNameError(lastName);
      _eEmail = FormValidators.emailError(email);
      _ePhone = FormValidators.phoneError(phone);
      _eUsername = FormValidators.usernameError(username);
      _ePassword = pErr;
      _eConfirm = cErr;
    });

    return _eFirst == null &&
        _eLast == null &&
        _eEmail == null &&
        _ePhone == null &&
        _eUsername == null &&
        _ePassword == null &&
        _eConfirm == null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingUser != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit user' : 'Add user'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First name',
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: _eFirst,
                      ),
                      onChanged: (_) => setState(() => _eFirst = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last name',
                        prefixIcon: const Icon(Icons.person),
                        errorText: _eLast,
                      ),
                      onChanged: (_) => setState(() => _eLast = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ApiRoleNames.user,
                    child: Text('Guest / End user'),
                  ),
                  DropdownMenuItem(
                    value: ApiRoleNames.yachtOwner,
                    child: Text('Yacht owner'),
                  ),
                  DropdownMenuItem(
                    value: ApiRoleNames.admin,
                    child: Text('Admin'),
                  ),
                ],
                onChanged: widget.existingUser == null
                    ? (val) {
                        setState(() {
                          _selectedRole = val ?? ApiRoleNames.user;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _eEmail,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _eEmail = null),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone (optional)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        errorText: _ePhone,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() => _ePhone = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      enabled: !isEdit,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                        errorText: _eUsername,
                      ),
                      onChanged: (_) => setState(() => _eUsername = null),
                    ),
                  ),
                ],
              ),
              if (isEdit) ...[
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: _changeUserPassword,
                  onChanged: _saving
                      ? null
                      : (v) {
                          setState(() {
                            _changeUserPassword = v ?? false;
                            if (!_changeUserPassword) {
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _ePassword = null;
                              _eConfirm = null;
                            }
                          });
                        },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text("Change this user's password"),
                ),
              ],
              if (!isEdit || _changeUserPassword) ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'New password' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _ePassword,
                  ),
                  onChanged: (_) => setState(() {
                    _ePassword = null;
                    _eConfirm = null;
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Confirm new password' : 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _eConfirm,
                  ),
                  onChanged: (_) => setState(() {
                    _ePassword = null;
                    _eConfirm = null;
                  }),
                ),
                const SizedBox(height: 8),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active account'),
                value: _status,
                onChanged: (val) {
                  setState(() {
                    _status = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_validateAndSetErrors()) {
                    return;
                  }

                  final firstName = _firstNameController.text.trim();
                  final lastName = _lastNameController.text.trim();
                  final username = _usernameController.text.trim();
                  final password = isEdit && !_changeUserPassword
                      ? ''
                      : _passwordController.text;

                  setState(() {
                    _saving = true;
                  });
                  try {
                    await widget.onSave(
                      firstName,
                      lastName,
                      _emailController.text.trim().isEmpty
                          ? null
                          : _emailController.text.trim(),
                      _phoneController.text.trim().isEmpty
                          ? null
                          : _phoneController.text.trim(),
                      username,
                      password,
                      _status,
                      widget.existingUser == null ? _selectedRole : null,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } on ApiException catch (e) {
                    setState(() {
                      _saving = false;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.displayMessage),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() {
                      _saving = false;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save user: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Save changes' : 'Create user'),
        ),
      ],
    );
  }
}

