import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:geolocator/geolocator.dart';

class CommonFeatures {
  static Future<bool> checkInternetAvailable() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}
