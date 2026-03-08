import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationTracker with WidgetsBindingObserver {
  static Timer? _timer;
  static bool _isRunning = false;
  static bool _isForeground = true;

  static void init() {
    WidgetsBinding.instance.addObserver(_LifecycleHandler());
  }

  static Future<void> startTracking() async {

    final prefs = await SharedPreferences.getInstance();



    final bool allowTracking = prefs.getBool("allow_tracking") ?? false;

    final int frequency = prefs.getInt("frequency") ?? 10;




    if (!allowTracking) {


      return;

    }




    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic( Duration(seconds: frequency ), (timer) async {
      if (!_isForeground) return;

      try {
        final Position position = await getCurrentLocation();

        await UserService.sendLocationLog(
          lat: position.latitude,
          lng: position.longitude,
        );

        print("✅ Sent: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("❌ Location Error: $e");
      }
    });

    print("✅ Location tracking started (${frequency} sec interval)");
  }

  static Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;

    print("🛑 Tracking stopped");
  }

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          "Location permission permanently denied. Enable it from settings.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String> getAddressFromPosition(Position pos) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (placemarks.isEmpty) return "Unknown location";

    final place = placemarks.first;

    return [
      place.name,
      place.street,
      place.locality,
      place.administrativeArea,
      place.postalCode
    ].where((e) => e != null && e.isNotEmpty).join(", ");
  }

  static void _setForeground(bool value) {
    _isForeground = value;
    print("App Foreground: $_isForeground");
  }
}

class _LifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationTracker._setForeground(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      LocationTracker._setForeground(false);
    }
  }
}
