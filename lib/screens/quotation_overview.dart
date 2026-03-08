import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:harshinifireess/screens/quotation_creation.dart';
import 'package:harshinifireess/screens/quotation_itemtable.dart';
import 'package:harshinifireess/screens/quotation_taxtable.dart';
import 'package:intl/intl.dart';

const Color primaryOrange = Color(0xFFFF7A00);
const Color lightBg = Color(0xFFF8F9FB);

class QuotationView extends StatefulWidget {
  final String quotationNo;
  const QuotationView({super.key, required this.quotationNo});

  @override
  State<QuotationView> createState() => _QuotationViewState();
}

class FollowUp {
  final String id;
  final DateTime timestamp;
  final DateTime creation;
  final String by;
  final String note;
  final String channel; // call, whatsapp, meeting, email, note

  FollowUp({
    required this.id,
    required this.timestamp,
    required this.creation,
    required this.by,
    required this.note,
    required this.channel,
  });
}

class _QuotationViewState extends State<QuotationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _updatingRemarks = false;
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  List<FollowUp> _followups = [];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadQuotation();
  }

  String? _selectedStatus;
  List<String> _statusOptions = [];
  bool _loadingStatus = true;

  DateTime? _selectedDate;
  final TextEditingController _remarksController = TextEditingController();

  Future<void> loadQuotation() async {
    try {
      setState(() => loading = true);
      data = await UserService.fetchQuotationDetails(widget.quotationNo);

      final List followUpsRaw = data!['custom_followup'] as List? ?? [];

      final followups =
          followUpsRaw.map<FollowUp>((f) {
              final tsRaw = f['next_follow_up_date'];
              final ts =
                  tsRaw is DateTime
                      ? tsRaw
                      : DateTime.tryParse(tsRaw?.toString() ?? '') ??
                          DateTime.now();
              final note = f['description']?.toString() ?? '';
              final channel =
                  (f['mode_of_communication']?.toString() ?? '').isEmpty
                      ? 'note'
                      : f['mode_of_communication'].toString();

              return FollowUp(
                id: f['name'] ?? '',
                creation:
                    DateTime.tryParse(f['creation']?.toString() ?? '') ??
                    DateTime.now(),
                timestamp: ts,
                by: f['followed_by']?.toString() ?? '',
                note: note,
                channel: channel,
              );
            }).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      await UserService.fetchStatusOptions(
        doctype: "Quotation",
        fieldname: "status",
      ).then((list) {
        setState(() {
          _statusOptions = list;

          _followups = followups;
          _loadingStatus = false;
        });
      });
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildNextFollowUpCard(FollowUp next) {
    return detailsCard(
      title: 'Next Follow-up',
      icon: Icons.calendar_today,
      children: [
        detailRow("Next Followed By", next.by),
        detailRow("Next Follwed On", DateFormat.yMMMd().format(next.timestamp)),
        detailRow("Remarks", next.note.isEmpty ? 'No remarks' : next.note),
      ],
    );
  }

  Widget _buildMissedFollowUpCard(FollowUp next) {
    return detailsCard(
      title: 'Follow-up Missed',
      icon: Icons.calendar_today,
      children: [
        detailRow("Due On", DateFormat.yMMMd().format(next.timestamp)),
        detailRow("Remarks", next.note.isEmpty ? 'No remarks' : next.note),
      ],
    );
  }

  void _showAddFollowUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                height: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔴 ERROR MESSAGE AT TOP
                    if (errorText != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorText!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Center(
                      child: Text(
                        "Add Follow Up",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _dateField("Next Follow-up Date"),
                    const SizedBox(height: 15),

                    _loadingStatus
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: "Status",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items:
                              _statusOptions
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            setModalState(() {
                              _selectedStatus = v;
                            });
                          },
                        ),
                    const SizedBox(height: 15),

                    _textField(
                      _remarksController,
                      "Remarks",
                      icon: Icons.note_alt,
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton.icon(
                        style: _primaryButtonStyle(Colors.orange),
                        onPressed: () async {
                          final bool statusProvided = _selectedStatus != null;

                          if (!statusProvided) {
                            if (_selectedDate == null ||
                                _remarksController.text.trim().isEmpty) {
                              setModalState(() {
                                errorText =
                                    "Please select follow-up date and enter remarks, or choose a status";
                              });
                              return;
                            }
                          }

                          try {
                            await UserService.addFollowUp(
                              referenceDoctype: "Quotation",
                              referenceName: widget.quotationNo,
                              followUpDate:
                                  _selectedDate != null
                                      ? _selectedDate!.toIso8601String().split(
                                        "T",
                                      )[0]
                                      : null,
                              remarks: _remarksController.text.trim(),
                              status: _selectedStatus,
                            );

                            _remarksController.clear();
                            _selectedDate = null;
                            _selectedStatus = null;

                            await loadQuotation();

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Follow-up added successfully"),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            setModalState(() {
                              errorText = e.toString();
                            });
                          }
                        },

                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Save Follow Up",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    IconData? icon,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        textAlignVertical: TextAlignVertical.top,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: required ? "$label *" : label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }

  Widget _dateField(String label) {
    final text =
        _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : '';
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      controller: TextEditingController(text: text),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text("Quotation"),
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          dividerColor: Colors.white,
          tabs: const [Tab(text: "DETAILS"), Tab(text: "SUMMARY")],
        ),
        actions: [
          if (!loading && data != null && data!['docstatus'] == 0)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => QuotationCreation(
                          quotationId: data!['name'], // ✅ pass ID
                        ),
                  ),
                );
              },
              icon: Icon(Icons.edit),
            ),
        ],
      ),
      body:
          loading
              ? const Center(child: CupertinoActivityIndicator(radius: 14))
              : error != null
              ? Center(child: Text(error!))
              : TabBarView(
                controller: _tabController,
                children: [detailsTab(), summaryTab()],
              ),
    );
  }

  ButtonStyle _primaryButtonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 2,
  );

  bool isMissed(DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final followDate = DateTime(ts.year, ts.month, ts.day);

    return followDate.isBefore(today);
  }

  void _showEditRemarksSheet(
    BuildContext context,
    String rowname,
    String currentNote,
  ) {
    final TextEditingController remarkController = TextEditingController(
      text: currentNote,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text(
                'Edit Remarks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 12),

              /// TextField
              TextField(
                controller: remarkController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter remarks',
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange.withOpacity(0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _updatingRemarks
                              ? null
                              : () async {
                                setState(() {
                                  _updatingRemarks = true;
                                });

                                try {
                                  await UserService.updateFollowUpRemarks(
                                    rowName: rowname,
                                    remarks: remarkController.text.trim(),
                                  );

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Remarks updated successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  loadQuotation();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _updatingRemarks = false;
                                    });
                                  }
                                }
                              },
                      child:
                          _updatingRemarks
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Update',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---------------- DETAILS TAB (REDESIGNED) ----------------
  Widget detailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          detailsCard(
            title: "General Information",
            icon: Icons.info_outline,
            children: [
              detailRow("Quotation No", widget.quotationNo),
              detailRow("Party Name", data!["party_name"]),
              detailRow("Quotation To", data!["quotation_to"]),
              detailRow("Company", data!["company"]),
              detailRow("Status", data!["status"]),
              detailRow("Transaction Date", data!["transaction_date"]),
            ],
          ),

          const SizedBox(height: 16),

          detailsCard(
            title: "Additional Details",
            icon: Icons.assignment_outlined,
            children: [
              detailRow("Kind Attn", data!["custom_kind_attn"]),
              detailRow("Territory", data!["custom_region"]),
              detailRow("Phone", data!["custom_phone"]),
              detailRow("Quotation Owner", data!["custom_quotation_owner"]),
              detailRow("Assigned To", data!["custom_assigned_to"]),
              detailRow("Visit Count", data!["custom_visit_count"]?.toString()),
            ],
          ),

          const SizedBox(height: 12),

          // Next Follow‑up
          ...(_followups.isNotEmpty
              ? [
                Builder(
                  builder: (_) {
                    final next = _followups.last;

                    // Check if missed
                    if (isMissed(next.timestamp)) {
                      return _buildMissedFollowUpCard(next);
                    } else {
                      return _buildNextFollowUpCard(next);
                    }
                  },
                ),
              ]
              : []),

          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Follow-up History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),

          ...(_followups.isNotEmpty
              ? [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _followups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final it = _followups[idx];

                    Color color;
                    IconData icon;
                    switch (it.channel) {
                      case 'call':
                        color = Colors.green;
                        icon = Icons.phone;
                        break;
                      case 'email':
                        color = Colors.indigo;
                        icon = Icons.email;
                        break;
                      case 'meeting':
                        color = Colors.blue;
                        icon = Icons.groups;
                        break;
                      case 'whatsapp':
                        color = Colors.teal;
                        icon = Icons.chat;
                        break;
                      default:
                        color = Colors.grey;
                        icon = Icons.notes;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 42,
                          child: Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Icon(icon, size: 8, color: Colors.white),
                              ),
                              if (idx != _followups.length - 1)
                                Container(
                                  width: 2,
                                  height: 80,
                                  margin: const EdgeInsets.only(top: 6),
                                  color: Colors.grey.shade300,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        it.by,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    it.note.isEmpty ? 'No remarks' : it.note,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(icon, size: 14, color: color),
                                            const SizedBox(width: 6),
                                            Text(
                                              it.channel,
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      PopupMenuButton<String>(
                                        color: Colors.white,
                                        itemBuilder:
                                            (_) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                            ],
                                        onSelected: (v) {
                                          if (v == 'edit') {
                                            _showEditRemarksSheet(
                                              context,
                                              it.id,
                                              it.note,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      DateFormat.yMMMd().add_jm().format(
                                        it.creation,
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ]
              : []),

          ...(_followups.isEmpty
              ? [
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('No follow-up history'),
                    ),
                  ),
                ),
              ]
              : []),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: _primaryButtonStyle(Colors.orange),
              onPressed: _showAddFollowUpSheet,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add New Follow Up',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PROFESSIONAL DETAILS CARD ----------------
  Widget detailsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade300),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ---------------- PROFESSIONAL DETAILS ROW ----------------
  Widget detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  List<QuotationItem> get overviewItems {
    final items = data?["items"] as List? ?? [];

    return items.map((e) {
      return QuotationItem(
        itemCode: e["item_code"] ?? "",
        itemName: e["item_name"] ?? "",
        qty: (e["qty"] as num).toDouble(),
        uom: e["uom"] ?? "",
        rate: (e["price_list_rate"] ?? e['rate'] ?? 0 as num).toDouble(),
        discountAmount: (e["discount_amount"] ?? 0).toDouble(),
        hasPriceList: true,
      );
    }).toList();
  }

  double get netTotal {
    return overviewItems.fold(0, (sum, e) => sum + e.amount);
  }

  // ---------------- SUMMARY TAB ----------------
  Widget summaryTab() {
    final totals = data!["totals"];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          QuotationItemTable(
            items: overviewItems,
            onItemsChanged: null,
            readOnly: true,
          ),

          const SizedBox(height: 16),
          SalesTaxesTable(
            netTotal: netTotal,
            selectedTemplateName: data!["taxes_and_charges"],
            discountOn: DiscountOn.netTotal,
            invoiceDiscount: 0,
            onGrandTotalChanged: null,
            scaffoldMessengerKey: null,
            readOnly: true,
          ),

          const SizedBox(height: 16),
          sectionTitle("Summary"),
          summaryRow("Total Qty", data!["total_qty"]),
          summaryRow("Discount On", data!["apply_discount_on"]),
          summaryRow("Net Total Before Discount", data!["total"]),
          summaryRow("Discount Amount", data!["discount_amount"]),
          summaryRow("Net Total After Discount", data!["net_total"]),
          summaryRow("Tax Category", data!["tax_category"]),
          summaryRow("Taxes & Charges", data!["taxes_and_charges"]),
          const Divider(),
          summaryRow(
            "Total Taxes",
            data!["total_taxes_and_charges"],
            bold: true,
          ),
          summaryRow(
            "Grand Total",
            data!["grand_total"],
            bold: true,
            highlight: true,
          ),
        ],
      ),
    );
  }

  // ---------------- ITEM TABLE ----------------
  Widget itemTable() {
    final items = data!["items"] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("Items"),
            ...items.map((item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["item_name"],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Qty: ${item["qty"]} ${item["uom"]}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text("Rate: ₹${item["rate"]}"),
                      Text(
                        "₹${item["amount"]}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- TAX TABLE ----------------
  Widget taxTable() {
    final taxes = data!["taxes"] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("Taxes"),
            ...taxes.map((tax) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${tax["charge_type"]}\n${tax["account_head"]}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text("₹${tax["tax_amount"]}"),
                    Text(
                      "₹${tax["total"]}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget infoCard(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryRow(
    String label,
    dynamic value, {
    bool bold = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: highlight ? primaryOrange : Colors.black,
              fontSize: highlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
