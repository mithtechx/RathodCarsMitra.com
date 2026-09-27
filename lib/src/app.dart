import 'package:flutter/material.dart';
import 'routing/app_router.dart';

class RCMitraApp extends StatelessWidget {
  const RCMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rathod Cars Mitra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F6F0),
        primaryColor: const Color(0xFFD95325),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD95325),
          primary: const Color(0xFFD95325),
          surface: const Color(0xFFF8F6F0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F6F0),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}