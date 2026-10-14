import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project credentials
  await Supabase.initialize(
    url: 'https://hcqvtqjnhzqtoottogug.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjcXZ0cWpuaHpxdG9vdHRvZ3VnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5MTM3NDQsImV4cCI6MjEwNjQ4OTc0NH0.W2Rz9l_8mKPeQzqIlXadaa4uWxtbG9Hni_n0vwEm1dY',
  );

  runApp(const RathodCarsMitraRoot());
}

class RathodCarsMitraRoot extends StatelessWidget {
  const RathodCarsMitraRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rathod Cars Mitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        // Root domain (rathodcarsmitra.com) loads your website landing/blog page
        '/': (context) => const WebsiteLandingPage(),
        // Loads your main app wrapper (MainBottomNavWrapper) when user clicks book ride
        '/app': (context) => const MainBottomNavWrapper(),
      },
    );
  }
}

// Website Landing Page with Blog Info & Booking CTA
class WebsiteLandingPage extends StatelessWidget {
  const WebsiteLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rathod Cars Mitra | Intercity Cab & Travel Blog'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Rathod Cars Mitra',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Explore our intercity travel guides, company updates, and book comfortable rides instantly.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  // Navigates into your app's main booking navigation wrapper
                  Navigator.pushNamed(context, '/app');
                },
                child: const Text('Book a Ride Now', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}