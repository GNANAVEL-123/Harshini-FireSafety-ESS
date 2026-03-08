import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:harshinifireess/screens/leadoverview.dart';

class LeadList extends StatefulWidget {
  const LeadList({super.key});

  @override
  State<LeadList> createState() => _LeadListState();
}

class _LeadListState extends State<LeadList> {
  int limitStart = 0;
  int limit = 20;
  bool isLoading = false;
  bool hasMore = true;
  List<String> statusOptions = [];
  List<String> sourceOptions = [];

  List<Map<String, dynamic>> leadList = [];

  @override
  void initState() {
    super.initState();
    loadLeads();
  }

  Future<void> loadLeads({bool isLoadMore = false}) async {
    if (isLoading) return;
    isLoading = true;

    const pageSize = 20;

    if (!isLoadMore) {
      limitStart = 0;
      leadList.clear();
    } else {
      limitStart = leadList.length;
    }

    final data = await UserService.fetchLeads(
      limitStart: limitStart,
      limit: pageSize,
      name: filterName,
      type: filterType,
      status: filterStatus,
      source: filterSource,
    );

    setState(() {
      leadList.addAll(
        (data["leads"] as List).map((e) => e as Map<String, dynamic>),
      );

      sourceOptions = List<String>.from(data['source'] ?? []);
      statusOptions = List<String>.from(data['status'] ?? []);

      hasMore = (data["total"] ?? 0) > leadList.length;
    });

    isLoading = false;
  }

  // ---------- FILTER OPTIONS ----------
  String? filterType;
  String? filterStatus;
  String? filterSource;
  String filterName = "";

  final leadTypeOptions = ['Lead', 'Company'];

  Future<void> _refreshLeads() async {
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      filterName = "";
      filterType = null;
      filterStatus = null;
      filterSource = null;

      leadList.clear();
      limitStart = 0;
      hasMore = true;
    });

    await loadLeads();
  }

  void openFilterSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // -------------------------------------------------------
                    // NAME FILTER WITH CLEAR
                    // -------------------------------------------------------
                    TextField(
                      controller: TextEditingController(text: filterName),
                      decoration: InputDecoration(
                        labelText: "Lead Name",
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            filterName.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setModalState(() => filterName = "");
                                  },
                                )
                                : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          filterName = val;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // -------------------------------------------------------
                    // STATUS FILTER WITH CLEAR
                    // -------------------------------------------------------
                    DropdownButtonFormField<String>(
                      value: filterStatus,
                      decoration: InputDecoration(
                        labelText: "Status",
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            filterStatus != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setModalState(() => filterStatus = null);
                                  },
                                )
                                : null,
                      ),
                      items:
                          statusOptions
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setModalState(() => filterStatus = val),
                    ),
                    // SizedBox(
                    //   width: 200,
                    //   child: DropdownButtonFormField<String>(
                    //     value: filterType,
                    //     dropdownColor: Colors.white,
                    //     decoration: InputDecoration(
                    //       labelText: "Type",
                    //       isDense: true,
                    //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    //       enabledBorder: OutlineInputBorder(
                    //         borderSide: const BorderSide(color: Colors.grey, width: 1),
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       focusedBorder: OutlineInputBorder(
                    //         borderSide: const BorderSide(color: Colors.grey, width: 2),
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //     ),
                    //     items: [null, ...leadTypeOptions]
                    //         .map((e) => DropdownMenuItem(value: e, child: Text(e ?? 'All')))
                    //         .toList(),
                    //     onChanged: (val) => setState(() => filterType = val),
                    //   ),
                    // ),
                    const SizedBox(height: 15),

                    // -------------------------------------------------------
                    // SOURCE FILTER WITH CLEAR
                    // -------------------------------------------------------
                    DropdownButtonFormField<String>(
                      value: filterSource,
                      decoration: InputDecoration(
                        labelText: "Source",
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            filterSource != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setModalState(() => filterSource = null);
                                  },
                                )
                                : null,
                      ),
                      items:
                          sourceOptions
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setModalState(() => filterSource = val),
                    ),
                    const SizedBox(height: 25),

                    // -------------------------------------------------------
                    // BUTTON ROW
                    // -------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Apply Filters"),
                          onPressed: () {
                            setState(() {
                              hasMore = true;
                              limitStart = 0;
                            });

                            Navigator.pop(context);
                            loadLeads();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Lead List", style: TextStyle(color: Colors.white)),
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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- LEAD LIST ----------
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshLeads,
              child:
                  leadList.isEmpty && !isLoading
                      ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 150),
                          Center(
                            child: Text(
                              "No Data Found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: leadList.length + (hasMore ? 1 : 0),

                        itemBuilder: (context, index) {
                          // ==========================
                          //  LOAD MORE ROW
                          // ==========================
                          if (index == leadList.length) {
                            if (isLoading) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CupertinoActivityIndicator(radius: 14),
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () => loadLeads(isLoadMore: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text("Load More"),
                                ),
                              ),
                            );
                          }

                          final item = leadList[index];

                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            LeadOverview(leadId: item['name']),
                                  ),
                                );
                              },
                              leading:
                                  item['image'] != null &&
                                          item['image']
                                              .toString()
                                              .trim()
                                              .isNotEmpty
                                      ? CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.white,
                                        backgroundImage: NetworkImage(
                                          item['image'],
                                        ),
                                      )
                                      : const CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.grey,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),

                              title: Text(
                                item['first_name'] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  item['name'] != null
                                      ? Text(
                                        "${item['name'] ?? ''}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                                  item['source'] != null
                                      ? Text(
                                        "${item['source'] ?? ''}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                                  item['next_follow_up'] != null
                                      ? Text(
                                        "Next: ${item['next_follow_up']}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      item['status'] == 'Open'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        item['status'] == 'Open'
                                            ? Colors.green
                                            : Colors.amber,
                                  ),
                                ),
                                child: Text(
                                  item['status'] ?? "",
                                  style: TextStyle(
                                    color:
                                        item['status'] == 'Open'
                                            ? Colors.green
                                            : Colors.amber.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
