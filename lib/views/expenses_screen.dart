import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../models/expense.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  void _showAddExpenseDialog(BuildContext context, AppState state) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Rent';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Log Operational Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Expense Category'),
                  items: ['Rent', 'Electricity', 'Salary', 'Transport', 'Other']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Expense Description', prefixIcon: Icon(Icons.description_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text('Expense Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
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
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  state.addExpense(
                    Expense(
                      title: titleController.text,
                      amount: double.parse(amountController.text),
                      category: category,
                      date: DateFormat('yyyy-MM-dd').format(selectedDate),
                    ),
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Expense logged: ${titleController.text}!'),
                      backgroundColor: AppColors.ready,
                    ),
                  );
                }
              },
              child: const Text('Log Expense'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card, size: 28),
            onPressed: () => _showAddExpenseDialog(context, state),
            tooltip: 'Record Expense',
          ),
        ],
      ),
      body: state.expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.payment_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No expenses recorded yet.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.expenses.length,
              itemBuilder: (context, index) {
                final e = state.expenses[index];

                // Category-specific visual styles
                IconData icon = Icons.payments;
                Color color = Colors.grey;

                if (e.category == 'Rent') {
                  icon = Icons.home;
                  color = Colors.purple[600]!;
                } else if (e.category == 'Electricity') {
                  icon = Icons.bolt;
                  color = Colors.amber[700]!;
                } else if (e.category == 'Salary') {
                  icon = Icons.people;
                  color = Colors.blue[600]!;
                } else if (e.category == 'Transport') {
                  icon = Icons.local_shipping;
                  color = Colors.green[600]!;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(e.date))),
                    trailing: Text(
                      currency.format(e.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMaroon),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
