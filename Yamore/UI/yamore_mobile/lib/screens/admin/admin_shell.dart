import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'yacht_review_screen.dart';

class AdminShell extends StatefulWidget {
  final AuthService authService;

  const AdminShell({super.key, required this.authService});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0; // Home selected by default

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Users',
    ),
    _NavItem(
      icon: Icons.directions_boat_outlined,
      selectedIcon: Icons.directions_boat,
      label: 'Yachts',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            backgroundColor: AppTheme.navBackground,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.sailing, color: Colors.white, size: 30),
                    SizedBox(height: 10),
                    Text(
                      'Yamore',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            destinations: _items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Container(
                    color: AppTheme.contentBackground,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    String sectionTitle;
    switch (_selectedIndex) {
      case 0:
        sectionTitle = 'Home';
        break;
      case 1:
        sectionTitle = 'Users';
        break;
      case 2:
        sectionTitle = 'Yachts';
        break;
      case 3:
        sectionTitle = 'Settings';
        break;
      default:
        sectionTitle = 'Yamore';
    }

    return Container(
      height: 56,
      color: AppTheme.navBackgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            sectionTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              const Text(
                'Administrator',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {
                  widget.authService.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return AdminHomeScreen(authService: widget.authService);
      case 1:
        return AdminUsersScreen(authService: widget.authService);
      case 2:
        return YachtReviewScreen(authService: widget.authService);
      case 3:
        return const Center(
          child: Text(
            'Settings\n\nHere you can configure admin preferences and global options in the future.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );
      default:
        return YachtReviewScreen(authService: widget.authService);
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
