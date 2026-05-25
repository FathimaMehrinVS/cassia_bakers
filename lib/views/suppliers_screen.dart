import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/supplier.dart';
import '../models/supplier_transaction.dart';
import 'package:intl/intl.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  Supplier? _selectedSupplier;
  String _searchQuery = '';
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final suppliers = appState.suppliers.where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.phone.contains(_searchQuery);
    }).toList();

    // Auto-select first supplier if none selected
    if (_selectedSupplier == null && suppliers.isNotEmpty) {
      _selectedSupplier = suppliers.first;
    } else if (_selectedSupplier != null) {
      // Keep selected supplier updated with latest state values
      final latest = appState.suppliers.firstWhere(
        (s) => s.id == _selectedSupplier!.id,
        orElse: () => _selectedSupplier!,
      );
      _selectedSupplier = latest;
    }

    // Calculations
    double totalDues = 0.0;
    double totalSettled = 0.0;
    for (var s in appState.suppliers) {
      totalDues += s.pendingDues;
      totalSettled += s.paidAmount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6), // Warm background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 800;
            if (isTablet) {
              return Row(
                children: [
                  // Left Supplier List Sidebar
                  SizedBox(
                    width: 320,
                    child: _buildSupplierListSidebar(context, suppliers, totalDues, totalSettled),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEADBC8)),
                  // Right Detailed Timeline Ledger View
                  Expanded(
                    child: _selectedSupplier == null
                        ? const Center(
                            child: Text(
                              'Select a supplier to view ledger history',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : _buildLedgerTimelineView(context, appState),
                  ),
                ],
              );
            } else {
              // Mobile view: list or detail sheet depending on selection
              return _selectedSupplier == null || _selectedSupplier?.id == null
                  ? _buildSupplierListSidebar(context, suppliers, totalDues, totalSettled)
                  : WillPopScope(
                      onWillPop: () async {
                        setState(() {
                          _selectedSupplier = null;
                        });
                        return false;
                      },
                      child: Scaffold(
                        appBar: AppBar(
                          backgroundColor: const Color(0xFF800020),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                            onPressed: () {
                              setState(() {
                                _selectedSupplier = null;
                              });
                            },
                          ),
                          title: Text(
                            _selectedSupplier!.name,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        body: _buildLedgerTimelineView(context, appState),
                      ),
                    );
            }
          },
        ),
      ),
      floatingActionButton: _selectedSupplier == null && MediaQuery.of(context).size.width <= 800
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF800020),
              onPressed: () => _showAddSupplierDialog(context, appState),
              child: const Icon(Icons.person_add, color: Color(0xFFD4AF37)),
            )
          : null,
    );
  }

  // ==========================================
  // SIDEBAR LIST VIEW
  // ==========================================
  Widget _buildSupplierListSidebar(
    BuildContext context,
    List<Supplier> suppliers,
    double totalDues,
    double totalSettled,
  ) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Sidebar header & metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF800020), // Maroon accent
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Supplier Ledger',
                      style: TextStyle(
                        color: Color(0xFFD4AF37), // Gold accent
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (MediaQuery.of(context).size.width > 800)
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Color(0xFFD4AF37)),
                        onPressed: () => _showAddSupplierDialog(context, appState),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PENDING DUEDUBT',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(totalDues),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL SETTLED',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(totalSettled),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search suppliers...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: const Color(0xFFF5F5F5),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Active List of supplier profile ledger sheets
          Expanded(
            child: suppliers.isEmpty
                ? const Center(
                    child: Text('No suppliers found', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    itemCount: suppliers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3EFE9)),
                    itemBuilder: (context, index) {
                      final s = suppliers[index];
                      final isSel = _selectedSupplier?.id == s.id;
                      return ListTile(
                        selected: isSel,
                        selectedTileColor: const Color(0xFFFFFDF9),
                        onTap: () => setState(() => _selectedSupplier = s),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEADBC8),
                          child: Text(
                            s.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Color(0xFF800020), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSel ? const Color(0xFF800020) : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          s.phone,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(s.pendingDues),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: s.pendingDues > 0 ? Colors.red.shade700 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'pending dues',
                              style: TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT TIMELINE VIEW & LEDGER LOGS
  // ==========================================
  Widget _buildLedgerTimelineView(BuildContext context, AppState appState) {
    final s = _selectedSupplier!;
    final timelineTx = appState.transactions.where((t) => t.supplierId == s.id).toList();

    return Column(
      children: [
        // Supplier Header Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800020)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(s.phone, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        if (s.email != null && s.email!.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.email, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.email!,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]
                      ],
                    ),
                    if (s.notes != null && s.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Note: ${s.notes}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(s.pendingDues),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: s.pendingDues > 0 ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  const Text('Outstanding Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEADBC8)),
        // Action Buttons Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showLogPurchaseWizard(context, appState, s),
                  icon: const Icon(Icons.shopping_bag, size: 16, color: Colors.white),
                  label: const Text('Log Stock Purchase', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSettleDuesWizard(context, appState, s),
                  icon: const Icon(Icons.payment, size: 16, color: Color(0xFF800020)),
                  label: const Text('Record Settlement', style: TextStyle(color: Color(0xFF800020))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF800020)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEADBC8)),
        // Transaction timeline history
        Expanded(
          child: timelineTx.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No transaction entries logged yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: timelineTx.length,
                  itemBuilder: (context, index) {
                    final t = timelineTx[index];
                    final isPurchase = t.totalAmount > 0;
                    return Card(
                      color: Colors.white,
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isPurchase ? Colors.red.shade100 : Colors.green.shade100,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isPurchase ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isPurchase ? Colors.red : Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isPurchase ? 'Wholesale Purchase' : 'Payment Settlement',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPurchase ? Colors.red.shade900 : Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  t.transactionDate,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (isPurchase) ...[
                              Text(
                                'Items: ${t.productsPurchased}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Qty: ${t.quantity}   |   Cost: ${_currencyFormat.format(t.costPrice)}/unit',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPurchase
                                          ? 'Total: ${_currencyFormat.format(t.totalAmount)}'
                                          : 'Amount Paid: ${_currencyFormat.format(t.paidAmount)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    if (isPurchase) ...[
                                      Text(
                                        'Paid: ${_currencyFormat.format(t.paidAmount)}   |   Dues Added: ${_currencyFormat.format(t.dueAmount)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ]
                                  ],
                                ),
                                // Render attachment triggers if local path reference exists
                                if (t.attachmentPath != null && t.attachmentPath!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _openBillInvoiceLightbox(context, t.attachmentPath!),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E7),
                                        border: Border.all(color: const Color(0xFFD4AF37)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.receipt_long, size: 12, color: Color(0xFF800020)),
                                          const SizedBox(width: 4),
                                          Text(
                                            t.attachmentPath!.split('/').last,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF800020),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                              ],
                            ),
                            if (t.notes != null && t.notes!.isNotEmpty) ...[
                              const Divider(height: 12, color: Color(0xFFF3EFE9)),
                              Text(
                                'Remarks: ${t.notes}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // DIALOGS & SHEET WIZARDS
  // ==========================================
  void _showAddSupplierDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Add Wholesale Supplier', style: TextStyle(color: Color(0xFF800020), fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Supplier/Business Name *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter business name' : null,
                  ),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Phone Number *'),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                  ),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'General Notes (e.g. Flour dealer)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newSup = Supplier(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  );
                  await appState.addSupplier(newSup);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Supplier profile added successfully')),
                  );
                }
              },
              child: const Text('Add Profile', style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  void _showLogPurchaseWizard(BuildContext context, AppState appState, Supplier s) {
    final prodCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final paidCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    
    String? attachmentRef;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log Raw Bulk Stock Purchase',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800020)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: prodCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Products Purchased (e.g. Maida Flour 50Kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please specify item purchased' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyCtrl,
                              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || int.tryParse(val) == null ? 'Enter quantity' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: costCtrl,
                              decoration: const InputDecoration(labelText: 'Unit Cost Price (₹)', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Enter cost price' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: paidCtrl,
                              decoration: const InputDecoration(labelText: 'Amount Paid Now (₹)', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Enter amount paid' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: dateCtrl,
                              decoration: const InputDecoration(labelText: 'Purchase Date', border: OutlineInputBorder()),
                              keyboardType: TextInputType.datetime,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter date' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Attachment Selector
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Photo Invoice/Bill Attachment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(
                                  attachmentRef == null ? 'No invoice attached' : attachmentRef!.split('/').last,
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // Simulate native attachment picker dialogue
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return SimpleDialog(
                                      title: const Text('Attach Wholesale Bill Receipt'),
                                      children: [
                                        SimpleDialogOption(
                                          onPressed: () {
                                            setModalState(() {
                                              attachmentRef = 'assets/logo/logo.jpeg';
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(Icons.camera_alt, color: Color(0xFF800020)),
                                              SizedBox(width: 8),
                                              Text('Capture Photo Bill (Mock Lens)'),
                                            ],
                                          ),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () {
                                            setModalState(() {
                                              attachmentRef = 'assets/logo/logo.jpeg';
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(Icons.photo_library, color: Color(0xFF800020)),
                                              SizedBox(width: 8),
                                              Text('Choose From Gallery (Mock file)'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.attach_file, size: 16, color: Color(0xFF800020)),
                              label: const Text('Select File', style: TextStyle(color: Color(0xFF800020))),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(labelText: 'Remarks / Ledger Notes', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF800020),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final qty = int.parse(qtyCtrl.text);
                                final cost = double.parse(costCtrl.text);
                                final paid = double.parse(paidCtrl.text);
                                final total = qty * cost;
                                final due = total - paid;

                                final t = SupplierTransaction(
                                  supplierId: s.id!,
                                  productsPurchased: prodCtrl.text.trim(),
                                  quantity: qty,
                                  costPrice: cost,
                                  totalAmount: total,
                                  paidAmount: paid,
                                  dueAmount: due,
                                  transactionDate: dateCtrl.text.trim(),
                                  attachmentPath: attachmentRef,
                                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                                );

                                await appState.addSupplierTransaction(t);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Wholesale purchase logged into supplier ledger')),
                                );
                              }
                            },
                            child: const Text('Save Entry', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettleDuesWizard(BuildContext context, AppState appState, Supplier s) {
    final paidCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Settle Balance: ${s.name}', style: const TextStyle(color: Color(0xFF800020), fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Outstanding Debt: ${_currencyFormat.format(s.pendingDues)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: paidCtrl,
                  decoration: const InputDecoration(labelText: 'Cash Paid (₹)', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || double.tryParse(val) == null) {
                      return 'Enter paid amount';
                    }
                    if (double.parse(val) <= 0) {
                      return 'Amount must be positive';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Payment Date', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter date' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Transaction Note (e.g. UPI, Cash ref)', border: OutlineInputBorder()),
                  maxLines: 2,
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(paidCtrl.text);
                  await appState.settleSupplierDues(
                    s,
                    amount,
                    dateCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment ledger settlement saved successfully')),
                  );
                }
              },
              child: const Text('Save Settlement', style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  // ==========================================
  // VIEW BILL ATTACHMENT LIGHTBOX
  // ==========================================
  void _openBillInvoiceLightbox(BuildContext context, String assetPath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.black87,
                elevation: 0,
                title: const Text('Attached Wholesale Bill Detail', style: TextStyle(color: Colors.white, fontSize: 16)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Container(
                color: Colors.white,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.asset(
                    assetPath, // Renders assets/logo/logo.jpeg locally
                    fit: BoxFit.contain,
                    height: MediaQuery.of(context).size.height * 0.65,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('Error loading photo bill details'),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  'Physical Bill verified under local SQLite references',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
