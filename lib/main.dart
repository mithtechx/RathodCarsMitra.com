import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with project credentials
  await Supabase.initialize(
    url: 'https://hcqvtqjnhzqtoottogug.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjcXZ0cWpuaHpxdG9vdHRvZ3VnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5MTM3NDQsImV4cCI6MjEwNjQ4OTc0NH0.W2Rz9l_8mKPeQzqIlXadaa4uWxtbG9Hni_n0vwEm1dY',
  );

  runApp(const RathodCarsMitraApp());
}

class RathodCarsMitraApp extends StatelessWidget {
  const RathodCarsMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rathod Cars Mitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainBottomNavWrapper(),
    );
  }
}