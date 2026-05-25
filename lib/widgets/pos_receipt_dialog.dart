import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../providers/app_state.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      icon: const Icon(Icons.print, color: Color(0xFF800020)),
                      label: const Text('Print ESC/POS', style: TextStyle(color: Color(0xFF800020))),
                      onPressed: () {
                        final appState = Provider.of<AppState>(context, listen: false);
                        if (!appState.isPrinterConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No printer paired! Go to Settings to pair a simulated thermal printer.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return _SimulatedPrinterDialog(
                              printerName: appState.pairedPrinterName ?? 'Thermal Printer',
                              orderId: orderId,
                              cartItems: cartItems,
                              total: total,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('WhatsApp PDF', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
                      onPressed: () {
                        final String invoiceText = '''
🍰 *CASSIO BAKERS INVOICE* 🍰
------------------------------------
Invoice: $orderId
Customer: ${customerName.isEmpty ? 'Walk-in Customer' : customerName}
Date: $currentDate
------------------------------------
${cartItems.entries.map((e) => '• ${e.value}x ${e.key.name} - ₹${(e.key.price * e.value).toStringAsFixed(0)}').join('\n')}
------------------------------------
Subtotal: ₹${subtotal.toStringAsFixed(0)}
${discount > 0 ? 'Discount: -₹${discount.toStringAsFixed(0)}\n' : ''}GST (5%): ₹${gstAmount.toStringAsFixed(0)}
*GRAND TOTAL: ₹${total.toStringAsFixed(0)}*
------------------------------------
Amount Paid: ₹${paidAmount.toStringAsFixed(0)}
${total - paidAmount > 0 ? '*Balance Due: ₹${(total - paidAmount).toStringAsFixed(0)}*\n' : ''}
Thank you for your order!
Baked with love, served with joy.
------------------------------------
''';
                        showDialog(
                          context: context,
                          builder: (context) {
                            return _WhatsAppBroadcastDialog(
                              phone: customerPhone,
                              invoiceText: invoiceText,
                            );
                          },
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

// ==========================================
// SIMULATED BLUETOOTH THERMAL PRINTER PROGRESS
// ==========================================
class _SimulatedPrinterDialog extends StatefulWidget {
  final String printerName;
  final String orderId;
  final Map<Product, int> cartItems;
  final double total;

  const _SimulatedPrinterDialog({
    required this.printerName,
    required this.orderId,
    required this.cartItems,
    required this.total,
  });

  @override
  State<_SimulatedPrinterDialog> createState() => _SimulatedPrinterDialogState();
}

class _SimulatedPrinterDialogState extends State<_SimulatedPrinterDialog> {
  String _status = 'Establishing secure Bluetooth channel...';
  double _progress = 0.1;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startPrintSimulation();
  }

  void _startPrintSimulation() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _status = 'Transmitting ESC/POS tax headers...';
      _progress = 0.4;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _status = 'Generating rasterized ticket lines...';
      _progress = 0.7;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _status = 'Feeding paper & triggering auto-cutter...';
      _progress = 0.9;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _status = 'Receipt printed successfully!';
      _progress = 1.0;
      _finished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.bluetooth_audio, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.printerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            color: Colors.green,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Job: ${widget.orderId}\nTotal: ₹${widget.total.toStringAsFixed(0)}\nLines: ${widget.cartItems.length} items',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black54),
            ),
          )
        ],
      ),
      actions: [
        if (_finished)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
      ],
    );
  }
}

// ==========================================
// SIMULATED WHATSAPP SHARE BROADCAST HUB
// ==========================================
class _WhatsAppBroadcastDialog extends StatelessWidget {
  final String phone;
  final String invoiceText;

  const _WhatsAppBroadcastDialog({
    required this.phone,
    required this.invoiceText,
  });

  @override
  Widget build(BuildContext context) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fallbackPhone = cleanPhone.isNotEmpty ? cleanPhone : '9876543210';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(Icons.share, color: Colors.green),
                  SizedBox(width: 8),
                  Text('WhatsApp Sharing Broadcast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Pre-formatted WhatsApp PDF invoice summary text generated successfully!',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text('WHATSAPP INVOICE TEXT PREVIEW:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    invoiceText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Recipient Number: +91 $fallbackPhone',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tapping share simulates standard Android intent triggers, broadcasting PDF invoices and pre-filled web deep links directly to clients.',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Simulating Android intent broadcast to +91 $fallbackPhone... PDF invoice sent!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.outgoing_mail, color: Colors.white, size: 16),
                    label: const Text('Share Receipt', style: TextStyle(color: Colors.white)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
