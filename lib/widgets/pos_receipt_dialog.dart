import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/product.dart';

class PosReceiptDialog extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final Map<Product, int> cartItems;
  final double subtotal;
  final double discount;
  final double gstAmount;
  final double total;
  final double paidAmount;

  const PosReceiptDialog({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.cartItems,
    required this.subtotal,
    required this.discount,
    required this.gstAmount,
    required this.total,
    required this.paidAmount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final String currentDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt Header
              const Text(
                'CASSIO BAKERS',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
              ),
              const Text(
                '12, Bakery Lane, MG Road, Bangalore\nPh: +91 98765 43210',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Divider(thickness: 1, height: 1),
              const SizedBox(height: 12),

              // Transaction Meta Details
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text('Invoice: $orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(currentDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Customer: ${customerName.isEmpty ? 'Walk-in Customer' : customerName}', style: const TextStyle(fontSize: 13)),
              if (customerPhone.isNotEmpty) Text('Phone: $customerPhone', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              const Divider(thickness: 1, height: 1),
              const SizedBox(height: 12),

              // Invoice Table Headers
              Row(
                children: const [
                  Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
              const SizedBox(height: 8),

              // Invoice items list
              ...cartItems.entries.map((entry) {
                final p = entry.key;
                final qty = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(p.name, style: const TextStyle(fontSize: 13))),
                      Expanded(child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                      Expanded(child: Text(currencyFormat.format(p.price).replaceAll('₹', ''), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                      Expanded(child: Text(currencyFormat.format(p.price * qty).replaceAll('₹', ''), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              const Divider(thickness: 1, height: 1),
              const SizedBox(height: 12),

              // Receipt Calculation Summary
              _buildReceiptRow('Subtotal', currencyFormat.format(subtotal)),
              if (discount > 0) _buildReceiptRow('Discount', '- ' + currencyFormat.format(discount), valueColor: Colors.red),
              _buildReceiptRow('GST (5%)', currencyFormat.format(gstAmount)),
              const SizedBox(height: 4),
              _buildReceiptRow('Grand Total', currencyFormat.format(total), isBold: true, fontSize: 16),
              const Divider(height: 20),
              _buildReceiptRow('Amount Paid', currencyFormat.format(paidAmount), isBold: true, valueColor: AppColors.ready),
              if (total - paidAmount > 0)
                _buildReceiptRow('Balance Due', currencyFormat.format(total - paidAmount), isBold: true, valueColor: AppColors.outOfStock),
              const SizedBox(height: 24),

              // Receipt Footer Greetings
              const Text(
                'Thank you for your business!\nBaked with love, served with joy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.primaryMaroon),
              ),
              const SizedBox(height: 24),

              // POS Invoice Action Triggers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connecting to thermal receipt printer...'), backgroundColor: AppColors.ready),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generating PDF invoice receipt...'), backgroundColor: AppColors.ready),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done', style: TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String val, {bool isBold = false, double fontSize = 13, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: valueColor ?? (isBold ? AppColors.primaryMaroon : AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
