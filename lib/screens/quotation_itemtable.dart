import 'package:flutter/material.dart';
import 'package:harshinifireess/Utils/user_service.dart';

/// ---------------- ITEM MODEL ----------------
class QuotationItem {
  String itemCode;
  String itemName;
  String uom;
  double qty;
  double rate;
  double discountAmount;
  bool hasPriceList;

  QuotationItem({
    required this.itemCode,
    required this.itemName,
    this.uom = 'Nos',
    this.qty = 1,
    this.rate = 0,
    this.discountAmount = 0,
    this.hasPriceList = false,
  });

  double get gross => qty * rate;

  double get amount => gross - discountAmount;

  double get discountPercent => gross > 0 ? (discountAmount / gross) * 100 : 0;
}

/// ---------------- MAIN TABLE ----------------
class QuotationItemTable extends StatefulWidget {
  final List<QuotationItem> items;
  final void Function(List<QuotationItem>, double)? onItemsChanged;
  final bool readOnly;
  const QuotationItemTable({
    super.key,
    required this.items,
    this.onItemsChanged,
    this.readOnly = false,
  });

  @override
  State<QuotationItemTable> createState() => _QuotationItemTableState();
}

class _QuotationItemTableState extends State<QuotationItemTable> {
  final Set<int> selectedRows = {};
  List<Map<String, String>> itemMaster = [];
  bool isLoadingItems = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadMeta() async {
    if (_isDisposed) return;

    setState(() => isLoadingItems = true);

    try {
      final data = await UserService.fetchQuotationMeta();

      if (_isDisposed) return; // 👈 REQUIRED after await

      itemMaster = List<Map<String, String>>.from(
        data["items"].map(
          (e) => {
            "code": e["item_code"].toString(),
            "name": e["item_name"].toString(),
            "uom": e["stock_uom"]?.toString() ?? "Nos",
          },
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      try {
        setState(() => isLoadingItems = false);
      } catch (e) {
        debugPrint('setState error ignored: $e');
      } catch (error) {
        debugPrint('setState error ignored: $error');
      }
    }
  }

  /// ---------------- TOTAL ----------------
  double get total => widget.items.fold(0, (sum, e) => sum + e.amount);

  void _recalculateNetTotal() {
    widget.onItemsChanged?.call(widget.items, total);
    ;
  }

  /// ---------------- DELETE ----------------
  void _deleteSelectedRows() {
    setState(() {
      widget.items.removeWhere(
        (item) => selectedRows.contains(widget.items.indexOf(item)),
      );
      selectedRows.clear();
      _recalculateNetTotal();
    });
  }

  /// ---------------- ADD ITEM ----------------
  void _openAddItemDialog() {
    String search = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search Item',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged:
                          (v) => setDialogState(() => search = v.toLowerCase()),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children:
                            itemMaster
                                .where(
                                  (e) =>
                                      e['name']!.toLowerCase().contains(search),
                                )
                                .map((item) {
                                  return ListTile(
                                    title: Text(item['name']!),
                                    subtitle: Text(item['code']!),
                                    trailing: const Icon(
                                      Icons.add,
                                      color: Colors.orange,
                                    ),
                                    onTap: () async {
                                      Navigator.pop(context);

                                      final rate =
                                          await UserService.fetchItemRate(
                                            item['code']!,
                                          );

                                      if (!mounted) return;

                                      setState(() {
                                        widget.items.add(
                                          QuotationItem(
                                            itemCode: item['code']!,
                                            itemName: item['name']!,
                                            uom: item['uom']!,
                                            rate: rate,
                                            hasPriceList: rate > 0,
                                          ),
                                        );
                                        _recalculateNetTotal();
                                      });
                                    },
                                  );
                                })
                                .toList(),
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

  /// ---------------- EDIT ITEM ----------------
  void _openEditItemDialog(QuotationItem item, int index) {
    final qtyCtrl = TextEditingController(text: item.qty.toString());
    final uomCtrl = TextEditingController(text: item.uom);
    final rateCtrl = TextEditingController(text: item.rate.toString());

    final discountAmtCtrl = TextEditingController(
      text: item.discountAmount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _previewRow('Item', item.itemName),
                _previewRow('Code', item.itemCode),
                const Divider(),

                /// ---- PRICE LIST RADIO ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Price List',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: item.hasPriceList,
                      onChanged: null,
                      activeColor: Colors.orange, // 🟠 ACTIVE CIRCLE
                      activeTrackColor: Colors.orange.shade200,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),

                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                ),
                TextField(
                  controller: uomCtrl,
                  decoration: const InputDecoration(labelText: 'UOM'),
                ),
                TextField(
                  controller: rateCtrl,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Rate (Price List)',
                  ),
                ),
                TextField(
                  controller: discountAmtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Discount Amount (₹)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text) ?? item.qty;
                final discountAmt = double.tryParse(discountAmtCtrl.text) ?? 0;

                final gross = qty * item.rate;

                final double discountPercent =
                    gross == 0
                        ? 0.0
                        : ((discountAmt / gross) * 100.0).clamp(0.0, 100.0);

                setState(() {
                  widget.items[index] = QuotationItem(
                    itemCode: item.itemCode,
                    itemName: item.itemName,
                    qty: qty,
                    uom: uomCtrl.text,
                    rate: item.rate,
                    discountAmount: discountAmt,
                    hasPriceList: item.hasPriceList,
                  );
                  _recalculateNetTotal();
                });

                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        _tableHeader(),

        if (widget.items.isEmpty) _emptyState(),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items.length,
          itemBuilder:
              (context, index) => _tableRow(widget.items[index], index),
        ),

        const SizedBox(height: 10),
        if (!widget.readOnly)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openAddItemDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Row',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: selectedRows.isEmpty ? null : _deleteSelectedRows,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total : ₹ ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// ---------------- HEADER ----------------
  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Row(children: [Expanded(child: Text('Item')), Text('Discount %')]),
          Divider(),
          Row(
            children: [
              Expanded(child: Text('Qty | UOM')),
              Expanded(child: Text('Rate', textAlign: TextAlign.center)),
              Expanded(child: Text('Amount', textAlign: TextAlign.end)),
            ],
          ),
        ],
      ),
    );
  }

  void _openPreviewDialog(QuotationItem item) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Item Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _previewRow('Item', item.itemName),
                _previewRow('Code', item.itemCode),
                _previewRow('Qty', '${item.qty} ${item.uom}'),
                _previewRow('Rate', '₹ ${item.rate}'),
                _previewRow('Discount', '₹ ${item.discountAmount}'),
                const Divider(),
                _previewRow('Amount', '₹ ${item.amount.toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  /// ---------------- ROW ----------------
  Widget _tableRow(QuotationItem item, int index) {
    final isSelected = selectedRows.contains(index);

    return InkWell(
      onTap: () {
        widget.readOnly
            ? _openPreviewDialog(item)
            : _openEditItemDialog(item, index);
      },

      onLongPress: () {
        setState(() {
          isSelected ? selectedRows.remove(index) : selectedRows.add(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (item.discountPercent > 0)
                  Text(
                    '-${item.discountPercent.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('${item.qty} ${item.uom}')),
                Expanded(
                  child: Text('${item.rate}', textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text(
                    '${item.amount.toStringAsFixed(2)}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: const Text(
        'No items added',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
