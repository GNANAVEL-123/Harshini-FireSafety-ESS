import 'package:flutter/material.dart';

import 'package:harshinifireess/Utils/authentication.dart';
import 'package:harshinifireess/screens/homescreen.dart';
import 'package:harshinifireess/screens/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkTokenAndProceed();
  }

  Future<void> checkTokenAndProceed() async {
    bool ok = await Authentication.isTokenActive();

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
