import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<Map<String, dynamic>> userFuture;

  @override
  void initState() {
    super.initState();
    userFuture = UserService.fetchUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "User Profile",
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFFFA000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade300,
      body: FutureBuilder<Map<String, dynamic>>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final user = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                userFuture = UserService.fetchUser();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 18),

              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        (user["user_image"] ?? "").toString().isNotEmpty
                            ? Image.network(
                              "${UserService.baseUrl}${user['user_image']}",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.orangeAccent,
                                );
                              },
                            )
                            : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.orangeAccent,
                            ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        children: [
                          _readOnlyField("Full Name", user["full_name"] ?? ""),
                          _readOnlyField("Email", user["email"] ?? ""),
                          _readOnlyField("Phone", user["phone"] ?? ""),
                          _readOnlyField("Mpbile No", user["mobile_no"] ?? ""),
                          _readOnlyField(
                            "Device Id",
                            user["device_info"] ?? "",
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _readOnlyField(
    String label,
    String value, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: TextEditingController(text: value),
        maxLines: maxLines,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade200,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
