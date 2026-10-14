import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../bookings/my_bookings_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../driver/driver_manifest_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MyBookingsScreen(),
    const DriverManifestScreen(),
    const AdminDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryOrange,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarStyle(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number),
              label: 'My Bookings',
            ),
            BottomNavigationBarStyle(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Driver Manifest',
            ),
            BottomNavigationBarStyle(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin Panel',
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for clean bottom bar items
class BottomNavigationBarStyle extends BottomNavigationBarItem {
  const BottomNavigationBarStyle({
    required Widget icon,
    required Widget activeIcon,
    required String label,
  }) : super(
          icon: icon,
          activeIcon: activeIcon,
          label: label,
        );
}