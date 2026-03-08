import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Authentication {
  static String get baseUrl {
    return dotenv.env['URL'] ?? "";
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
    String otp,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.login',
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "otp": otp,
        }),
      );

      if (response.statusCode != 200) {
        return {
          "success": false,
          "error": "Server Error: ${response.statusCode}"
        };
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final message = data["message"];

      if (message["success"] == true) {
        final prefs = await SharedPreferences.getInstance();

        final user = message["user"];
        final apiKey = message["api_key"];
        final apiSecret = message["api_secret"];
        final deviceInfo = message["device_info"];
        final fullname = message["full_name"];

        final token = "token $apiKey:$apiSecret";

        await prefs.setString('email', user);
        await prefs.setString('fullname', fullname);
        await prefs.setString('api_key', apiKey);
        await prefs.setString('api_secret', apiSecret);
        await prefs.setString('token', token);
        await prefs.setString('device_info', deviceInfo);

        return {
          "success": true
        };
      } else {
        return {
          "success": false,
          "error": message["message"]
        };
      }
    } catch (e) {
      return {
        "success": false,
        "error": "Network Error. Please try again."
      };
    }
  }


  static Future<bool> pingSite() async {
    final url = Uri.parse('$baseUrl/api/method/ping');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["message"] == "pong") {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isTokenActive() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return false;

    final url = Uri.parse(
      "$baseUrl/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.mobile_is_session_active",
    );

    try {
      final response = await http.get(url, headers: {"Authorization": token});

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body["message"]["active"] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    bool internet = await hasInternet();
    if (!internet) {
      return {"success": false, "message": "Internet is Not Available"};
    }

    bool server = await pingSite();
    if (!server) {
      return {"success": false, "message": "Unable to reach server"};
    }

    if (token == null || token.isEmpty) {
      return {"success": false, "message": "Token not found"};
    }

    final url = Uri.parse(
      "$baseUrl/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.fetch_profile",
    );

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": token, "Content-Type": "application/json"},
      );

      if (response.statusCode == 401) {
        return {"success": false, "message": "Session Inactive"};
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["message"]?["success"] == true) {
          return {"success": true, "data": body["message"]["data"]};
        }

        return {
          "success": false,
          "message": body["message"]?["message"] ?? "Invalid response",
        };
      }

      return {"success": false, "message": "Profile fetch failed"};
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<bool> hasInternet() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity is List) {
      if (connectivity.contains(ConnectivityResult.none)) {
        return false;
      }
    } else {
      if (connectivity == ConnectivityResult.none) {
        return false;
      }
    }

    return true;
  }

  static Future<bool> validateConnection() async {
    final online = await hasInternet();
    if (!online) {
      throw Exception("Internet is Not Available");
    }

    final server = await pingSite();
    if (!server) {
      throw Exception("Unable to reach server");
    }

    return true;
  }
}
