import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class LeaveApplication extends StatefulWidget {
  const LeaveApplication({super.key});

  @override
  State<LeaveApplication> createState() => _LeaveApplicationState();
}

class _LeaveApplicationState extends State<LeaveApplication> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _totalDaysController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _halfDayDateController = TextEditingController();

  // Variables

  List<String> leaveTypes = [];
  bool halfDayAllowed = false;
  bool _loading = true;
  bool _submitting = false;

  String? _selectedLeaveType;
  bool _isHalfDay = false;
  String? _selectedHalfDaySession; // FN or AN
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadMetaData();
  }

  Future<void> _loadMetaData() async {
    try {
      final meta = await UserService.fetchLeaveMetaData();

      setState(() {
        // Prefill employee details
        _employeeIdController.text = meta["employee_id"] ?? "";
        _employeeNameController.text = meta["employee_name"] ?? "";
        _departmentController.text = meta["department"] ?? "";

        // Leave types
        leaveTypes = List<String>.from(meta["leave_types"] ?? []);

        // Half day permission
        halfDayAllowed = (meta["half_day_allowed"] ?? 0) == 1;

        _loading = false;
      });
    } catch (e) {
      _loading = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load metadata")));
    }
  }

  final List<String> sessions = ['FN', 'AN'];

  // Function to pick date
  Future<void> _selectDate(
    TextEditingController controller,
    bool isFromDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _calculateTotalDays();
      });
    }
  }

  // Calculate total days between from/to
  void _calculateTotalDays() {
    if (_fromDate != null && _toDate != null) {
      final difference = _toDate!.difference(_fromDate!).inDays + 1;
      _totalDaysController.text = difference.toString();
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitting = true);

      final leaveData = {
        'employee_id': _employeeIdController.text,
        'employee_name': _employeeNameController.text,
        'department': _departmentController.text,
        'leave_type': _selectedLeaveType,
        'from_date': _fromDateController.text,
        'to_date': _toDateController.text,
        'total_days': _totalDaysController.text,
        'half_day': _isHalfDay,
        'session': _selectedHalfDaySession,
        'reason': _reasonController.text,
        'half_day_date': _halfDayDateController.text,
      };

      try {
        await UserService.createLeaveApplication(leaveData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave Application Created'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        final errorText = e.toString().replaceFirst("Exception: ", "");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _submitting = false);
        }
      }
    }
  }

  // ---------- TEXT FIELD ----------
  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    IconData? icon,
    bool required = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
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
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2),
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

  // ---------- DROPDOWN FIELD ----------
  Widget _dropdownField(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: (val) {
          if (required && (val == null || val.isEmpty)) {
            return '';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: required ? "$label *" : label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.orange, width: 2),
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
        items:
            options
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Application'),
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
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _textField(
                _employeeIdController,
                'Employee ID / Code',
                readOnly: true,
                required: true,
                icon: Icons.badge_outlined,
              ),
              _textField(
                _employeeNameController,
                'Employee Name',
                readOnly: true,
                required: true,
                icon: Icons.person_outline,
              ),
              _textField(
                _departmentController,
                'Department / Designation',
                icon: Icons.apartment_outlined,
              ),

              _dropdownField(
                'Leave Type',
                _selectedLeaveType,
                leaveTypes,
                (val) => setState(() => _selectedLeaveType = val),
                required: true,
              ),

              _textField(
                _fromDateController,
                'From Date',
                readOnly: true,
                icon: Icons.calendar_today_outlined,
                required: true,
                onTap: () => _selectDate(_fromDateController, true),
              ),
              _textField(
                _toDateController,
                'To Date',
                readOnly: true,
                icon: Icons.calendar_today_outlined,
                required: true,
                onTap: () => _selectDate(_toDateController, false),
              ),
              _textField(
                _totalDaysController,
                'Total Days',
                readOnly: true,
                icon: Icons.timelapse_outlined,
              ),

              const SizedBox(height: 8),
              if (halfDayAllowed)
                Row(
                  children: [
                    const Text(
                      'Half Day',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      inactiveThumbColor: Colors.orange,
                      inactiveTrackColor: Colors.white,
                      activeColor: Colors.orange,
                      value: _isHalfDay,
                      onChanged: (val) {
                        setState(() {
                          _isHalfDay = val;
                          if (!_isHalfDay) {
                            _selectedHalfDaySession = null;
                            _halfDayDateController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),

              if (_isHalfDay)
                Column(
                  children: [
                    _textField(
                      _halfDayDateController,
                      'Half Day Date',
                      icon: Icons.calendar_today_outlined,
                      required: true,
                      readOnly: true,
                      onTap: () => _selectDate(_halfDayDateController, false),
                    ),
                    _dropdownField(
                      'Session (FN / AN)',
                      _selectedHalfDaySession,
                      sessions,
                      (val) => setState(() => _selectedHalfDaySession = val),
                      required: true,
                    ),
                  ],
                ),

              _textField(
                _reasonController,
                'Leave Reason / Description',
                maxLines: 4,
                required: true,
                icon: Icons.note_alt_outlined,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _submitting
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Create Application',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
