import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/user_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (_) async => false,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_tracking',
      initialNotificationTitle: 'Location Tracking Active',
      initialNotificationContent: 'Tracking location in background',
      foregroundServiceNotificationId: 888,
    ),
  );
}
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final geolocator = GeolocatorPlatform.instance;

  Timer? timer;

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  timer = Timer.periodic(
    Duration(seconds: prefs.getInt("frequency") ?? 10),
    (t) async {
      final allowTracking = prefs.getBool("allow_tracking") ?? false;
      if (!allowTracking) return;

      try {
        final permission = await geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint("❌ Location permission denied in background");
          return;
        }

        final position = await geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  ),
);


        await UserService.sendLocationLog(
          lat: position.latitude,
          lng: position.longitude,
        );

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Location Tracking Active",
            content:
                "Lat: ${position.latitude}, Lng: ${position.longitude}",
          );
        }
      } catch (e, s) {
        debugPrint("❌ Background Location Error: $e");
        debugPrint("📌 Stack: $s");
      }
    },
  );
}

