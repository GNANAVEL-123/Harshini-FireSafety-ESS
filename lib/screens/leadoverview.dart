import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:harshinifireess/screens/leadcreation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class LeadOverview extends StatefulWidget {
  final String leadId;
  const LeadOverview({required this.leadId, super.key});

  @override
  State<LeadOverview> createState() => _LeadOverviewState();
}

class Lead {
  final String id;
  final String name;
  final String? imageUrl;
  final String? salutation;
  final String? jobTitle;
  final String? companyName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? website;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String status;
  final String? leadType;
  final String? source;
  final String assignedTo;
  final DateTime createdOn;
  final String? note;
  final String? region;
  final String? qualificationStatus;
  final String? gstCategory;
  final String? gstin;
  final String? noOfEmployees;

  Lead({
    required this.id,
    required this.name,
    this.imageUrl,
    this.salutation,
    this.jobTitle,
    this.companyName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.website,
    this.phone,
    this.whatsapp,
    this.email,
    required this.status,
    this.leadType,
    this.source,
    required this.assignedTo,
    required this.createdOn,
    this.note,
    this.region,
    this.qualificationStatus,
    this.gstCategory,
    this.gstin,
    this.noOfEmployees,
  });
}

class Attachment {
  final String id;
  final String name;
  final String? thumbnailUrl; // if null show doc icon
  final String mimeType;
  final String? fileUrl;

  Attachment({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    required this.mimeType,
    this.fileUrl,
  });
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

class _LeadOverviewState extends State<LeadOverview> {
  bool _updatingRemarks = false;

  Lead? _lead;
  List<Attachment> _attachments = [];
  List<FollowUp> _followups = [];
  bool _loading = true;
  String? _error;
  List<String> _statuses = [];
  bool _loadingStatuses = false;

  String? _selectedStatus;
  List<String> _statusOptions = [];
  bool _loadingStatus = true;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLeadData();
    _fetchStatuses();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  // ---------- Small UI Helpers ----------

  ButtonStyle _primaryButtonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 2,
  );

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

  Widget _timeField(String label) {
    final text = _selectedTime != null ? _selectedTime!.format(context) : '';
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      controller: TextEditingController(text: text),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime ?? TimeOfDay.now(),
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
        }
      },
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    String? value,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // vertical center
        children: [
          Container(
            decoration: BoxDecoration(
              color: hasValue ? Colors.blue.shade50 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: hasValue ? Colors.blue : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasValue ? value! : 'Unavailable',
              style: TextStyle(
                fontSize: 14,
                color: hasValue ? Colors.black : Colors.grey,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: 0.05,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    String label,
    String? value,
    IconData icon,
    Color color,
  ) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.08),
      labelStyle: TextStyle(color: Colors.grey[900], fontSize: 12),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildAddressCard() {
    final l = _lead;
    if (l == null) return const SizedBox.shrink();

    final parts =
        [
          l.addressLine1,
          l.addressLine2,
          l.city,
          l.state,
          l.country,
          l.pincode,
        ].where((e) => e != null && e!.trim().isNotEmpty).toList();

    if (parts.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: Colors.red),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parts.join(', '),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                              referenceDoctype: "Lead",
                              referenceName: widget.leadId,
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

                            await _fetchLeadData();

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

  // ---------- Data Fetch & Mapping ----------

  Future<void> _fetchLeadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await UserService.fetchLeadDetails(widget.leadId);

      await UserService.fetchStatusOptions(
        doctype: "Lead",
        fieldname: "status",
      ).then((list) {
        setState(() {
          _statusOptions = list;
          _loadingStatus = false;
        });
      });

      final imagePath = data['image'];
      final imageUrl =
          imagePath != null && imagePath.toString().isNotEmpty
              ? '${UserService.baseUrl}$imagePath'
              : null;

      final createdRaw = data['creation'];
      final createdOn =
          createdRaw is DateTime
              ? createdRaw
              : DateTime.tryParse(createdRaw?.toString() ?? '') ??
                  DateTime.now();

      final List attachmentsRaw = data['attachments'] as List? ?? [];
      final List followUpsRaw =
          data['custom_view_follow_up_details_copy'] as List? ?? [];

      final lead = Lead(
        id: data['name'] ?? '',
        name: data['lead_name'] ?? '',
        imageUrl: imageUrl,
        salutation: data['salutation'],
        jobTitle: data['job_title'],
        companyName: data['company_name'] ?? data['company'],
        addressLine1: data['custom_address_line_1'],
        addressLine2: data['custom_address_line_2'],
        city: data['city'],
        state: data['state'],
        country: data['country'],
        pincode: data['custom_pincode']?.toString(),
        website: data['website'],
        phone: data['phone'] ?? data['mobile_no'],
        whatsapp: data['whatsapp_no'],
        email: data['email_id'],
        status: data['status'] ?? '',
        leadType: data['type'],
        source: data['source'],
        assignedTo: data['custom_assigned_to'] ?? '',
        createdOn: createdOn,
        note: data['custom_remarks'],
        region: data['custom_region'],
        qualificationStatus: data['qualification_status'],
        gstCategory: data['custom_gst_category'],
        gstin: data['custom_gstin'],
        noOfEmployees: data['no_of_employees']?.toString(),
      );

      final attachments =
          attachmentsRaw
              .map<Attachment>(
                (a) => Attachment(
                  id: a['name'] ?? '',
                  name: a['file_name'] ?? '',
                  thumbnailUrl: null,
                  mimeType: a['file_type'] ?? '',
                  fileUrl: a['file_url'],
                ),
              )
              .toList();

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

      setState(() {
        _lead = lead;
        _attachments = attachments;
        _followups = followups;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchStatuses() async {
    setState(() {
      _loadingStatuses = true;
    });
    try {
      final statuses = await UserService.fetchLeadStatuses();
      setState(() {
        _statuses = statuses;
        _loadingStatuses = false;
      });
    } catch (e) {
      setState(() {
        _loadingStatuses = false;
      });
      // Handle error if needed
    }
  }

  bool isMissed(DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final followDate = DateTime(ts.year, ts.month, ts.day);

    return followDate.isBefore(today);
  }

  Widget _buildNextFollowUpCard(FollowUp next) {
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 22,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Follow-up',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(next.by, style: TextStyle(color: Colors.grey[700])),
                  Text(
                    DateFormat.yMMMd().format(next.timestamp),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    next.note.isEmpty ? 'No remarks' : next.note,
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedFollowUpCard(FollowUp next) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 26,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Follow-up Missed",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Due on ${DateFormat.yMMMd().format(next.timestamp)}",
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    next.note.isEmpty ? 'No remarks' : next.note,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bodyLoader() {
    return Center(child: CupertinoActivityIndicator(radius: 14));
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // Request permissions for file access
      PermissionStatus status;
      if (await Permission.photos.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.photos.request();
      }
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to pick files'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;

        // Validate file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 10MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading file...'),
            duration: Duration(seconds: 1),
          ),
        );

        // Upload file using UserService
        await UserService.uploadAttachment(
          doctype: 'Lead',
          docname: widget.leadId,
          file: file,
          filename: fileName,
        );

        // Refresh data
        await _fetchLeadData();

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------- Build ----------

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
                                      backgroundColor: Colors.greenAccent,
                                    ),
                                  );
                                  _fetchLeadData();
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

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lead Overview'),
          centerTitle: true,
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
          elevation: 0,
        ),
        body: Center(child: Text('Error: $_error')),
      );
    }
    if (_lead == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lead Overview'),
          centerTitle: true,
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
          elevation: 0,
        ),
        body: const Center(child: Text('Lead not found')),
      );
    }

    final lead = _lead!;

    Color statusColor;
    switch (lead.status.toLowerCase()) {
      case 'lead':
        statusColor = Colors.blue;
        break;
      case 'qualified':
        statusColor = Colors.green;
        break;
      case 'opportunity':
        statusColor = Colors.orange;
        break;
      case 'lost':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Overview'),
        centerTitle: true,
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
        elevation: 0,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
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
      backgroundColor: Colors.white,
      body:
          _loading
              ? bodyLoader()
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _fetchLeadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Card(
                          color: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage:
                                      lead.imageUrl != null
                                          ? NetworkImage(lead.imageUrl!)
                                          : null,
                                  child:
                                      lead.imageUrl == null
                                          ? Text(
                                            lead.name.isNotEmpty
                                                ? lead.name
                                                    .trim()
                                                    .split(' ')
                                                    .map(
                                                      (e) =>
                                                          e.isNotEmpty
                                                              ? e[0]
                                                              : '',
                                                    )
                                                    .take(2)
                                                    .join()
                                                    .toUpperCase()
                                                : '',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lead.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (lead.status.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(
                                                  0.08,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Text(
                                                lead.status,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if ((lead.companyName ?? '').isNotEmpty)
                                        Text(
                                          lead.companyName!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      if ((lead.jobTitle ?? '').isNotEmpty)
                                        Text(
                                          lead.jobTitle!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          if ((lead.phone ?? '').isNotEmpty)
                                            IconButton(
                                              onPressed: () async {
                                                final Uri phoneUri = Uri(
                                                  scheme: 'tel',
                                                  path: lead.phone,
                                                );
                                                if (await canLaunchUrl(
                                                  phoneUri,
                                                )) {
                                                  await launchUrl(phoneUri);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Colors.green,
                                              ),
                                            )
                                          else
                                            IconButton(
                                              onPressed: null,
                                              icon: Icon(
                                                Icons.phone,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          if ((lead.whatsapp ?? '').isNotEmpty)
                                            IconButton(
                                              onPressed: () async {
                                                final url =
                                                    'https://wa.me/${lead.whatsapp}';
                                                if (await canLaunchUrl(
                                                  Uri.parse(url),
                                                )) {
                                                  await launchUrl(
                                                    Uri.parse(url),
                                                    mode:
                                                        LaunchMode
                                                            .externalApplication,
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Cannot open WhatsApp for ${lead.name}',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const FaIcon(
                                                FontAwesomeIcons.whatsapp,
                                                color: Colors.teal,
                                              ),
                                            )
                                          else
                                            IconButton(
                                              onPressed: null,
                                              icon: Icon(
                                                Icons.chat,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          if ((lead.email ?? '').isNotEmpty)
                                            IconButton(
                                              onPressed: () {
                                                /* open email */
                                              },
                                              icon: const Icon(
                                                Icons.email_outlined,
                                                color: Colors.indigo,
                                              ),
                                            )
                                          else
                                            IconButton(
                                              onPressed: null,
                                              icon: Icon(
                                                Icons.email_outlined,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => LeadCreation(
                                                        leadId: _lead!.id,
                                                        isEdit: true,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Contact & Classification
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                              margin: const EdgeInsets.only(
                                bottom: 16,
                              ), // add gap below
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Contact',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildFieldRow(
                                      icon: Icons.phone,
                                      label: 'Phone',
                                      value: lead.phone,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildFieldRow(
                                      icon: Icons.chat,
                                      label: 'WhatsApp',
                                      value: lead.whatsapp,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildFieldRow(
                                      icon: Icons.email_outlined,
                                      label: 'Email',
                                      value: lead.email,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildFieldRow(
                                      icon: Icons.language,
                                      label: 'Website',
                                      value: lead.website,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Classification',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        if ((lead.leadType ?? '').isNotEmpty)
                                          Chip(
                                            label: Text(lead.leadType!),
                                            backgroundColor:
                                                Colors.orange.shade50,
                                          ),
                                        if ((lead.source ?? '').isNotEmpty)
                                          Chip(
                                            label: Text(
                                              'Source: ${lead.source}',
                                            ),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                          ),
                                        if (lead.assignedTo.isNotEmpty)
                                          Chip(
                                            label: Text(
                                              'Assigned: ${lead.assignedTo}',
                                            ),
                                            backgroundColor:
                                                Colors.green.shade50,
                                          ),
                                        if ((lead.region ?? '').isNotEmpty)
                                          Chip(
                                            label: Text(
                                              'Region: ${lead.region}',
                                            ),
                                            backgroundColor:
                                                Colors.purple.shade50,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'Created:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            DateFormat.yMMMd().add_jm().format(
                                              lead.createdOn,
                                            ),
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildAddressCard(),

                        const SizedBox(height: 12),

                        // More info
                        SizedBox(
                          width:
                              double.infinity, // Forces full horizontal width
                          child: Card(
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'More Info',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildInfoChip(
                                        'Employees',
                                        lead.noOfEmployees,
                                        Icons.groups,
                                        Colors.teal,
                                      ),
                                      _buildInfoChip(
                                        'Qualification',
                                        lead.qualificationStatus,
                                        Icons.verified,
                                        Colors.green,
                                      ),
                                      _buildInfoChip(
                                        'GST Category',
                                        lead.gstCategory,
                                        Icons.receipt_long,
                                        Colors.indigo,
                                      ),
                                      _buildInfoChip(
                                        'GSTIN',
                                        lead.gstin,
                                        Icons.confirmation_num,
                                        Colors.brown,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width:
                              double
                                  .infinity, // Ensures card fills horizontal space
                          child: Card(
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.only(
                              bottom: 20,
                            ), // Adds spacing below
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.assignment_turned_in,
                                        color: Colors.deepOrange,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Requirement',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // Optionally add a status badge or icon here!
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    lead.note!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Attachments
                        Card(
                          color: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Attachments',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: _pickAndUploadFile,
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 110,
                                  child:
                                      _attachments.isEmpty
                                          ? const Center(
                                            child: Text('No attachments'),
                                          )
                                          : ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _attachments.length,
                                            separatorBuilder:
                                                (_, __) =>
                                                    const SizedBox(width: 12),
                                            itemBuilder: (context, index) {
                                              final a = _attachments[index];
                                              return InkWell(
                                                // onTap: () async {
                                                //   final url = '${await UserService.baseUrl}${a.fileUrl}';
                                                //   if (await canLaunchUrl(Uri.parse(url))) {
                                                //     await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                                //   } else {
                                                //     ScaffoldMessenger.of(context).showSnackBar(
                                                //       SnackBar(
                                                //         content: Text('Cannot open ${a.name}'),
                                                //         backgroundColor: Colors.red,
                                                //       ),
                                                //     );
                                                //   }
                                                // },
                                                onTap: () async {
                                                  final url =
                                                      '${await UserService.baseUrl}${a.fileUrl}';
                                                  final uri = Uri.parse(url);

                                                  try {
                                                    await launchUrl(
                                                      uri,
                                                      mode:
                                                          LaunchMode
                                                              .externalApplication,
                                                    );
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Cannot open ${a.name}',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                },

                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 100,
                                                      height: 70,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[100],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade300,
                                                        ),
                                                      ),
                                                      child:
                                                          a.thumbnailUrl != null
                                                              ? ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                child: Image.network(
                                                                  a.thumbnailUrl!,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        c,
                                                                        e,
                                                                        s,
                                                                      ) => const Center(
                                                                        child: Icon(
                                                                          Icons
                                                                              .broken_image,
                                                                        ),
                                                                      ),
                                                                ),
                                                              )
                                                              : Center(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .attachment,
                                                                      size: 34,
                                                                    ),
                                                                    SizedBox(
                                                                      height: 4,
                                                                    ),
                                                                    Text(
                                                                      a.mimeType,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    SizedBox(
                                                      width: 100,
                                                      child: Text(
                                                        a.name,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                ),
                              ],
                            ),
                          ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        ...(_followups.isNotEmpty
                            ? [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _followups.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: Icon(
                                                icon,
                                                size: 8,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (idx != _followups.length - 1)
                                              Container(
                                                width: 2,
                                                height: 80,
                                                margin: const EdgeInsets.only(
                                                  top: 6,
                                                ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      it.by,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  it.note.isEmpty
                                                      ? 'No remarks'
                                                      : it.note,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: color
                                                            .withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            icon,
                                                            size: 14,
                                                            color: color,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            it.channel,
                                                            style: TextStyle(
                                                              color: color,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                                              child: Text(
                                                                'Edit',
                                                              ),
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
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    DateFormat.yMMMd()
                                                        .add_jm()
                                                        .format(it.creation),
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
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text('No follow-up history'),
                                ),
                              ),
                            ]
                            : []),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
