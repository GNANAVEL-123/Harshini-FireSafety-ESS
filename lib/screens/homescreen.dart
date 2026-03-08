import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harshinifireess/Utils/common_features.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:harshinifireess/screens/leadcreation.dart';
import 'package:harshinifireess/screens/leadlist.dart';
import 'package:harshinifireess/screens/leadoverview.dart';
import 'package:harshinifireess/screens/leave_application.dart';
import 'package:harshinifireess/screens/location_tracker.dart';
import 'package:harshinifireess/screens/login.dart';
import 'package:harshinifireess/screens/profile.dart';
import 'package:harshinifireess/screens/quotation_creation.dart';
import 'package:harshinifireess/Utils/authentication.dart';
import 'package:harshinifireess/screens/background_location_service.dart';
import 'package:harshinifireess/screens/quotation_list.dart';
import 'package:harshinifireess/screens/quotation_overview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fullName = "";
  String email = "";
  late Future<Map<String, dynamic>> userFuture;
  List<dynamic> followUps = [];
  String todayStatus = "NONE";
  bool isCheckInDisabled = false;
  bool isCheckOutDisabled = false;
  bool isCheckInLoading = false;
  bool isCheckOutLoading = false;
  final String baseUrl = dotenv.env['URL'] ?? 'Not Configured';


  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserDetails();
    userFuture = UserService.fetchUserProfile();
    fetchTodaysFollowups();
    fetchProfile();

    LocationTracker.init();

    loadCheckinStatus();
  }

  Future<void> fetchTodaysFollowups() async {
    try {
      final data = await UserService.fetchTodaysFollowups();
      setState(() {
        followUps = data;
      });
    } catch (e) {
      print("Error loading followups: $e");
    }
  }

  Future<void> fetchProfile() async {
    final result = await Authentication.fetchProfile();

    if (!mounted) return;

    if (result["success"] == true) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'default_company',
        result["data"]['default_company'] ?? '',
      );
      await prefs.setString(
        'default_tax_category',
        result["data"]['default_tax_category'] ?? '',
      );
      await prefs.setString(
        'default_sales_taxes_and_charges_template',
        result["data"]['default_sales_taxes_and_charges_template'] ?? '',
      );
      await prefs.setString(
        'default_price_list',
        result["data"]['default_price_list'] ?? '',
      );
      await prefs.setBool(
        'is_default_company_set',
        result["data"]['is_default_company_set'] ?? false,
      );
      await prefs.setBool(
        'is_default_tax_category_set',
        result["data"]['is_default_tax_category_set'] ?? false,
      );
      await prefs.setBool(
        'is_default_sales_taxes_and_charges_template_set',
        result["data"]['is_default_sales_taxes_and_charges_template_set'] ??
            false,
      );
      await prefs.setBool(
        'is_default_price_list_set',
        result["data"]['is_default_price_list_set'] ?? false,
      );

      return;
    }

    // ❌ Do NOT redirect if internet issue
    if (result["message"] == "Internet is Not Available") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Internet is Not Available"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ❌ Do NOT redirect if server unreachable
    if (result["message"] == "Unable to reach server") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Server not reachable"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Redirect ONLY if session expired
    if (result["message"] == "Session Inactive" ||
        result["message"] == "Token not found") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Please login again."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"] ?? "Something went wrong"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> refreshProfile() async {
    await fetchProfile();
    await fetchTodaysFollowups();

    await loadCheckinStatus();
  }

  Future<void> requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    if (permission != LocationPermission.always) {
      debugPrint("❌ Background location not granted");
    }
  }

  Future<void> loadCheckinStatus() async {
    try {
      final status = await UserService.fetchTodayCheckinStatus();

      setState(() {
        todayStatus = status;
        if (todayStatus == "NONE") {
          isCheckInDisabled = false;
          isCheckOutDisabled = false;
        } else if (todayStatus == "IN") {
          isCheckInDisabled = true;
          isCheckOutDisabled = false;
        } else if (todayStatus == "OUT") {
          isCheckInDisabled = true;
          isCheckOutDisabled = true;
        }
      });

      final service = FlutterBackgroundService();

      /// ✅ START tracking ONLY when checked IN
      if (todayStatus == "IN") {
        final isRunning = await service.isRunning();
        if (!isRunning) {
          await requestLocationPermissions();
          await service.startService();
          debugPrint("🟢 Background tracking STARTED");
        }
      }
      /// 🛑 STOP tracking when checked OUT or NONE
      else {
        service.invoke('stopService');
        debugPrint("🔴 Background tracking STOPPED");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  final actions = [
    {"icon": Icons.person_add, "label": "Add Lead", "page": LeadCreation()},

    {
      "icon": Icons.view_list_outlined,
      "label": "Lead List",
      "page": LeadList(),
    },
    {
      "icon": Icons.receipt_long,
      "label": "Add Quotation",
      "page": QuotationCreation(),
    },

    {
      "icon": Icons.list_sharp,
      "label": "Quotation List",
      "page": QuotationList(),
    },
  ];

  void showGreetingDialog(
    BuildContext context,
    String greeting,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade300,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.sentiment_satisfied_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          // textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  Future<void> loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      fullName = prefs.getString("fullname") ?? "Unknown User";
      email = prefs.getString("email") ?? "No Email";
    });
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning 🌞";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon ☀️";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening 🍂";
    } else {
      return "Good Night 🌙";
    }
  }

  String getFestivalGreeting() {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;

    // 🎉 Add festivals here
    if (month == 1 && day == 1) return "Happy New Year 🎉";
    if (month == 1 && day == 14) return "Happy Pongal 🌾";

    if (month == 5 && day == 1) return "Happy Labours Day💪";
    if (month == 8 && day == 15) return "Happy Independence Day 🇮🇳";
    // if (month == 10 && day == 31) return "Happy Halloween 🎃";
    // if (month == 11 && day == 12) return "Happy Diwali 🪔";
    if (month == 12 && day == 25) return "Merry Christmas 🎄";

    return ""; // No festival today
  }

  BoxDecoration getFestivalDecoration() {
    String greeting = getFestivalGreeting();

    if (greeting.contains("Pongal")) {
      return BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.yellow]),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
    }

    if (greeting.contains("Diwali")) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.orange],
        ),
      );
    }

    if (greeting.contains("Christmas")) {
      return BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.green, Colors.red]),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
    }

    if (greeting.contains("Independence")) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.white, Colors.green],
        ),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
    }

    // Default look
    return const BoxDecoration(color: Colors.white);
  }

  TextStyle getGreetingTextStyle(String greeting) {
    // ✅ Festival greeting
    if (greeting.contains("Happy") || greeting.contains("Merry")) {
      return const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.deepOrange, // highlight festival text
        shadows: [
          Shadow(blurRadius: 4, offset: Offset(1, 1), color: Colors.black26),
        ],
      );
    }

    // ✅ Normal greeting (Morning / Afternoon / Evening)
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.green,
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(text, style: const TextStyle(color: Colors.grey)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Colors.blue.shade50,
      onTap: onTap,
    );
  }

  String getMonthlyMotivation() {
    final now = DateTime.now();

    if (now.day != 1) return "";

    final monthlyMessages = {
      1: "Start the new year with confidence. You are capable of great things! 💪",
      2: "February: Short month, big goals. Keep moving forward! 🚀",
      3: "March: Let your progress bloom like spring! 🌸",
      4: "April: Be consistent — success loves discipline. ✅",
      5: "May: Every day is a new chance to succeed. 🌟",
      6: "June: Stay focused. Half the year, infinite possibilities! 🔥",
      7: "July: Push yourself. Great things take effort. 💼",
      8: "August: Believe in your journey. You’re growing! 🌱",
      9: "September: This is your month to level up! 📈",
      10: "October: Don’t fear failure — fear not trying. 💯",
      11: "November: Be grateful, stay consistent, grow stronger. 🙏",
      12: "December: Finish the year stronger than you started! 🏆",
    };

    return monthlyMessages[now.month]!;
  }

  Future<bool> ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If still denied, try once more
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If permanently denied, cannot ask again
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Widget build(BuildContext context) {
    final motivation = getMonthlyMotivation();
    final greetingText =
        getFestivalGreeting().isNotEmpty
            ? getFestivalGreeting()
            : getGreeting();

    ButtonStyle disabledButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade400,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
    );

    ButtonStyle enabledButtonStyle(Color color) {
      return ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      );
    }

    return Scaffold(
      appBar: AppBar(
        // title: Text('Welcome', style: TextStyle(color: Colors.white,
        // // fontFamily: 'Roboto'
        // fontFamily: 'Arial', // or 'Times New Roman', 'Georgia', 'Courier'
        // )),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFFFA000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              child: UserAccountsDrawerHeader(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFFFA000)],

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                accountName: Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                accountEmail: Text(
                  email,
                  style: TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    icon: Icons.person_2_sharp,
                    text: 'Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Profile()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.work_off_outlined,
                    text: 'Leave Application',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaveApplication(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.logout,
                    text: 'Log Out',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          baseUrl,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),

      // ----------------- Drawer Item Widget -----------------
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: refreshProfile,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.all(7),
                    padding: EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: getFestivalDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Text(
                                      greetingText,
                                      style: getGreetingTextStyle(greetingText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (motivation.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Text(
                              motivation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),

                        // 🔹 Inner White Section (Attendance)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Create Your Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed:
                                      (isCheckInDisabled || isCheckInLoading)
                                          ? null
                                          : () async {
                                            try {
                                              setState(
                                                () => isCheckInLoading = true,
                                              );

                                              await Authentication.validateConnection();
                                              await ensureLocationPermission();

                                              final pos =
                                                  await LocationTracker.getCurrentLocation();

                                              await UserService.createCheckIn(
                                                latitude: pos.latitude,
                                                longitude: pos.longitude,
                                              );

                                              // ✅ START BACKGROUND SERVICE
                                              final service =
                                                  FlutterBackgroundService();
                                              final isRunning =
                                                  await service.isRunning();
                                              if (!isRunning) {
                                                await requestLocationPermissions();

                                                await service.startService();
                                              }

                                              showGreetingDialog(
                                                context,
                                                "Welcome!",
                                                "Check-In Successful",
                                              );
                                            } catch (e) {
                                              showError(
                                                context,
                                                e
                                                    .toString()
                                                    .replaceAll(
                                                      "Exception:",
                                                      "",
                                                    )
                                                    .trim(),
                                              );
                                            } finally {
                                              setState(
                                                () => isCheckInLoading = false,
                                              );
                                              await loadCheckinStatus();
                                            }
                                          },
                                  icon: const Icon(
                                    Icons.login,
                                    color: Colors.white,
                                  ),
                                  label:
                                      isCheckInLoading
                                          ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'Check In',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  style:
                                      isCheckInDisabled
                                          ? disabledButtonStyle
                                          : enabledButtonStyle(Colors.green),
                                ),

                                ElevatedButton.icon(
                                  onPressed:
                                      (isCheckOutDisabled || isCheckOutLoading)
                                          ? null
                                          : () async {
                                            try {
                                              setState(
                                                () => isCheckOutLoading = true,
                                              );

                                              await Authentication.validateConnection();

                                              final pos =
                                                  await LocationTracker.getCurrentLocation();

                                              await UserService.createCheckOut(
                                                latitude: pos.latitude,
                                                longitude: pos.longitude,
                                              );

                                              // 🛑 STOP BACKGROUND SERVICE
                                              FlutterBackgroundService().invoke(
                                                'stopService',
                                              );

                                              showGreetingDialog(
                                                context,
                                                "Looking forward to meeting you next working day.",
                                                "Check Out created successfully!",
                                              );
                                            } catch (e) {
                                              showError(
                                                context,
                                                e
                                                    .toString()
                                                    .replaceAll(
                                                      "Exception:",
                                                      "",
                                                    )
                                                    .trim(),
                                              );
                                            } finally {
                                              setState(
                                                () => isCheckOutLoading = false,
                                              );
                                              await loadCheckinStatus();
                                            }
                                          },
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                  ),
                                  label:
                                      isCheckOutLoading
                                          ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'Check Out',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  style:
                                      isCheckOutDisabled
                                          ? disabledButtonStyle
                                          : enabledButtonStyle(
                                            Colors.redAccent,
                                          ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    color: Colors.white,
                    height: 150, // height for the row

                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: actions.length,
                      padding: const EdgeInsets.all(5),
                      itemBuilder: (context, index) {
                        final action = actions[index];
                        return Container(
                          width: 100,
                          height: 20,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              final page = action["page"];
                              if (page == null || page == "") {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Page not available"),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => page as Widget,
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.shade50,
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ), // smooth rounded box
                                  ),
                                  child: Icon(
                                    action["icon"] as IconData,
                                    color: Colors.deepOrange,
                                    size: 28,
                                  ),
                                ),

                                const SizedBox(height: 10),
                                Text(
                                  action["label"] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 🔹 Follow-up Header
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Today's Follow-ups",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey,
                                ),
                              ),
                              Icon(Icons.calendar_today, color: Colors.grey),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        followUps.isEmpty
                            ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.event_note_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "No follow-ups available",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Add a follow-up to track interactions",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: followUps.length,
                              itemBuilder: (context, index) {
                                final item = followUps[index];
                                return Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: Colors.grey,
                                      width: 1.2,
                                    ),
                                  ),
                                  elevation: 3,
                                  // margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: ListTile(
                                      onTap: () {
                                        if (item['parenttype'] == 'Lead') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => LeadOverview(
                                                    leadId: item['parent'],
                                                  ),
                                            ),
                                          );
                                        } else if (item['parenttype'] ==
                                            'Quotation') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => QuotationView(
                                                    quotationNo: item['parent'],
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      tileColor: Colors.white,
                                      leading: Icon(
                                        item['parenttype'] == 'Lead'
                                            ? Icons.person_outline
                                            : Icons.receipt_long,
                                        color:
                                            item['parenttype'] == 'Lead'
                                                ? Colors.orangeAccent
                                                : const Color(0xFF2980B9),
                                        size: 30,
                                      ),
                                      title: Text(
                                        item['party_name']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${item['parenttype']}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "${item['parent']}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              item['party_status'] == 'Open'
                                                  ? Colors.green.withOpacity(
                                                    0.1,
                                                  )
                                                  : Colors.amber.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                item['party_status'] == 'Open'
                                                    ? Colors.green
                                                    : Colors.amber,
                                          ),
                                        ),
                                        child: Text(
                                          item['party_status']!,
                                          style: TextStyle(
                                            color:
                                                item['party_status'] == 'Open'
                                                    ? Colors.green
                                                    : Colors.amber.shade800,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
