import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
                'CASSIA BAKERS',
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
              _buildReceiptRow('GST (0%)', currencyFormat.format(0.0)),
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
🍰 *CASSIA BAKERS INVOICE* 🍰
------------------------------------
Invoice: $orderId
Customer: ${customerName.isEmpty ? 'Walk-in Customer' : customerName}
Date: $currentDate
------------------------------------
${cartItems.entries.map((e) => '• ${e.value}x ${e.key.name} - ₹${(e.key.price * e.value).toStringAsFixed(0)}').join('\n')}
------------------------------------
Subtotal: ₹${subtotal.toStringAsFixed(0)}
${discount > 0 ? 'Discount: -₹${discount.toStringAsFixed(0)}\n' : ''}GST (0%): ₹0
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
                              orderId: orderId,
                              customerName: customerName,
                              phone: customerPhone,
                              cartItems: cartItems,
                              subtotal: subtotal,
                              discount: discount,
                              gstAmount: gstAmount,
                              total: total,
                              paidAmount: paidAmount,
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
  final String orderId;
  final String customerName;
  final String phone;
  final Map<Product, int> cartItems;
  final double subtotal;
  final double discount;
  final double gstAmount;
  final double total;
  final double paidAmount;
  final String invoiceText;

  const _WhatsAppBroadcastDialog({
    required this.orderId,
    required this.customerName,
    required this.phone,
    required this.cartItems,
    required this.subtotal,
    required this.discount,
    required this.gstAmount,
    required this.total,
    required this.paidAmount,
    required this.invoiceText,
  });

  Future<void> _sharePDFDirectToWhatsApp(BuildContext context) async {
    final pdf = pw.Document();

    // 1. Load the brand logo image from assets
    pw.MemoryImage? logoImage;
    try {
      final imageBytes = await rootBundle.load('assets/logo/logo.jpeg');
      logoImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
    } catch (e) {
      // Logo fallback is fine
    }

    // 2. Build the PDF layout page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Logo
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 70, height: 70),
                ),
              pw.SizedBox(height: 10),

              // Title
              pw.Text(
                'CASSIA BAKERS',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#6B1C2A'),
                ),
              ),
              pw.SizedBox(height: 4),

              // Subtitle info
              pw.Text(
                '12, Bakery Lane, MG Road, Bangalore\nPh: +91 98765 43210\nEmail: orders@cassiabakers.com',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Meta Details Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE TO:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        customerName.isEmpty ? 'Walk-in Customer' : customerName,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      if (phone.isNotEmpty)
                        pw.Text(
                          'Ph: +91 $phone',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE NO: $orderId',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'DATE: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table header
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6B1C2A'),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text('Item Description', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Price (Rs.)', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Total (Rs.)', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
              ),

              // Table lines
              ...cartItems.entries.map((entry) {
                final p = entry.key;
                final qty = entry.value;
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(p.name, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('${p.price.toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text('$qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('${(p.price * qty).toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              pw.SizedBox(height: 16),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Subtotal:  ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('${subtotal.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      if (discount > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text('Discount:  ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('-${discount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('GST (0%):  ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('0', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Divider(thickness: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('GRAND TOTAL:  ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6B1C2A'))),
                          pw.Text('${total.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6B1C2A'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Amount Paid:  ', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          pw.Text('${paidAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        ],
                      ),
                      if (total - paidAmount > 0) ...[
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            pw.Text('Balance Due:  ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                            pw.Text('${(total - paidAmount).toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer notes
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text(
                'Thank you for choosing Cassia Bakers!',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6B1C2A')),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Baked with love, served with joy.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to a temporary physical file
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Cassia_Bakers_Invoice_$orderId.pdf");
    await file.writeAsBytes(await pdf.save());

    // Format the phone number (E.164 format without '+')
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = cleanPhone.startsWith('91') && cleanPhone.length == 12
        ? cleanPhone
        : cleanPhone.length == 10
            ? '91$cleanPhone'
            : cleanPhone.isNotEmpty ? cleanPhone : '919876543210';

    try {
      const platform = MethodChannel('com.cassiabakers.app/whatsapp');
      final bool? success = await platform.invokeMethod<bool>('shareToWhatsApp', {
        'phone': formattedPhone,
        'filePath': file.path,
        'message': 'Thank you for shopping with CASSIA BAKERS. Please find your invoice attached.',
      });
      if (success != true) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Thank you for shopping with CASSIA BAKERS. Please find your invoice attached.',
        );
      }
    } catch (e) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Thank you for shopping with CASSIA BAKERS. Please find your invoice attached.',
      );
    }
  }

  Future<void> _sharePDFGeneral(BuildContext context) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final imageBytes = await rootBundle.load('assets/logo/logo.jpeg');
      logoImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
    } catch (e) {
      // Fallback
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 70, height: 70),
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'CASSIA BAKERS',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#6B1C2A'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '12, Bakery Lane, MG Road, Bangalore\nPh: +91 98765 43210\nEmail: orders@cassiabakers.com',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE TO:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        customerName.isEmpty ? 'Walk-in Customer' : customerName,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      if (phone.isNotEmpty)
                        pw.Text(
                          'Ph: +91 $phone',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE NO: $orderId',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'DATE: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6B1C2A'),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text('Item Description', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Price (Rs.)', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Total (Rs.)', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
              ),
              ...cartItems.entries.map((entry) {
                final p = entry.key;
                final qty = entry.value;
                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(p.name, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('${p.price.toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text('$qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('${(p.price * qty).toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Subtotal:  ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('${subtotal.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      if (discount > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text('Discount:  ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('-${discount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('GST (0%):  ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('0', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Divider(thickness: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('GRAND TOTAL:  ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6B1C2A'))),
                          pw.Text('${total.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6B1C2A'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Amount Paid:  ', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          pw.Text('${paidAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        ],
                      ),
                      if (total - paidAmount > 0) ...[
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            pw.Text('Balance Due:  ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                            pw.Text('${(total - paidAmount).toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text(
                'Thank you for choosing Cassia Bakers!',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6B1C2A')),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Baked with love, served with joy.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Cassia_Bakers_Invoice_$orderId.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Thank you for shopping with CASSIA BAKERS. Please find your invoice attached.',
    );
  }

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
                  Text('Direct WhatsApp Sharing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Generated invoice PDF has been temporarily stored in cache. Ready to share directly to the customer\'s WhatsApp thread.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text('WHATSAPP PRE-FILLED MESSAGE:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  '“Thank you for shopping with CASSIA BAKERS. Please find your invoice attached.”',
                  style: TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Target Customer Number: +91 $fallbackPhone',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tapping "Share WhatsApp" opens WhatsApp directly into the customer\'s chat screen with the PDF invoice attached and pre-filled message ready.',
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
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      side: const BorderSide(color: Colors.blueGrey),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _sharePDFGeneral(context);
                    },
                    icon: const Icon(Icons.share, size: 14),
                    label: const Text('Other Share', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _sharePDFDirectToWhatsApp(context);
                    },
                    icon: const Icon(Icons.send, color: Colors.white, size: 14),
                    label: const Text('Share WhatsApp', style: TextStyle(color: Colors.white, fontSize: 12)),
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
