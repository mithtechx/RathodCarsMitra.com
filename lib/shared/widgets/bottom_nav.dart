import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/passenger/home_screen.dart';
import '../../features/profile/profile_hub_screen.dart';
import '../../features/bookings/my_bookings_screen.dart'; // CORRECT

class MainBottomNavWrapper extends StatefulWidget {
  const MainBottomNavWrapper({super.key});

  @override
  State<MainBottomNavWrapper> createState() => _MainBottomNavWrapperState();
}

class _MainBottomNavWrapperState extends State<MainBottomNavWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MyBookingsScreen(), // Connected to real-time Supabase tickets stream
    const ProfileHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.cardWhite,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}