import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:harshinifireess/screens/leadoverview.dart';
import 'package:harshinifireess/screens/quotation_overview.dart';

class QuotationList extends StatefulWidget {
  const QuotationList({super.key});

  @override
  State<QuotationList> createState() => _QuotationListState();
}

class _QuotationListState extends State<QuotationList> {
  int limitStart = 0;
  int limit = 20;
  bool isLoading = false;
  bool hasMore = true;
  List<String> statusOptions = [];
  List<String> territoryOptions = [];

  List<Map<String, dynamic>> quotationList = [];

  @override
  void initState() {
    super.initState();
    loadQuotations();
  }

  Future<void> loadQuotations({bool isLoadMore = false}) async {
    if (isLoading) return;
    isLoading = true;

    const pageSize = 20;

    if (!isLoadMore) {
      limitStart = 0;
      quotationList.clear();
    } else {
      limitStart = quotationList.length;
    }

    final data = await UserService.fetchQuotation(
      limitStart: limitStart,
      limit: pageSize,
      name: filterName,
      status: filterStatus,
      source: filterSource,
    );

    setState(() {
      quotationList.addAll(
        (data["quotations"] as List).map((e) => e as Map<String, dynamic>),
      );

      territoryOptions = List<String>.from(data['territory'] ?? []);
      statusOptions = List<String>.from(data['status'] ?? []);

      hasMore = (data["total"] ?? 0) > quotationList.length;
    });

    isLoading = false;
  }

  // ---------- FILTER OPTIONS ----------
  String? filterType;
  String? filterStatus;
  String? filterSource;
  String filterName = "";

  Future<void> _refreshquotations() async {
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      filterName = "";
      filterType = null;
      filterStatus = null;
      filterSource = null;

      quotationList.clear();
      limitStart = 0;
      hasMore = true;
    });

    await loadQuotations();
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
                        labelText: "Quotation Name",
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
                          territoryOptions
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
                            loadQuotations();
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
      backgroundColor: Colors.white,

      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Quotation List'),
        centerTitle: false,
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
              onRefresh: _refreshquotations,
              child:
                  quotationList.isEmpty && !isLoading
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
                        itemCount: quotationList.length + (hasMore ? 1 : 0),

                        itemBuilder: (context, index) {
                          // ==========================
                          //  LOAD MORE ROW
                          // ==========================
                          if (index == quotationList.length) {
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
                                  onPressed:
                                      () => loadQuotations(isLoadMore: true),
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

                          final item = quotationList[index];

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
                                        (_) => QuotationView(
                                          quotationNo: item['name'],
                                        ),
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
                                item['customer_name'] ?? "",
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
