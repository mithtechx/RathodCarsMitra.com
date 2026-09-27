import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xfakpdlbmhjwybhxozya.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmYWtwZGxibWhqd3liaHhvenlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1MDkxODQsImV4cCI6MjEwMjA4NTE4NH0.fEAhb66WicfHrzAM_5b55YdNU025fGf-rsXtzt-DLjU',
  );

  runApp(const RCMitraApp());
}