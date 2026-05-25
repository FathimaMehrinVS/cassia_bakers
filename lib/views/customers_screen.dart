import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../models/customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRepayDialog(BuildContext context, AppState state, Customer c) {
    final paymentController = TextEditingController(text: c.pendingDues.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle Outstanding Dues — ${c.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Outstanding Dues: ₹ ${c.pendingDues.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: paymentController,
              decoration: const InputDecoration(labelText: 'Amount Paid (₹)', prefixIcon: Icon(Icons.currency_rupee)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final double payment = double.tryParse(paymentController.text) ?? 0.0;
              state.settleCustomerDues(c, payment);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment of ₹$payment recorded! Updated outstanding dues.'),
                  backgroundColor: AppColors.ready,
                ),
              );
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Customer Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Customer Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                state.addCustomer(
                  Customer(name: nameController.text, phone: phoneController.text),
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Customer profile created for ${nameController.text}!'),
                    backgroundColor: AppColors.ready,
                  ),
                );
              }
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final displayedCustomers = state.filteredCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt, size: 28),
            onPressed: () => _showAddCustomerDialog(context, state),
            tooltip: 'Add Customer',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => state.setCustomerSearch(val),
              decoration: InputDecoration(
                hintText: 'Search customer name or phone...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryMaroon),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          state.setCustomerSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Customers List
          Expanded(
            child: displayedCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No customers matched details.'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: displayedCustomers.length,
                    itemBuilder: (context, index) {
                      final c = displayedCustomers[index];

                      // Initials helper
                      final initials = c.name.isNotEmpty
                          ? c.name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
                          : 'C';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryMaroon.withOpacity(0.08),
                            child: Text(
                              initials,
                              style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.phone),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Loyalty Points: ${c.loyaltyPoints}',
                                  style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                c.pendingDues > 0 ? 'Due: ${currency.format(c.pendingDues)}' : 'Due: ₹0',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: c.pendingDues > 0 ? Colors.red : AppColors.ready,
                                  fontSize: 14,
                                ),
                              ),
                              if (c.pendingDues > 0)
                                const Text('Tap to settle', style: TextStyle(fontSize: 10, color: Colors.grey))
                            ],
                          ),
                          onTap: c.pendingDues > 0 ? () => _showRepayDialog(context, state, c) : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
