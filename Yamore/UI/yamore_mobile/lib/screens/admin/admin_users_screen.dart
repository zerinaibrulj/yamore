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
        page: 0,
        pageSize: 100,
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
              onPressed: _loadUsers,
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primaryBlue),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(label: Text('First Name')),
            DataColumn(label: Text('Last Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Roles')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: _users
              .map(
                (u) => DataRow(
                  onSelectChanged: (selected) {
                    if (selected == true) {
                      _openEditUserDialog(u);
                    }
                  },
                  cells: [
                    DataCell(Text(u.firstName)),
                    DataCell(Text(u.lastName)),
                    DataCell(Text(u.email ?? '—')),
                    const DataCell(Text('')), // phone not in AppUser yet
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
                          color:
                              (u.status ?? true) ? Colors.green : Colors.redAccent,
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
                              color:
                                  (u.status ?? true) ? Colors.orange : Colors.green,
                            ),
                            tooltip:
                                (u.status ?? true) ? 'Suspend user' : 'Activate user',
                            onPressed: () => _toggleStatus(u),
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
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(AppUser user) async {
    final active = user.status ?? true;
    try {
      if (active) {
        await _api.suspendUser(user.userId);
      } else {
        await _api.activateUser(user.userId);
      }
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  void _openAddUserDialog() {
    // TODO: implement Add User dialog (next pass)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add User – dialog coming next.')),
    );
  }

  void _openEditUserDialog(AppUser user) {
    // TODO: implement Edit User dialog (next pass)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit User ${user.displayName} – dialog coming next.')),
    );
  }

  void _deleteUser(AppUser user) {
    // TODO: implement Delete User call (next pass)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete User ${user.displayName} – API call coming next.')),
    );
  }
}

