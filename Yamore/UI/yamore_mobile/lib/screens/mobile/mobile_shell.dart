import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import 'mobile_home_tab.dart';
import 'mobile_bookings_tab.dart';
import 'mobile_profile_tab.dart';
import 'mobile_my_yachts_tab.dart';

class MobileShell extends StatefulWidget {
  final AppUser user;
  final AuthService authService;

  const MobileShell({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selectedIndex = 0;

  late final List<_TabItem> _tabs;

  @override
  void initState() {
    super.initState();
    if (widget.user.isYachtOwner) {
      _tabs = [
        const _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
        const _TabItem(icon: Icons.directions_boat_outlined, activeIcon: Icons.directions_boat, label: 'My Yachts'),
        const _TabItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Bookings'),
        const _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
      ];
    } else {
      _tabs = [
        const _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
        const _TabItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'My Bookings'),
        const _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
      ];
    }
  }

  Widget _buildBody() {
    if (widget.user.isYachtOwner) {
      switch (_selectedIndex) {
        case 0:
          return MobileHomeTab(authService: widget.authService, user: widget.user);
        case 1:
          return MobileMyYachtsTab(authService: widget.authService);
        case 2:
          return MobileBookingsTab(authService: widget.authService, user: widget.user);
        case 3:
          return MobileProfileTab(authService: widget.authService, user: widget.user, onLogout: _logout);
        default:
          return MobileHomeTab(authService: widget.authService, user: widget.user);
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return MobileHomeTab(authService: widget.authService, user: widget.user);
        case 1:
          return MobileBookingsTab(authService: widget.authService, user: widget.user);
        case 2:
          return MobileProfileTab(authService: widget.authService, user: widget.user, onLogout: _logout);
        default:
          return MobileHomeTab(authService: widget.authService, user: widget.user);
      }
    }
  }

  void _logout() {
    widget.authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sailing, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Yamore',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
}
