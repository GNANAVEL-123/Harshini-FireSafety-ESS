import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/authentication.dart';
import 'package:harshinifireess/Utils/common_features.dart';
import 'package:harshinifireess/screens/homescreen.dart';
import 'package:flutter/cupertino.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _otpVerified = false;

  // 🔐 Hardcoded credentials (for testing)
  final String hardcodedUsername = "admin";
  final String hardcodedPassword = "1234";
  final String hardcodedOTP = "567890";

  String errorMessage = '';
  String otpMessage = '';
  bool _isloading = false;
  final hasInternet = false;

  @override
  void initState() {
    super.initState();

    CommonFeatures.checkInternetAvailable();
    CommonFeatures.requestLocationPermission();
  }

  // Future<void> InternetAvailable() async {
  //   final hasInternet = await CommonFeatures.checkInternetAvailable();

  //   if (!hasInternet) {
  //     print("No Internet");
  //     return;
  //   }

  //   print("Internet available");
  // }

  void _login() async {
  setState(() {
    _isloading = true;
    errorMessage = "";
  });

  bool internet = await CommonFeatures.checkInternetAvailable();

  if (!internet) {
    setState(() {
      errorMessage = "No Internet Connection";
      _isloading = false;
    });
    return;
  }

  bool siteActive = await Authentication.pingSite();

  if (!siteActive) {
    setState(() {
      errorMessage = "Unable to Reach Site";
      _isloading = false;
    });
    return;
  }

  final username = _usernameController.text.trim();
  final password = _passwordController.text.trim();
  final otp = _otpController.text.trim();

  final result = await Authentication.login(username, password, otp);

  if (result["success"] == true) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  } else {
    setState(() {
      errorMessage = result["error"];
      _isloading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔥 Logo / Icon
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Color(0xFFFFEBEE),
                      ),
                      child: Image.asset(
                        "assets/images/logo.jpg",
                        height: 80,
                        width: 80,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Harshini Fire Safety",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Secure Access Portal",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),

                    // 🧾 Username Field
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.grey,
                        ),
                        labelText: 'Username',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔑 Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔢 OTP Field
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.sms, color: Colors.grey),
                        labelText: 'Enter OTP',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 🔘 Login Button
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child:
                          _isloading
                              ? Center(
                                child: const CupertinoActivityIndicator(
                                  color: Colors.white,
                                  radius: 10,
                                ),
                              )
                              : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                    ),

                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Text(
                      "© 2025 Harshini Fire Safety",
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
