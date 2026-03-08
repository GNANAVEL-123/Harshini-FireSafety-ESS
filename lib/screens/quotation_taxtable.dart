import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';
import 'package:harshinifireess/screens/quotation_creation.dart'; // for DiscountOn enum

/// ---------------- MODEL ----------------
class SalesTax {
  String chargeType;
  String accountHead;
  double rate;
  double taxAmount;

  SalesTax({
    required this.chargeType,
    required this.accountHead,
    required this.rate,
    this.taxAmount = 0,
  });
}

/// ---------------- WIDGET ----------------
class SalesTaxesTable extends StatefulWidget {
  final double netTotal;
  final String? selectedTemplateName; // 🔥 Added
  final ValueChanged<double>? onGrandTotalChanged;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final DiscountOn discountOn;
  final double invoiceDiscount;
  final bool readOnly;

  const SalesTaxesTable({
    super.key,
    required this.netTotal,
    this.selectedTemplateName,
    this.onGrandTotalChanged, // ✅
    this.scaffoldMessengerKey, // ✅ add here
    required this.discountOn,
    required this.invoiceDiscount,
    this.readOnly = false,
  });

  @override
  State<SalesTaxesTable> createState() => _SalesTaxesTableState();
}

class _SalesTaxesTableState extends State<SalesTaxesTable>
    with AutomaticKeepAliveClientMixin {
  final List<SalesTax> taxes = [];
  final Set<int> selectedRows = {};

  @override
  bool get wantKeepAlive => true;

  double get totalTax => taxes.fold(0, (sum, e) => sum + e.taxAmount);

  // When discountOn == netTotal, widget.netTotal is already (original - discount)
  // When discountOn == grandTotal, widget.netTotal is original value
  double get grandTotal =>
      widget.discountOn == DiscountOn.grandTotal
          ? widget.netTotal + totalTax - widget.invoiceDiscount
          : widget.netTotal + totalTax;

  /// ---------------- AUTO RECALCULATE ----------------
  @override
  void didUpdateWidget(covariant SalesTaxesTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 Recalculate tax amount when net total changes
    if (oldWidget.netTotal != widget.netTotal) {
      setState(() {
        for (var tax in taxes) {
          tax.taxAmount = widget.netTotal * tax.rate / 100;
        }
        _notifyGrandTotal(); // ✅
      });
    }

    // 🔥 Reload taxes ONLY when template changes
    if (oldWidget.selectedTemplateName != widget.selectedTemplateName &&
        widget.selectedTemplateName != null) {
      _loadTaxesFromTemplate();
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.selectedTemplateName != null &&
        widget.selectedTemplateName!.isNotEmpty) {
      _loadTaxesFromTemplate();
    }
  }

  void _notifyGrandTotal() {
    if (widget.onGrandTotalChanged != null) {
      // Schedule after build to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onGrandTotalChanged!(grandTotal);
      });
    }
  }

  Future<void> _loadTaxesFromTemplate() async {
    final rows = await UserService.fetchTaxTemplateDetails(
      widget.selectedTemplateName!,
    );

    setState(() {
      taxes
        ..clear()
        ..addAll(
          rows.map(
            (row) => SalesTax(
              chargeType: row["charge_type"],
              accountHead: row["account_head"],
              rate: (row["rate"] as num).toDouble(),
              taxAmount:
                  widget.netTotal * (row["rate"] as num).toDouble() / 100,
            ),
          ),
        );
    });
    _notifyGrandTotal(); // ✅
  }

  /// ---------------- ADD TAX (FROM META) ----------------
  void _addTax() async {
    if (widget.selectedTemplateName == null ||
        widget.selectedTemplateName!.isEmpty) {
      widget.scaffoldMessengerKey?.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please select a Tax Template first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final rows = await UserService.fetchTaxTemplateDetails(
        widget.selectedTemplateName!,
      );

      if (!mounted) return;

      setState(() {
        taxes.clear();
        selectedRows.clear();

        for (final row in rows) {
          taxes.add(
            SalesTax(
              chargeType: row["charge_type"],
              accountHead: row["account_head"],
              rate: (row["rate"] as num).toDouble(),
              taxAmount:
                  widget.netTotal * (row["rate"] as num).toDouble() / 100,
            ),
          );
        }
      });

      if (mounted) _notifyGrandTotal();
    } catch (e) {
      widget.scaffoldMessengerKey?.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to load tax rows: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ---------------- DELETE ----------------
  void _deleteSelected() {
    setState(() {
      taxes.removeWhere((e) => selectedRows.contains(taxes.indexOf(e)));
      selectedRows.clear();
    });
    _notifyGrandTotal(); // ✅
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Taxes and Charges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        _tableHeader(),

        if (taxes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              'No taxes added',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: taxes.length,
          itemBuilder: (context, index) {
            return _tableRow(taxes[index], index);
          },
        ),

        const SizedBox(height: 10),
        if (!widget.readOnly)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addTax,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Row',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: selectedRows.isEmpty ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),

        const SizedBox(height: 12),
        if (!widget.readOnly) ...[
          // When discount on Net Total, netTotal passed is already adjusted
          if (widget.discountOn == DiscountOn.netTotal) ...[
            _summaryRow(
              "Net Total Before Discount",
              widget.netTotal + widget.invoiceDiscount,
            ),
            _summaryRow("Discount Amount", widget.invoiceDiscount),
            _summaryRow("Net Total After Discount", widget.netTotal),
          ] else ...[
            _summaryRow("Net Total Before Discount", widget.netTotal),
            _summaryRow("Discount Amount", widget.invoiceDiscount),
            _summaryRow(
              "Net Total After Discount",
              widget.netTotal - widget.invoiceDiscount,
            ),
          ],
          _summaryRow('Total Tax', totalTax),
          _summaryRow('Grand Total', grandTotal, bold: true),
        ],
      ],
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 - Account Head
          const Text(
            'Account Head',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          // Row 2 - Charge Type | Rate | Amount
          Row(
            children: const [
              Expanded(flex: 3, child: Text('Charge Type')),
              Expanded(child: Text('Rate', textAlign: TextAlign.center)),
              Expanded(child: Text('Amount', textAlign: TextAlign.end)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableRow(SalesTax tax, int index) {
    final isSelected = selectedRows.contains(index);

    return InkWell(
      onLongPress:
          widget.readOnly
              ? null
              : () {
                setState(() {
                  isSelected
                      ? selectedRows.remove(index)
                      : selectedRows.add(index);
                });
              },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 - Account Head
            Text(
              tax.accountHead,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            // Row 2 - Charge Type | Rate | Amount
            Row(
              children: [
                Expanded(flex: 3, child: Text(tax.chargeType)),
                Expanded(
                  child: Text('${tax.rate}%', textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text(
                    '₹${tax.taxAmount.toStringAsFixed(2)}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- SUMMARY ----------------
  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '₹ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
