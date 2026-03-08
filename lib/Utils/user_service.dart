import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static Future<String> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("base_url") ?? "";
  }

  static Future<Map<String, dynamic>> fetchLeadDetails(String leadId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_lead_detail",
    ).replace(
      queryParameters: {
        "name": leadId,
      },
    );

    final response = await http.get(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"] != null) {
      return body["message"];
    } else {
      throw Exception("Failed to load lead details: ${response.body}");
    }
  }

  static Future<void> updateFollowUpRemarks({
    required String rowName,
    required String remarks,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.update_followup_remarks",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({"row_name": rowName, "remarks": remarks}),
    );
    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body["message"] != "success") {
      throw Exception(body["message"] ?? "Failed to update remarks");
    }
  }

  static Future<Map<String, dynamic>> fetchQuotationMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_quotation_metadata",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"] != null) {
      return body["message"];
    } else {
      throw Exception("Failed to load quotation metadata");
    }
  }

  static Future<double> fetchItemRate(String itemCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) {
      throw Exception("Token missing");
    }

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_item_price",
    );

    final response = await http.get(
      url.replace(queryParameters: {"item_code": itemCode}),
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch item price");
    }

    final json = jsonDecode(response.body);
    return (json["message"]["rate"] as num).toDouble();
  }

  static Future<List<Map<String, dynamic>>> fetchTaxTemplateDetails(
    String templateName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      throw Exception("Token missing");
    }

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_tax_template_details",
    );

    final response = await http.get(
      url.replace(queryParameters: {"template_name": templateName}),
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load tax template details");
    }

    final json = jsonDecode(response.body);
    final data = json["message"] as List;

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> validateQuotation(
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.validate_quotation",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({"data": payload}),
    );
    if (response.statusCode != 200) {
      throw Exception("Validation API failed");
    }

    final result = jsonDecode(response.body);

    if (result["exc"] != null) {
      throw Exception(result["exc"]);
    }

    return result["message"];
  }

  static Future<Map<String, dynamic>> createQuotation(
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.create_quotation",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({"data": payload}),
    );

    if (response.statusCode != 200) {
      throw Exception("Create Quotation API failed");
    }

    final result = jsonDecode(response.body);

    return result["message"];
  }

  

  static Future<void> sendLocationLog({
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.log_employee_location",
    );

    final payload = {
      "data": jsonEncode({
        "lat": lat,
        "lng": lng,
        "time": DateTime.now().toString(),
      }),
    };

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(body["message"] ?? "Failed to send location");
    }
  }

  static Future<Map<String, dynamic>> fetchMetaData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_metadata",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"] != null) {
      return Map<String, dynamic>.from(body["message"]);
    } else {
      throw Exception("Failed to load metadata: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> fetchLeaveMetaData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_leave_metadata",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"] != null) {
      return Map<String, dynamic>.from(body["message"]);
    } else {
      throw Exception("Failed to load leave metadata: ${response.body}");
    }
  }

  static Future<void> createLeaveApplication(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Session expired. Please login again.");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.create_leave_application",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({"data": data}),
    );

    final body = jsonDecode(response.body);

    if (body["exc"] != null) {
      String errorMessage = "Something went wrong";

      if (body["_server_messages"] != null) {
        final messages = jsonDecode(body["_server_messages"]);
        errorMessage = jsonDecode(messages[0])["message"];
      }

      throw Exception(errorMessage);
    }
    if (response.statusCode != 200 || body["message"]?["success"] != true) {
      throw Exception(body["message"]?["message"] ?? "Leave creation failed");
    }
  }

  static Future<Map<String, dynamic>> fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_session_user_details",
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": token ?? "",
        "Content-Type": "application/json",
      },
    );
    print(response.body);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      return body["message"];
    } else {
      throw Exception("Failed to fetch user: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> fetchLeads({
    required int limitStart,
    int limit = 20,
    String? name,
    String? type,
    String? status,
    String? source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final uri = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_leads",
    ).replace(
      queryParameters: {
        "limit_start": limitStart.toString(),
        "limit": limit.toString(),
        if (name != null && name.isNotEmpty) "name": name,
        if (type != null) "type": type,
        if (status != null) "status": status,
        if (source != null) "source": source,
      },
    );

    final response = await http.get(
      uri,
      headers: {"Authorization": token ?? ""},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["message"];
    } else {
      throw Exception("Failed to load leads: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> fetchQuotation({
    required int limitStart,
    int limit = 20,
    String? name,
    String? status,
    String? source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final uri = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_quotations",
    ).replace(
      queryParameters: {
        "limit_start": limitStart.toString(),
        "limit": limit.toString(),
        if (name != null && name.isNotEmpty) "name": name,
        if (status != null) "status": status,
        if (source != null) "source": source,
      },
    );

    final response = await http.get(
      uri,
      headers: {"Authorization": token ?? ""},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["message"];
    } else {
      throw Exception("Failed to load quotations: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> fetchQuotationDetails(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final uri = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_quotation_details",
    ).replace(queryParameters: {"name": name});

    final response = await http.get(
      uri,
      headers: {"Authorization": token ?? ""},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)["message"];
    } else {
      throw Exception("Failed to fetch quotation");
    }
  }

  static Future<Map<String, dynamic>> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.fetch_profile",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      return body["data"];
    } else {
      throw Exception("Failed to load profile: ${response.body}");
    }
  }

  static Future<List<dynamic>> fetchTodaysFollowups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.todays_followup",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"]["success"] == true) {
      return body["message"]["data"];
    } else {
      throw Exception("Failed to load followups: ${response.body}");
    }
  }

  static Future<List<String>> fetchStatusOptions({
    required String doctype,
    required String fieldname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_field_options",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({"doctype": doctype, "fieldname": fieldname}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"] != null) {
      return List<String>.from(body["message"]);
    } else {
      throw Exception("Failed to fetch status options");
    }
  }

  static Future<bool> addFollowUp({
    required String referenceDoctype,
    required String referenceName,
    String? followUpDate,
    String? remarks,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      throw Exception("Token missing");
    }

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.add_followup",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({
        "reference_doctype": referenceDoctype,
        "reference_name": referenceName,
        if (followUpDate != null) "next_follow_up_date": followUpDate,
        if (remarks != null) "remarks": remarks,
        if (status != null) "status": status,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"]["success"] == true) {
      return true;
    } else {
      throw Exception(body["message"]?["error"] ?? "Failed to add follow-up");
    }
  }

  static Future<Map<String, dynamic>> fetchLeadByName(String leadId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_lead_detail",
    ).replace(queryParameters: {"name": leadId});

    final response = await http.get(
      url,
      headers: {"Authorization": token!, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"] != null) {
      return body["message"];
    } else {
      throw Exception("Failed to fetch lead");
    }
  }

  static Future<String> fetchTodayCheckinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Missing token");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_today_checkin_status",
    );

    final response = await http.get(url, headers: {"Authorization": token});

    final json = jsonDecode(response.body);
    if (json["message"]["success"] == true) {
      return json["message"]["status"];
    } else {
      throw Exception(json["message"]["message"]);
    }
  }

  static Future<Map<String, dynamic>> createCheckIn({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final device_token = prefs.getString("device_info");
    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.create_checkin",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
        "address": address ?? "",
        "device_token": device_token,
      }),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode == 200 && json["message"]["success"] == true) {
      final bool allowTracking = (json["message"]["allow_tracking"] ?? 0) == 1;

      final int frequency = json["message"]["frequency"] ?? 10;

      await prefs.setBool("allow_tracking", allowTracking);
      await prefs.setInt("frequency", frequency);

      return json["message"];
    } else {
      throw Exception(json["message"]["message"] ?? "Check-in failed");
    }
  }

  static Future<Map<String, dynamic>> createCheckOut({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final device_token = prefs.getString("device_info");
    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.create_checkout",
    );

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
        "address": address ?? "",
        "device_token": device_token,
      }),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode == 200 && json["message"]["success"] == true) {
      return json["message"];
    } else {
      throw Exception(json["message"]["message"] ?? "Checkout failed");
    }
  }

  static Future<Map<String, dynamic>> createLead({
    required String leadName,
    required String leadOwner,
    String? assignedTo,
    String? status,
    String? companyName,
    String? leadSource,
    String? allocated_to_manager,
    String? customer,
    String? territory,
    String? industry,
    List<String>? items,
    String? email,
    String? whatsappNo,
    String? phone,
    String? address,
    String? annualRevenue,
    String? noOfEmployees,
    String? notes,
    List<Map<String, dynamic>>? followUps,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.create_lead_with_followup",
    );
    final body = {
      "lead_name": leadName,
      "lead_owner": leadOwner,
      "assigned_to": assignedTo,
      "status": status,
      "allocated_to_manager": allocated_to_manager,
      "company_name": companyName,
      "lead_source": leadSource,
      "customer": customer,
      "territory": territory,
      "industry": industry,
      "items": items ?? [],
      "email": email,
      "whatsapp_no": whatsappNo,
      "phone": phone,
      "address": address,
      "annual_revenue": annualRevenue,
      "no_of_employees": noOfEmployees,
      "notes": notes,
      "follow_ups": followUps != null ? jsonEncode(followUps) : null,
    }..removeWhere((key, value) => value == null);

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['message']["success"] == true) {
      return {
        "success": true,
        "lead": data['message']["lead"],
        "message": data["message"],
      };
    } else {
      throw Exception(data["message"] ?? "Failed to create lead");
    }
  }

  static Future<Map<String, dynamic>> updateLead({
    required String leadId,
    required String leadName,
    required String leadOwner,
    String? assignedTo,
    String? status,
    String? companyName,
    String? leadSource,
    String? allocated_to_manager,
    String? customer,
    String? territory,
    String? industry,
    List<String>? items,
    String? email,
    String? whatsappNo,
    String? phone,
    String? address,
    String? annualRevenue,
    String? noOfEmployees,
    String? notes,
    List<Map<String, dynamic>>? followUps,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.update_lead_with_followup",
    );

    final body = {
      "lead_id": leadId,
      "lead_name": leadName,
      "lead_owner": leadOwner,
      "assigned_to": assignedTo,
      "status": status,
      "allocated_to_manager": allocated_to_manager,
      "company_name": companyName,
      "lead_source": leadSource,
      "customer": customer,
      "territory": territory,
      "industry": industry,
      "items": items ?? [],
      "email": email,
      "whatsapp_no": whatsappNo,
      "phone": phone,
      "address": address,
      "annual_revenue": annualRevenue,
      "no_of_employees": noOfEmployees,
      "notes": notes,
      "follow_ups": followUps != null ? jsonEncode(followUps) : null,
    }..removeWhere((key, value) => value == null);

    final response = await http.post(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["message"]["success"] == true) {
      return {"success": true, "lead": data["message"]["lead"]};
    } else {
      throw Exception(data["message"] ?? "Failed to update lead");
    }
  }

  static Future<void> uploadAttachment({
    required String doctype,
    required String docname,
    required File file,
    required String filename,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.upload_attachment",
    );

    final request =
        http.MultipartRequest('POST', url)
          ..headers['Authorization'] = token
          ..fields['doctype'] = doctype
          ..fields['docname'] = docname
          ..files.add(
            await http.MultipartFile.fromPath(
              'file',
              file.path,
              filename: filename,
            ),
          );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final body = jsonDecode(responseBody);

    if (response.statusCode == 200 && body["message"]["success"] == true) {
      return;
    } else {
      throw Exception(body["message"]["message"] ?? "Upload failed");
    }
  }

  static Future<List<String>> fetchLeadStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) throw Exception("Token missing");

    final url = Uri.parse(
      "${await baseUrl}/api/method/crm_activity_tracking.crm_activity_tracking.utils.api.get_lead_statuses",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": token, "Content-Type": "application/json"},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["message"] != null) {
      return List<String>.from(body["message"]);
    } else {
      throw Exception("Failed to load lead statuses: ${response.body}");
    }
  }
}
