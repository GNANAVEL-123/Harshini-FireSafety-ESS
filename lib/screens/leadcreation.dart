import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadCreation extends StatefulWidget {
  final String? leadId;
  final bool isEdit;
  const LeadCreation({super.key, this.leadId, this.isEdit = false});

  @override
  State<LeadCreation> createState() => _LeadCreationState();
}

class _LeadCreationState extends State<LeadCreation>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  final TextEditingController _leadName = TextEditingController();
  final TextEditingController _companyName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobileNo = TextEditingController();
  final TextEditingController _whatsappNo = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _annualRevenue = TextEditingController();
  final TextEditingController _noOfEmployees = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // Dropdowns
  String? _leadowner;
  String? _assignedto;
  String? _allocated_to_manager;
  String? _customer;
  String? _industry;
  String? _status;
  String? _leadsource;
  String? _territory;
  String? _company;
  bool isLoadingMeta = true;
  bool iscompanyset = true;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  File? _imageFile;

  List<String> userOptions = [];
  List<String> statusOptions = [];
  List<String> industries = [];
  List<String> companyoptions = [];
  List<String> itemoptions = [];
  List<String> leadsourceoptions = [];
  List<String> territoryoption = [];
  List<String> _selectedItems = [];
  List<String> customeroptions = [];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );
    if (pickedImage != null) {
      setState(() => _imageFile = File(pickedImage.path));
    }
  }

  void _showAddFollowUpSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
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
                  const Center(
                    child: Text(
                      "Add Follow Up",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _dateField("Next Follow-up Date"),
                  const SizedBox(height: 15),
                  _textField(
                    _remarksController,
                    "Remarks",
                    icon: Icons.note_alt,
                  ),
                  const SizedBox(height: 20),

                  // -------------------
                  //    BUTTONS ROW
                  // -------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // CLEAR BUTTON
                      ElevatedButton.icon(
                        style: _primaryButtonStyle(Colors.grey.shade500),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _dateController.clear();
                            _remarksController.clear();
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear, color: Colors.white),
                        label: const Text(
                          "Clear",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      // CONFIRM BUTTON
                      ElevatedButton.icon(
                        style: _primaryButtonStyle(Colors.orangeAccent),
                        onPressed: () {
                          if (_selectedDate == null ||
                              _remarksController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please fill all required fields",
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          "Confirm",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget bodyLoader() {
    return Center(child: CupertinoActivityIndicator(radius: 14));
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _loadMeta();

    if (widget.isEdit && widget.leadId != null) {
      _loadLeadForEdit();
    }

    _fetchlocalstorage();
  }

  Future<void> _fetchlocalstorage() async {
    final prefs = await SharedPreferences.getInstance();

    iscompanyset = prefs.getBool('is_default_company_set') ?? false;
  }

  Future<void> _loadLeadForEdit() async {
    try {
      final data = await UserService.fetchLeadByName(widget.leadId!);

      setState(() {
        _leadName.text = data["lead_name"] ?? "";
        _leadowner = data["lead_owner"];
        _assignedto = data["custom_assigned_to"];
        _allocated_to_manager = data["custom_allocated_to_manager"];
        _status = data["status"];
        _company = data["company"];
        _leadsource = data["source"];
        _customer = data["customer"];
        _territory = data["territory"];
        _industry = data["industry"];
        _email.text = data["email_id"] ?? "";
        _whatsappNo.text = data["mobile_no"] ?? "";
        _phone.text = data["phone"] ?? "";
        _address.text = data["address"] ?? "";
        _annualRevenue.text = data["annual_revenue"]?.toString() ?? "";
        _noOfEmployees.text = data["no_of_employees"]?.toString() ?? "";
        _notes.text = data["custom_remarks"] ?? "";
        _selectedItems =
            (data["custom_item_request_type"] as List?)
                ?.map((e) => e["item"].toString())
                .toList() ??
            [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      isLoadingMeta = true;
    });

    try {
      // Fetch metadata from your backend
      final meta = await UserService.fetchMetaData();

      final s = meta['lead_meta'];

      final users = meta['user'];

      final industrieslist = meta['industry'];

      final itemlist = meta['itemlist'];

      final companieslist = meta['companies'];

      final customerlist = meta['customer'];

      final territorylist = meta['territory'];

      final leadsourcelist = meta['lead_source'];

      // Apply to UI
      setState(() {
        if (users is List) {
          userOptions = users.map((e) => e.toString()).toList();
        }

        if (s is List) {
          statusOptions = s.map((e) => e.toString()).toList();
        }

        if (industrieslist is List) {
          industries = industrieslist.map((e) => e.toString()).toList();
        }

        if (itemlist is List) {
          itemoptions = itemlist.map((e) => e.toString()).toList();
        }

        if (customerlist is List) {
          customeroptions = customerlist.map((e) => e.toString()).toList();
        }

        if (companieslist is List) {
          companyoptions = companieslist.map((e) => e.toString()).toList();
        }
        if (territorylist is List) {
          territoryoption = territorylist.map((e) => e.toString()).toList();
        }
        if (leadsourcelist is List) {
          leadsourceoptions = leadsourcelist.map((e) => e.toString()).toList();
        }

        isLoadingMeta = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMeta = false;
      });
    }
  }

  List<String> _validateMandatoryFields() {
    List<String> missing = [];

    if (_leadName.text.trim().isEmpty) missing.add("Lead Name");
    if(_email.text.trim().isEmpty) missing.add('Email');
    if(_whatsappNo.text.trim().isEmpty) missing.add('Whatsapp No');
    if (_assignedto == null || _assignedto!.isEmpty) missing.add("Assigned To");
    if (_status == null || _status!.isEmpty) missing.add("Status");

    return missing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Lead", style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFFFA000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body:
          isLoadingMeta
              ? bodyLoader()
              : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFFFA000)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      /// ✅ TAB BAR INSIDE BODY
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.orange,
                        labelColor: Colors.orange,
                        unselectedLabelColor: Colors.grey,
                        dividerColor: Colors.white,
                        tabs: [
                          Tab(text: "Mandatory Info"),
                          Tab(text: "Other Info"),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// ✅ TAB CONTENT
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              /// ---------------- Mandatory Info Tab ----------------
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionTitle("🧾 Basic Lead Information"),
                                    _card([
                                      _textField(
                                        _leadName,
                                        "Lead Name",
                                        required: true,
                                      ),
                                      _textField(_email, "Email",required: true),
                                      _textField(
                                        _whatsappNo,
                                        "WhatsApp Number",
                                        keyboard: TextInputType.phone,
                                        required: true
                                      ),
                                      // _searchableDropdownField(
                                      //   "Lead Owner",
                                      //   _leadowner,
                                      //   userOptions,
                                      //   (val) =>
                                      //       setState(() => _leadowner = val),
                                      //   required: true,
                                      // ),
                                      _searchableDropdownField(
                                        "Assigned To",
                                        _assignedto,
                                        userOptions,
                                        (val) =>
                                            setState(() => _assignedto = val),
                                        required: true,
                                      ),
                                      _searchableDropdownField(
                                        "Status",
                                        _status,
                                        statusOptions,
                                        (val) => setState(() => _status = val),
                                        required: true,
                                      ),
                                    ]),
                                  ],
                                ),
                              ),

                              /// ---------------- Other Info Tab ----------------
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionTitle("🏢 Business Information"),
                                    _card([
                                      if (!iscompanyset)
                                        _searchableDropdownField(
                                          "Company Name",
                                          _company,
                                          companyoptions,
                                          (val) =>
                                              setState(() => _company = val),
                                        ),
                                      _searchableDropdownField(
                                        "Lead Source",
                                        _leadsource,
                                        leadsourceoptions,
                                        (val) =>
                                            setState(() => _leadsource = val),
                                      ),
                                      _searchableDropdownField(
                                        "Assigned to Manager",
                                        _allocated_to_manager,
                                        userOptions,
                                        (val) => setState(
                                          () => _allocated_to_manager = val,
                                        ),
                                      ),
                                      _searchableDropdownField(
                                        "Customer",
                                        _customer,
                                        customeroptions,
                                        (val) =>
                                            setState(() => _customer = val),
                                      ),
                                      _searchableDropdownField(
                                        "Territory",
                                        _territory,
                                        territoryoption,
                                        (val) =>
                                            setState(() => _territory = val),
                                      ),
                                      _searchableDropdownField(
                                        "Industry",
                                        _industry,
                                        industries,
                                        (val) =>
                                            setState(() => _industry = val),
                                      ),
                                      // _textField(
                                      //   _annualRevenue,
                                      //   "Annual Revenue",
                                      //   keyboard: TextInputType.number,
                                      // ),
                                      // _textField(
                                      //   _noOfEmployees,
                                      //   "No. of Employees",
                                      //   keyboard: TextInputType.number,
                                      // ),
                                      _multiSelectField("Items", itemoptions),
                                    ]),

                                    _sectionTitle(
                                      "📞 Additional Contact Details",
                                    ),
                                    _card([
                                      _textField(
                                        _phone,
                                        "Secondary Mobile Number",
                                        keyboard: TextInputType.phone,
                                      ),
                                      _textField(
                                        _address,
                                        "Address",
                                        maxLines: 2,
                                      ),
                                    ]),

                                    _sectionTitle("💬 Interaction & Notes"),
                                    _card([
                                      _textField(
                                        _notes,
                                        "Description / Notes",
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 5),
                                      ElevatedButton.icon(
                                        onPressed: _showAddFollowUpSheet,
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Add Follow Up",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: _primaryButtonStyle(
                                          Colors.orangeAccent,
                                        ),
                                      ),
                                    ]),
                                    // _sectionTitle("📸 Attachments"),
                                    // _card([
                                    //   Row(
                                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //     children: [
                                    //       const Text("Photo / Business Card",
                                    //           style: TextStyle(
                                    //               fontSize: 15, fontWeight: FontWeight.w500)),
                                    //       IconButton(
                                    //         icon: const Icon(Icons.camera_alt, color: Colors.blue),
                                    //         onPressed: _pickImage,
                                    //       ),
                                    //     ],
                                    //   ),
                                    //   if (_imageFile != null)
                                    //     ClipRRect(
                                    //       borderRadius: BorderRadius.circular(10),
                                    //       child: Image.file(_imageFile!,
                                    //           height: 120,
                                    //           width: double.infinity,
                                    //           fit: BoxFit.cover),
                                    //     ),
                                    // ]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _saveLead,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: Text(
                                widget.isEdit ? "Update Lead" : "Save Lead",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),

                              style: _primaryButtonStyle(Colors.orangeAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // ---------- REUSABLE UI HELPERS ----------

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    ),
  );

  Widget _card(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
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
            return ''; // Leave message empty; red border will show
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: required ? "$label *" : label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          // Normal states
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          // Error states
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          errorStyle: const TextStyle(height: 0), // hide error text
        ),
      ),
    );
  }

  Widget _multiSelectField(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () async {
          final selected = await showDialog<List<String>>(
            context: context,
            builder: (context) {
              List<String> tempSelected = List.from(_selectedItems);
              List<String> filteredOptions = List.from(options);
              final searchController = TextEditingController();

              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text("Select $label"),
                content: SizedBox(
                  width: double.maxFinite,
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔍 SEARCH FIELD
                          TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: "Search $label",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                filteredOptions =
                                    options
                                        .where(
                                          (item) => item.toLowerCase().contains(
                                            value.toLowerCase(),
                                          ),
                                        )
                                        .toList();
                              });
                            },
                          ),
                          const SizedBox(height: 10),

                          // 📋 LIST
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children:
                                  filteredOptions.map((item) {
                                    return CheckboxListTile(
                                      value: tempSelected.contains(item),
                                      title: Text(item),
                                      onChanged: (bool? selectedValue) {
                                        setDialogState(() {
                                          if (selectedValue == true) {
                                            tempSelected.add(item);
                                          } else {
                                            tempSelected.remove(item);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedItems),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, tempSelected),
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );

          if (selected != null) {
            setState(() {
              _selectedItems = selected;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _selectedItems.isEmpty
                      ? "Select $label"
                      : _selectedItems.join(", "),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _selectedItems.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchableDropdownField(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    final TextEditingController controller = TextEditingController(
      text: value ?? '',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FormField<String>(
        initialValue: value,
        validator: (val) {
          if (required && (val == null || val.isEmpty)) {
            return '';
          }
          return null;
        },
        builder: (FormFieldState<String> field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeAheadField<String>(
                controller: controller,
                suggestionsCallback: (pattern) {
                  return options
                      .where(
                        (e) => e.toLowerCase().contains(pattern.toLowerCase()),
                      )
                      .toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(
                      suggestion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                onSelected: (suggestion) {
                  controller.text = suggestion;
                  field.didChange(suggestion);
                  onChanged(suggestion);
                },
                decorationBuilder: (context, child) {
                  return Material(
                    color: Colors.white, // ✅ dropdown background
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },

                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: required ? "$label *" : label,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,

                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorStyle: const TextStyle(height: 0),

                      suffixIcon:
                          controller.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  controller.clear();
                                  field.didChange(null);
                                  onChanged(null);
                                },
                              )
                              : const Icon(Icons.arrow_drop_down),
                    ),
                  );
                },
              ),

              /// 🔴 Error space (kept invisible like your dropdown)
              if (field.hasError) const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevents tapping outside
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 30),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop(); // close the dialog
      Navigator.of(context).pop(); // pop current page if needed
    });
  }

  void _saveLead() async {
    final missingFields = _validateMandatoryFields();

    if (missingFields.isNotEmpty) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please fill mandatory fields: ${missingFields.join(", ")}",
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(vertical: 80, horizontal: 10),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    try {
      final followUps = [
        {
          "description": _remarksController.text,
          "next_follow_up_date": _dateController.text,
        },
      ];

      final response =
          widget.leadId == null
              ? await UserService.createLead(
                leadName: _leadName.text,
                leadOwner: _leadowner ?? '',
                status: _status,
                assignedTo: _assignedto,
                allocated_to_manager: _allocated_to_manager,
                companyName: _company,
                leadSource: _leadsource,
                customer: _customer,
                territory: _territory,
                industry: _industry,
                items: _selectedItems,
                email: _email.text,
                whatsappNo: _whatsappNo.text,
                phone: _phone.text,
                address: _address.text,
                annualRevenue: _annualRevenue.text,
                noOfEmployees: _noOfEmployees.text,
                notes: _notes.text,
                followUps: followUps,
              )
              : await UserService.updateLead(
                leadId: widget.leadId!,
                leadName: _leadName.text,
                leadOwner: _leadowner ?? '',
                status: _status,
                assignedTo: _assignedto,
                allocated_to_manager: _allocated_to_manager,
                companyName: _company,
                leadSource: _leadsource,
                customer: _customer,
                territory: _territory,
                industry: _industry,
                items: _selectedItems,
                email: _email.text,
                whatsappNo: _whatsappNo.text,
                phone: _phone.text,
                address: _address.text,
                annualRevenue: _annualRevenue.text,
                noOfEmployees: _noOfEmployees.text,
                notes: _notes.text,
                followUps: followUps,
              );


      if (response["success"]) {
        // _showSuccessDialog(
        //   widget.leadId == null
        //       ? "Lead saved successfully ✅"
        //       : "Lead updated successfully ✅",
        // );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.leadId == null
                  ? "Lead saved successfully ✅"
                  : "Lead updated successfully ✅",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Widget _dateField(String label) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey, width: 2),
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
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: const Color(0xFFD32F2F),
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
          });
        }
      },
      controller: _dateController,
    );
  }

  Widget _timeField(String label) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        prefixIcon: const Icon(Icons.access_time, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey, width: 2),
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
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: const Color(0xFFD32F2F),
                  secondary: const Color(0xFFFFA000),
                  onSurface: Colors.black,
                ),
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Colors.white,
                  hourMinuteColor: Colors.white,
                  hourMinuteTextColor: const Color(0xFFD32F2F),
                  dialHandColor: const Color(0xFFD32F2F),
                  dialBackgroundColor: Colors.white,
                  entryModeIconColor: const Color(0xFFD32F2F),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedTime = picked;
            _timeController.text = picked.format(context);
          });
        }
      },
      controller: _timeController,
    );
  }

  ButtonStyle _primaryButtonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 2,
  );
}
