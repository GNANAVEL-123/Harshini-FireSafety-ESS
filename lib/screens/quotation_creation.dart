import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:harshinifireess/screens/quotation_itemtable.dart';
import 'package:harshinifireess/screens/quotation_taxtable.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryOrange = Color(0xFFFF7A00);
const Color lightBg = Color(0xFFFDFDFD);

enum DiscountOn { netTotal, grandTotal }

class QuotationCreation extends StatefulWidget {
  final String? quotationId;

  const QuotationCreation({super.key, this.quotationId});

  @override
  State<QuotationCreation> createState() => _QuotationCreationState();
}

class _QuotationCreationState extends State<QuotationCreation>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  late TabController _tabController;

  List customers = [];
  List leads = [];
  List items = [];
  List<QuotationItem> quotationItems = [];

  List<String> taxCategories = [];
  List<Map<String, dynamic>> salesTaxTemplates = [];
  List<String> priceLists = [];

  String? selectedTaxCategory = 'In-State';
  String? selectedTaxTemplate;
  String? selectedPriceList = 'Standard Selling';
  DiscountOn discountOn = DiscountOn.netTotal;

  List<SalesTax> taxes = [];

  List<String> quotationTypes = [];

  List territory = [];
  List users = [];
  List<Map<String, dynamic>> companies = [];

  String? selectedCompany;
  double defaultGstRate = 0.0;

  double netTotal = 0.0;
  double total = 0.0;

  bool loading = true;

  double invoiceDiscount = 0.0;
  double discountedNetTotal = 0.0;
  double grandTotal = 0.0;

  bool iscompanyset = false;
  bool istaxcategoryset = false;
  bool issalestaxestemplate = false;
  bool ispricelist = false;

  String quotationTo = 'Customer';
  String? quotationType;

  String? selectedCustomer;
  String? selectedLead;
  String? selectedRegion;
  String? selectedQuotationowner;
  String? selectedAllocatedto;

  bool isValidated = false;
  Map<String, dynamic>? validatedData;

  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController territoryCtrl = TextEditingController();
  final TextEditingController kindAttentionCtrl = TextEditingController();
  final TextEditingController phonenumberCtrl = TextEditingController();
  // final TextEditingController visitCountCtrl = TextEditingController();

  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeta();
    _fetchlocalstorage();
    if (widget.quotationId != null) {
      isEditMode = true;
      _loadQuotationForEdit(widget.quotationId!);
    }
  }

  Future<void> _fetchlocalstorage() async {
    final prefs = await SharedPreferences.getInstance();

    iscompanyset = prefs.getBool('is_default_company_set') ?? false;
    istaxcategoryset = prefs.getBool('is_default_tax_category_set') ?? false;
    issalestaxestemplate =
        prefs.getBool('is_default_sales_taxes_and_charges_template_set') ??
        false;
    ispricelist = prefs.getBool('is_default_price_list_set') ?? false;
    setState(() {
      selectedTaxCategory =
          prefs.getString('default_tax_category') ?? 'In-State';
      selectedCompany = prefs.getString('default_company');
      selectedTaxTemplate = prefs.getString(
        'default_sales_taxes_and_charges_template',
      );
      selectedPriceList =
          prefs.getString('default_price_list') ?? 'Standard Selling';
    });
  }

  Future<void> _loadQuotationForEdit(String quotationId) async {
    try {
      setState(() => loading = true);

      final data = await UserService.fetchQuotationDetails(quotationId);

      setState(() {
        // HEADER
        quotationTo = data["quotation_to"];
        selectedCustomer = data["party_name"];
        selectedLead = data["party_name"];
        partyNameCtrl.text = data["party_name"] ?? "";
        selectedQuotationowner = data["custom_assigned_to"] ?? "";
        selectedAllocatedto = data["custom_assigned_to"] ?? "";
        selectedCompany = data["company"] ?? "";
        // visitCountCtrl.text = data["custom_visit_count"].toString() ?? "";
        quotationType = data['custom_type_of_quotation'] ?? "";
        invoiceDiscount = (data["discount_amount"] ?? 0).toDouble();

        discountOn =
            data["apply_discount_on"] == "Grand Total"
                ? DiscountOn.grandTotal
                : DiscountOn.netTotal;

        kindAttentionCtrl.text = data["custom_kind_attn"] ?? "";
        phonenumberCtrl.text = data["custom_phone"] ?? "";
        selectedRegion = data["custom_region"];
        territoryCtrl.text = data["custom_region"] ?? "";
        selectedTaxCategory = data["tax_category"] ?? "";
        selectedTaxTemplate = data["taxes_and_charges"] ?? "";
        selectedCompany = data["company"] ?? "";

        // ITEMS
        quotationItems =
            (data["items"] as List).map((item) {
              return QuotationItem(
                itemCode: item["item_code"],
                itemName: item["item_name"] ?? "",
                qty: (item["qty"] ?? 0).toDouble(),
                uom: item["uom"],
                rate: (item["price_list_rate"] ?? item["rate"] ?? 0).toDouble(),
                discountAmount: (item["discount_amount"] ?? 0).toDouble(),
              );
            }).toList();

        // TAXES
        taxes =
            (data["taxes"] as List).map((t) {
              return SalesTax(
                chargeType: t["charge_type"],
                accountHead: t["account_head"],
                rate: (t["rate"] ?? 0).toDouble(),
                taxAmount: (t["tax_amount"] ?? 0).toDouble(),
              );
            }).toList();

        // TOTALS
        netTotal = data["net_total"].toDouble();
        total = data["total"].toDouble();
        grandTotal = data["grand_total"].toDouble();

        isValidated = true; // already validated quotation
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadMeta() async {
    try {
      final data = await UserService.fetchQuotationMeta();
      setState(() {
        customers = data["customers"];
        leads = data["leads"];
        items = data["items"];
        taxes =
            ((data["taxes"] ?? []) as List)
                .map(
                  (t) => SalesTax(
                    chargeType: t["charge_type"] ?? "",
                    accountHead: t["account_head"] ?? "",
                    rate: (t["rate"] ?? 0).toDouble(),
                  ),
                )
                .toList();

        users = data["users"];
        territory = data['territory'];
        taxCategories = List<String>.from(data["tax_categories"]);
        salesTaxTemplates = List<Map<String, dynamic>>.from(
          data["sales_tax_templates"],
        );
        priceLists = List<String>.from(data["price_lists"]);

        quotationTypes = List<String>.from(data["quotation_types"]);

        companies = List<Map<String, dynamic>>.from(data["companies"]);

        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  // ---------------- DISCOUNT INPUT ----------------
  Widget _buildDiscountCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Discount',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: invoiceDiscount.toStringAsFixed(2),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              setState(() {
                invoiceDiscount = double.tryParse(val) ?? 0.0;
                _recalculateTotals(); // recalc totals on discount change
              });
              _markDirty();
            },
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getPartyOptions() {
    if (quotationTo == "Customer") {
      return customers
          .map<DropdownMenuItem<String>>(
            (c) => DropdownMenuItem<String>(
              value: c["name"],
              child: Text(c["customer_name"]),
            ),
          )
          .toList();
    } else {
      return leads
          .map<DropdownMenuItem<String>>(
            (l) => DropdownMenuItem<String>(
              value: l["name"],
              child: Text(l["lead_name"] ?? l["company_name"]),
            ),
          )
          .toList();
    }
  }

  void _recalculateTotals() {
    double baseAmount = netTotal;
    double totalTax = 0.0;

    if (discountOn == DiscountOn.grandTotal) {
      // 1️⃣ Calculate taxes on net total first
      for (var tax in taxes) {
        tax.taxAmount = baseAmount * tax.rate / 100;
        totalTax += tax.taxAmount;
      }

      // 2️⃣ Grand total with discount applied
      discountedNetTotal = baseAmount + totalTax - invoiceDiscount;
      discountedNetTotal = discountedNetTotal.clamp(0.0, double.infinity);
    } else {
      // Discount on net total, so taxes applied after discount
      discountedNetTotal = baseAmount - invoiceDiscount;
      discountedNetTotal = discountedNetTotal.clamp(0.0, double.infinity);

      // Recalculate taxes on discounted net total
      totalTax = 0.0;
      for (var tax in taxes) {
        tax.taxAmount = discountedNetTotal * tax.rate / 100;
        totalTax += tax.taxAmount;
      }

      // Add taxes to discounted net total for display
      discountedNetTotal += totalTax;
    }

    // Notify Grand Total
    grandTotal = discountedNetTotal;

    // Trigger UI update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _validateQuotation() async {
    if (!_validateRequiredFields()) return;
    try {
      setState(() {
        loading = true;
      });
      final payload = _buildQuotationPayload();
      final response = await UserService.validateQuotation(payload);

      if (response["valid"] != true) {
        final errors = List<String>.from(response["errors"] ?? []);
        final message =
            errors.isNotEmpty ? errors.join('\n') : "Validation failed";
        scaffoldMessengerKey.currentState?.clearSnackBars();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      setState(() {
        validatedData = response;
        isValidated = true;
        _applyValidatedData(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _applyValidatedData(Map<String, dynamic> data) {
    // Preserve original discount amounts
    final originalDiscounts = {
      for (final item in quotationItems) item.itemCode: item.discountAmount,
    };

    quotationItems.clear();

    for (final item in data["items"]) {
      final qty = (item["qty"] ?? 0).toDouble();
      final rate = (item["rate"] ?? 0).toDouble();
      final discountAmount = (item["discount_amount"] ?? 0).toDouble();

      quotationItems.add(
        QuotationItem(
          itemCode: item["item_code"],
          itemName: item["item_name"] ?? "",
          qty: qty,
          uom: item["uom"],
          rate: rate,
          discountAmount:
              originalDiscounts[item["item_code"]] ?? discountAmount,
        ),
      );
    }

    netTotal =
        isEditMode
            ? data["totals"]["total"].toDouble()
            : data["totals"]["net_total"].toDouble();
    invoiceDiscount = data["totals"]["discount_amount"].toDouble();
    grandTotal = data["totals"]["grand_total"].toDouble();
  }

  void _markDirty() {
    if (!isValidated) return;

    setState(() {
      isValidated = false;
      validatedData = null;
    });
  }

  bool _validateRequiredFields() {
    List<String> missingFields = [];

    // ---- COMPANY ----
    if (selectedCompany == null || selectedCompany!.isEmpty) {
      missingFields.add("Company");
    }

    // ---- CUSTOMER / LEAD ----
    if (quotationTo == "Customer" &&
        (selectedCustomer == null || selectedCustomer!.isEmpty)) {
      missingFields.add("Customer");
    }

    if (quotationTo == "Lead" &&
        (selectedLead == null || selectedLead!.isEmpty)) {
      missingFields.add("Lead");
    }

    // ---- TERRITORY ----
    if (selectedRegion == null || selectedRegion!.isEmpty) {
      missingFields.add("Territory");
    }

    // ---- QUOTATION TYPE ----
    if (quotationType == null || quotationType!.isEmpty) {
      missingFields.add("Quotation Type");
    }

    // ---- KIND ATTENTION ----
    if (kindAttentionCtrl.text.isEmpty) {
      missingFields.add("Kind Attention");
    }

    // ---- PHONE NUMBER ----
    if (phonenumberCtrl.text.isEmpty || phonenumberCtrl.text.length < 10) {
      missingFields.add("Phone Number");
    }

    // ---- QUOTATION OWNER ----
    if (selectedQuotationowner == null || selectedQuotationowner!.isEmpty) {
      missingFields.add("Quotation Owner");
    }

    // ---- ALLOCATED TO ----
    if (selectedAllocatedto == null || selectedAllocatedto!.isEmpty) {
      missingFields.add("Allocated To");
    }

    // ---- ITEMS ----
    if (quotationItems.isEmpty) {
      missingFields.add("At least one Item");
    }

    // ---- TAX ----
    if (selectedTaxCategory == null ||
        selectedTaxCategory!.isEmpty ||
        !istaxcategoryset) {
      missingFields.add("Tax Category");
    }

    if (selectedTaxTemplate == null ||
        selectedTaxTemplate!.isEmpty ||
        !issalestaxestemplate) {
      missingFields.add("Sales Taxes and Charges Template");
    }

    // ---- SHOW SINGLE ERROR ----
    if (missingFields.isNotEmpty) {
      _showError("Mandatory fields missing – ${missingFields.join(', ')}");
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: lightBg,

        appBar: AppBar(
          foregroundColor: Colors.white,
          title:
              widget.quotationId != null
                  ? Text('Update Quotation')
                  : Text('Create Quotation'),
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Details'), Tab(text: 'Items & Amount')],
          ),
        ),

        body:
            loading
                ? Center(child: CupertinoActivityIndicator(radius: 14))
                : TabBarView(
                  controller: _tabController,
                  children: [_quotationDetailsTab(), _quotationSummaryTab()],
                ),

        /// 🔶 CREATE BUTTON
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (isValidated) {
                    _createQuotation();
                  } else {
                    _validateQuotation();
                  }
                },
                child:
                    loading
                        ? const CupertinoActivityIndicator(
                          radius: 10,
                          color: Colors.white,
                        )
                        : Text(
                          isValidated
                              ? (widget.quotationId != null
                                  ? 'Update Quotation'
                                  : 'Create Quotation')
                              : 'Validate Quotation',
                          style: const TextStyle(color: Colors.white),
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- TAB 1 ----------------

  Widget _quotationDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuotationToCard(),
          const SizedBox(height: 16),
          _buildPartyDetailsCard(),
          const SizedBox(height: 16),
          _buildQuotationTypeCard(),
          const SizedBox(height: 16),
          // _buildVisitCountCard(),
        ],
      ),
    );
  }

  // ---------------- TAB 2 ----------------

  Widget _quotationSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          QuotationItemTable(
            items: quotationItems,
            onItemsChanged: (updatedItems, netTotal) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  quotationItems = updatedItems;
                  this.netTotal = netTotal;
                  _recalculateTotals();
                });
              });
              _markDirty();
            },
          ),

          const SizedBox(height: 20),
          _buildDiscountCard(), // <-- discount input here
          const SizedBox(height: 20),

          Row(
            children: [
              const Text('Discount On: '),
              const SizedBox(width: 12),
              ChoiceChip(
                backgroundColor: Colors.grey,
                selectedColor: Colors.orange,
                checkmarkColor: Colors.white,
                label: const Text(
                  'Net Total',
                  style: TextStyle(color: Colors.white),
                ),
                selected: discountOn == DiscountOn.netTotal,
                onSelected: (_) {
                  setState(() => discountOn = DiscountOn.netTotal);
                  _recalculateTotals();
                  _markDirty();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                backgroundColor: Colors.grey,
                selectedColor: Colors.orange,
                checkmarkColor: Colors.white,
                label: const Text(
                  'Grand Total',
                  style: TextStyle(color: Colors.white),
                ),
                selected: discountOn == DiscountOn.grandTotal,
                onSelected: (_) {
                  setState(() => discountOn = DiscountOn.grandTotal);
                  _recalculateTotals();
                  _markDirty();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          SalesTaxesTable(
            netTotal:
                isEditMode
                    ? (discountOn == DiscountOn.netTotal
                        ? (quotationItems.fold(
                                  0.0,
                                  (sum, item) => sum + item.amount,
                                ) -
                                invoiceDiscount)
                            .clamp(0.0, double.infinity)
                        : quotationItems.fold(
                          0.0,
                          (sum, item) => sum + item.amount,
                        ))
                    : (discountOn == DiscountOn.netTotal
                        ? (netTotal - invoiceDiscount).clamp(
                          0.0,
                          double.infinity,
                        )
                        : netTotal),
            selectedTemplateName: selectedTaxTemplate,
            scaffoldMessengerKey: scaffoldMessengerKey,
            discountOn: discountOn,
            invoiceDiscount: invoiceDiscount,
            onGrandTotalChanged: (value) {
              if (isEditMode) {
                // Backend value is final
                setState(() => grandTotal = value);
              } else {
                // Create flow → calculate
                setState(() {
                  grandTotal =
                      discountOn == DiscountOn.grandTotal
                          ? value - invoiceDiscount
                          : value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------- UI CARDS ----------------

  Widget _buildQuotationToCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Quotation To'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _quotationToOption(
                  title: 'Customer',
                  value: 'Customer',
                  icon: Icons.business,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quotationToOption(
                  title: 'Lead',
                  value: 'Lead',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quotationToOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = quotationTo == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => quotationTo = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryOrange : Colors.grey.shade300,
            width: 1.4,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryOrange : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryOrange : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTypeAheadField<T>({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required List<T> items,
    required String Function(T) displayText,
    required void Function(T) onSelected,
    String? hintText,
    bool enabled = true,
    bool showClear = true,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeAheadField<T>(
          controller: controller,
          // enabled: enabled,
          decorationBuilder: (context, child) {
            return Material(
              color: Colors.white, // ✅ dropdown background
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },

          suggestionsCallback: (pattern) {
            if (pattern.isEmpty) return items;

            return items
                .where(
                  (item) => displayText(
                    item,
                  ).toLowerCase().contains(pattern.toLowerCase()),
                )
                .toList();
          },

          itemBuilder: (context, suggestion) {
            return ListTile(title: Text(displayText(suggestion)));
          },

          onSelected: (suggestion) {
            controller.text = displayText(suggestion);
            onSelected(suggestion);
          },

          builder: (context, textController, focusNode) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                isDense: true,
                labelText: label,
                hintText: hintText,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,

                suffixIcon:
                    showClear && textController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            textController.clear();
                            focusNode.unfocus();
                            if (onClear != null) onClear();
                          },
                        )
                        : null,
              ),
            );
          },

          emptyBuilder:
              (context) => const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "No matching records",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
        ),
      ],
    );
  }

  Future<void> _createQuotation() async {
    if (!_validateRequiredFields()) return;

    try {
      setState(() {
        loading = true;
      });
      final res = await UserService.createQuotation(_buildQuotationPayload());

      if (!mounted) return;

      if (res["valid"] != true) {
        final errors = List<String>.from(res["errors"] ?? []);
        _showError(errors.isNotEmpty ? errors.join('\n') : "Creation failed");
        return;
      }

      final isEdit = widget.quotationId != null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? "Quotation ${res['name']} updated successfully"
                : "Quotation ${res['name']} created successfully",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _showError(String message) {
    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic> _buildQuotationPayload() {
    final party_type =
        quotationTo == 'Customer' ? selectedCustomer : selectedLead;
    return {
      if (widget.quotationId != null) "name": widget.quotationId,
      "quotation_to": quotationTo,
      "company": selectedCompany,
      "party_name": party_type,
      "kind_attention": kindAttentionCtrl.text,
      "custom_phone": phonenumberCtrl.text,
      "lead": selectedLead,
      "territory": selectedRegion,
      // "custom_visit_count": visitCountCtrl.text,
      "custom_type_of_quotation": quotationType,
      "tax_category": selectedTaxCategory,
      "tax_template": selectedTaxTemplate,
      "price_list": selectedPriceList,
      "discount_amount": invoiceDiscount,
      "discount_on":
          discountOn == DiscountOn.netTotal ? "Net Total" : "Grand Total",
      "items":
          quotationItems.map((item) {
            return {
              "item_code": item.itemCode,
              "qty": item.qty,
              "uom": item.uom,
              "rate": item.rate,
              "discount_amount": item.discountAmount,
            };
          }).toList(),
    };
  }

  Widget _buildPartyDetailsCard() {
    return _buildCard(
      child: Column(
        children: [
          if (!iscompanyset)
            buildTypeAheadField<Map<String, dynamic>>(
              label: "Company",
              icon: Icons.business_center,
              controller: TextEditingController(text: selectedCompany),
              items: companies,
              displayText: (c) => c["name"],
              onSelected: (company) {
                setState(() {
                  selectedCompany = company["name"];
                  defaultGstRate =
                      double.tryParse(company["default_gst_rate"].toString()) ??
                      0.0;
                });
              },
              onClear: () {
                setState(() {
                  selectedCompany = null;
                  defaultGstRate = 0.0; // 🔥 GST CLEARED
                });
              },
            ),
          const SizedBox(height: 12),

          buildTypeAheadField(
            label: quotationTo == "Customer" ? "Customer" : "Lead",
            icon: Icons.business,
            controller: partyNameCtrl,
            items: quotationTo == "Customer" ? customers : leads,
            displayText:
                (item) =>
                    quotationTo == "Customer"
                        ? item["customer_name"]
                        : (item["lead_name"] ?? item["company_name"]),
            onSelected: (item) {
              setState(() {
                if (quotationTo == "Customer") {
                  selectedCustomer = item["name"];
                  territoryCtrl.text = item["territory"] ?? "";
                } else {
                  selectedLead = item["name"];
                }
              });
            },
            onClear: () {
              setState(() {
                selectedCustomer = null;
                selectedLead = null;
                selectedTaxCategory = null;
                selectedTaxTemplate = null;
                selectedRegion = null;
              });
            },
          ),

          const SizedBox(height: 12),
          buildTypeAheadField<String>(
            label: "Region",
            icon: Icons.map,
            controller: territoryCtrl,
            items: List<String>.from(territory),
            displayText: (t) => t,
            onSelected: (val) {
              setState(() => selectedRegion = val);
            },
          ),

          const SizedBox(height: 12),
          _buildTextField(
            controller: kindAttentionCtrl,
            label: 'Kind Attention',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 12),
          _buildTextField(
            controller: phonenumberCtrl,
            label: 'Phone Number',
            icon: Icons.call,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),

          buildTypeAheadField<String>(
            label: "Quotation Owner",
            icon: Icons.person,
            controller: TextEditingController(text: selectedQuotationowner),
            items: List<String>.from(users),
            displayText: (u) => u,
            onSelected: (val) {
              setState(() => selectedQuotationowner = val);
            },
          ),

          const SizedBox(height: 12),
          buildTypeAheadField<String>(
            label: "Allocated To",
            icon: Icons.assignment_ind,
            controller: TextEditingController(text: selectedAllocatedto),
            items: List<String>.from(users),
            displayText: (u) => u,
            onSelected: (val) {
              setState(() => selectedAllocatedto = val);
            },
          ),
          const SizedBox(height: 12),
          if (!istaxcategoryset)
            buildTypeAheadField<String>(
              label: "Tax Category",
              icon: Icons.account_balance,
              controller: TextEditingController(text: selectedTaxCategory),
              items: taxCategories,
              displayText: (e) => e,
              onSelected: (val) {
                setState(() {
                  selectedTaxCategory = val;
                  selectedTaxTemplate = null;
                });
                _markDirty();
              },
              onClear: () {
                setState(() {
                  selectedTaxCategory = null;
                  selectedTaxTemplate = null;
                });
              },
            ),
          const SizedBox(height: 12),
          if (!issalestaxestemplate)
            buildTypeAheadField<Map<String, dynamic>>(
              label: "Sales Taxes and Charges Template",
              icon: Icons.receipt_long,
              controller: TextEditingController(text: selectedTaxTemplate),
              items:
                  salesTaxTemplates.where((e) {
                    // Filter by selected company and tax category
                    final companyMatches =
                        selectedCompany == null ||
                        e["company"] == selectedCompany;
                    final taxCategoryMatches =
                        selectedTaxCategory == null ||
                        e["tax_category"] == selectedTaxCategory;
                    return companyMatches && taxCategoryMatches;
                  }).toList(),

              displayText: (e) => e["name"],
              onSelected: (val) {
                setState(() {
                  selectedTaxTemplate = val["name"];
                });
              },
            ),
          const SizedBox(height: 12),

          if (!ispricelist)
            buildTypeAheadField<String>(
              label: "Selling Price List",
              icon: Icons.price_check,
              controller: TextEditingController(text: selectedPriceList),
              items: priceLists,
              displayText: (e) => e,
              onSelected: (val) {
                setState(() => selectedPriceList = val);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuotationTypeCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Type of Quotation'),
          const SizedBox(height: 8),

          buildTypeAheadField<String>(
            label: 'Select Type',
            icon: Icons.local_fire_department,
            controller: TextEditingController(text: quotationType),
            items: quotationTypes,
            displayText: (e) => e,
            onSelected: (val) {
              setState(() {
                quotationType = val;
              });
            },
          ),
        ],
      ),
    );
  }

  // Widget _buildVisitCountCard() {
  //   return _buildCard(
  //     child: _buildTextField(
  //       controller: visitCountCtrl,
  //       label: 'Visit Count',
  //       icon: Icons.confirmation_number,
  //       keyboardType: TextInputType.number,
  //     ),
  //   );
  // }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

// ---------------- TOTALS CARD ----------------

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _TotalRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}
