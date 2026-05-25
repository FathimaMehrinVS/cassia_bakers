import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'All'; // All, Pending, Preparing, Ready, Delivered

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrderDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final detailsController = TextEditingController();
    final totalController = TextEditingController();
    final advanceController = TextEditingController();
    final instructionsController = TextEditingController();
    
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    TimeOfDay selectedTime = const TimeOfDay(hour: 17, minute: 0); // 05:00 PM

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Book Custom Cake Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Customer Phone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: detailsController, decoration: const InputDecoration(labelText: 'Cake Specifications (e.g. 2 Kg Velvet)', prefixIcon: Icon(Icons.cake_outlined))),
                const SizedBox(height: 12),
                TextField(controller: totalController, decoration: const InputDecoration(labelText: 'Total Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: advanceController, decoration: const InputDecoration(labelText: 'Advance Received (₹)', prefixIcon: Icon(Icons.payments_outlined)), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: instructionsController, decoration: const InputDecoration(labelText: 'Special Instructions', prefixIcon: Icon(Icons.edit_note_outlined))),
                const SizedBox(height: 16),

                // Delivery Date Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text('Delivery Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Delivery Time Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text('Delivery Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                      child: Text(selectedTime.format(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty && detailsController.text.isNotEmpty) {
                  final String ordId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                  state.addOrder(
                    CakeOrder(
                      id: ordId,
                      customerName: nameController.text,
                      customerPhone: phoneController.text,
                      cakeDetails: detailsController.text,
                      deliveryDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                      deliveryTime: selectedTime.format(context),
                      totalAmount: double.parse(totalController.text),
                      advanceAmount: double.parse(advanceController.text),
                      status: 'Pending',
                      specialInstructions: instructionsController.text,
                      createdAt: DateTime.now().toString(),
                    ),
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order booked: $ordId successfully!'), backgroundColor: AppColors.ready),
                  );
                }
              },
              child: const Text('Book Order'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Apply filtering options
    final List<CakeOrder> displayedOrders = state.orders.where((o) {
      final matchesSearch = o.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          o.customerPhone.contains(_searchController.text) ||
          o.cakeDetails.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesStatus = _selectedStatusFilter == 'All' || o.status == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cake Orders queue', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _showAddOrderDialog(context, state),
            tooltip: 'Book Custom Cake',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search field
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search orders by name or phone...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryMaroon),
              ),
            ),
          ),

          // 2. Status Chips filter (Pending, Preparing, Ready, Delivered)
          _buildStatusFilterRow(),
          const SizedBox(height: 12),

          // 3. Orders List matching screenshot exactly
          Expanded(
            child: displayedOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cake_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No cake orders match selection.'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      final o = displayedOrders[index];

                      // Status styles
                      Color statusColor = AppColors.pending;
                      if (o.status == 'Preparing') statusColor = AppColors.preparing;
                      if (o.status == 'Ready') statusColor = AppColors.ready;
                      if (o.status == 'Delivered') statusColor = AppColors.primaryMaroon;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cake Illustration Circle
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMaroon.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cake, color: AppColors.primaryMaroon, size: 28),
                              ),
                              const SizedBox(width: 14),

                              // Order Card Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.between,
                                      children: [
                                        Text(o.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        // Interactive Status Pill
                                        InkWell(
                                          onTap: () => _showStatusToggleDialog(context, state, o),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: statusColor.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  o.status,
                                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(Icons.edit, size: 10, color: statusColor),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('${o.customerName} | ${o.customerPhone}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('dd MMM yyyy').format(DateTime.parse(o.deliveryDate))}, ${o.deliveryTime}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      o.cakeDetails,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.warmBrown, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.between,
                                      children: [
                                        Text(
                                          'Advance: ${currency.format(o.advanceAmount)} / ${currency.format(o.totalAmount)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        if (o.pendingAmount > 0)
                                          Text(
                                            'Due: ${currency.format(o.pendingAmount)}',
                                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                          )
                                        else
                                          const Text('Fully Paid', style: TextStyle(color: AppColors.ready, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    if (o.specialInstructions != null && o.specialInstructions!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        width: double.infinity,
                                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                        child: Text(
                                          'Note: ${o.specialInstructions}',
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.brown),
                                        ),
                                      )
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    final filters = ['All', 'Pending', 'Preparing', 'Ready', 'Delivered'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final bool isSelected = _selectedStatusFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(f, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedStatusFilter = f),
            ),
          );
        },
      ),
    );
  }

  void _showStatusToggleDialog(BuildContext context, AppState state, CakeOrder o) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Preparing', 'Ready', 'Delivered'].map((status) {
            return ListTile(
              title: Text(status),
              leading: Icon(
                Icons.circle,
                color: status == 'Pending'
                    ? AppColors.pending
                    : status == 'Preparing'
                        ? AppColors.preparing
                        : status == 'Ready'
                            ? AppColors.ready
                            : AppColors.primaryMaroon,
              ),
              onTap: () {
                state.updateOrderStatus(o.id, status);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
