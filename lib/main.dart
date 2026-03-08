import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:harshinifireess/screens/login.dart';
import 'package:harshinifireess/screens/splash.dart';
import 'package:harshinifireess/screens/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harshinifireess/screens/background_location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("base_url", dotenv.env['URL'] ?? "");

  await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(),
    );
  }
}
