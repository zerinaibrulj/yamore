import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../models/paged_users.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  final AuthService authService;

  const AdminUsersScreen({super.key, required this.authService});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
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
          roleName = 'User';
          break;
        case 'Yacht owners':
          roleName = 'YachtOwner';
          break;
        case 'Admins':
          roleName = 'Admin';
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
        _error = '${e.statusCode}: ${e.body}';
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

  Future<void> _toggleStatus(AppUser user) async {
    final active = user.status ?? true;
    try {
      if (active) {
        await _api.suspendUser(user.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.displayName} has been suspended.')),
          );
        }
      } else {
        await _api.activateUser(user.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.displayName} has been activated.')),
          );
        }
      }
      await _loadUsers();
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
        await _showSuccessDialog(
          context,
          title: 'User created',
          message: 'The new user has been added successfully.',
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
        await _showSuccessDialog(
          context,
          title: 'User updated',
          message: 'The user has been updated successfully.',
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
          await _showSuccessDialog(
            context,
            title: 'Warning sent',
            message: 'The warning has been sent to ${user.displayName}.',
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
          await _showSuccessDialog(
            context,
            title: 'User deleted',
            message: 'The user has been deleted successfully.',
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

Future<void> _showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
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
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
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
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
      );
    },
  );
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

  bool _status = true;
  bool _saving = false;
  String _selectedRole = 'User';

  Future<void> _showInvalidDataDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid data'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _status = widget.existingUser?.status ?? true;
    if (widget.existingUser != null) {
      if (widget.existingUser!.isAdmin) {
        _selectedRole = 'Admin';
      } else if (widget.existingUser!.isYachtOwner) {
        _selectedRole = 'YachtOwner';
      } else {
        _selectedRole = 'User';
      }
    } else {
      _selectedRole = 'User';
    }
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
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person_outline),
                        suffixIcon: _buildValidationIcon(
                          _isFirstNameValid,
                          _firstNameController.text,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last name',
                        prefixIcon: Icon(Icons.person),
                        suffixIcon: _buildValidationIcon(
                          _isLastNameValid,
                          _lastNameController.text,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
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
                    value: 'User',
                    child: Text('Guest / End user'),
                  ),
                  DropdownMenuItem(
                    value: 'YachtOwner',
                    child: Text('Yacht owner'),
                  ),
                  DropdownMenuItem(
                    value: 'Admin',
                    child: Text('Admin'),
                  ),
                ],
                onChanged: widget.existingUser == null
                    ? (val) {
                        setState(() {
                          _selectedRole = val ?? 'User';
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: _buildValidationIcon(
                    _isEmailValid,
                    _emailController.text,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        suffixIcon: _buildValidationIcon(
                          _isPhoneValid,
                          _phoneController.text,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
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
                        suffixIcon: _buildValidationIcon(
                          _isUsernameValid,
                          _usernameController.text,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'New password (optional)' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: _buildValidationIcon(
                    _isPasswordValid,
                    _passwordController.text,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
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
                  final firstName = _firstNameController.text.trim();
                  final lastName = _lastNameController.text.trim();
                  final username = _usernameController.text.trim();
                  final password = _passwordController.text;

                  if (firstName.isEmpty || lastName.isEmpty || username.isEmpty) {
                    await _showInvalidDataDialog(
                      'Please enter valid data before creating a user. '
                      'First name, last name and username are required.',
                    );
                    return;
                  }
                  if (firstName.length < 2 || firstName.length > 50) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('First name must be between 2 and 50 characters.'),
                      ),
                    );
                    return;
                  }
                  if (lastName.length < 2 || lastName.length > 50) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Last name must be between 2 and 50 characters.'),
                      ),
                    );
                    return;
                  }
                  if (!_isUsernameValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Username must be 3-32 characters and contain only letters, numbers, '.', '_' or '-'.",
                        ),
                      ),
                    );
                    return;
                  }
                  if (_emailController.text.trim().isNotEmpty && !_isEmailValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid email address.'),
                      ),
                    );
                    return;
                  }
                  if (_phoneController.text.trim().isNotEmpty && !_isPhoneValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid phone number.'),
                      ),
                    );
                    return;
                  }
                  if (!isEdit && password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password is required when creating a user.')),
                    );
                    return;
                  }
                  if (password.isNotEmpty && !_isPasswordValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password must be at least 8 characters long and include uppercase, lowercase, digit, and special character.',
                        ),
                      ),
                    );
                    return;
                  }

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
                  } catch (e) {
                    setState(() {
                      _saving = false;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save user: $e')),
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
  
  bool get _isEmailValid {
    final value = _emailController.text.trim();
    if (value.isEmpty) return false;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value) && value.length <= 100;
  }

  bool get _isFirstNameValid {
    final value = _firstNameController.text.trim();
    return value.length >= 2 && value.length <= 50;
  }

  bool get _isLastNameValid {
    final value = _lastNameController.text.trim();
    return value.length >= 2 && value.length <= 50;
  }

  bool get _isPasswordValid {
    final value = _passwordController.text;
    if (value.isEmpty) return false;
    if (value.length < 8 || value.length > 128) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[^a-zA-Z0-9]').hasMatch(value);
    return hasLower && hasUpper && hasDigit && hasSpecial;
  }

  bool get _isUsernameValid {
    final value = _usernameController.text.trim();
    if (value.isEmpty) return false;
    final usernameRegex = RegExp(r'^[a-zA-Z0-9._-]{3,32}$');
    return usernameRegex.hasMatch(value);
  }

  bool get _isPhoneValid {
    final value = _phoneController.text.trim();
    if (value.isEmpty) return false;
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
    return phoneRegex.hasMatch(value);
  }

  Widget? _buildValidationIcon(bool isValid, String value) {
    if (value.trim().isEmpty) return null;
    return Icon(
      isValid ? Icons.check_circle : Icons.cancel,
      color: isValid ? Colors.green : Colors.red.shade400,
      size: 18,
    );
  }
}

