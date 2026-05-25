import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/pos_receipt_dialog.dart';
import 'camera_scanner_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _discountController = TextEditingController();

  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // Simulate Barcode Scanner Trigger
  void _simulateBarcodeScan(AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner, color: AppColors.primaryMaroon),
            SizedBox(width: 8),
            Text('Simulate Barcode Scan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a mock barcode or item ID to scan into the register:'),
            const SizedBox(height: 12),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode Code (e.g., prod-1, cookies, puff)',
                prefixIcon: Icon(Icons.barcode_reader),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Black Forest'),
                  onPressed: () => _barcodeController.text = 'blackforest',
                ),
                ActionChip(
                  label: const Text('Butter Cookies'),
                  onPressed: () => _barcodeController.text = 'cookies',
                ),
                ActionChip(
                  label: const Text('Veg Puff'),
                  onPressed: () => _barcodeController.text = 'puff',
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _barcodeController.text.toLowerCase().trim();
              Navigator.of(context).pop();
              _barcodeController.clear();

              // Resolve mock product from database list
              Product? foundProduct;
              for (var p in state.products) {
                if (p.name.toLowerCase().contains(code) || p.category.toLowerCase().contains(code)) {
                  foundProduct = p;
                  break;
                }
              }

              if (foundProduct != null) {
                state.addToCart(foundProduct);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scanned: ${foundProduct.name} added to cart!'),
                    backgroundColor: AppColors.ready,
                    duration: const Duration(seconds: 1),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No item resolved for scanned barcode code.'),
                    backgroundColor: AppColors.outOfStock,
                  ),
                );
              }
            },
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(AppState state) {
    _discountController.text = state.posDiscount.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Flat Discount'),
        content: TextField(
          controller: _discountController,
          decoration: const InputDecoration(labelText: 'Discount Value (₹)', prefixIcon: Icon(Icons.percent)),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(_discountController.text) ?? 0.0;
              state.setPosDiscount(val);
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, AppState state, NumberFormat currency) {
    if (state.cart.isEmpty) return;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cashPaidController = TextEditingController(text: state.cartTotal.toStringAsFixed(0));
    Customer? selectedCustomer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('POS Payment Checkout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display Due Total
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bill Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(currency.format(state.cartTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search existing customer
                DropdownButtonFormField<Customer>(
                  decoration: const InputDecoration(labelText: 'Existing Customer Profile'),
                  value: selectedCustomer,
                  items: state.customers
                      .map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.phone})')))
                      .toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedCustomer = val;
                      if (val != null) {
                        nameController.text = val.name;
                        phoneController.text = val.phone;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text('Or Enter Customer Details:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Customer Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Customer Phone', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // Cash details
                TextField(
                  controller: cashPaidController,
                  decoration: const InputDecoration(labelText: 'Cash Received (₹)', prefixIcon: Icon(Icons.payments_outlined)),
                  keyboardType: TextInputType.number,
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
              onPressed: () async {
                final double paid = double.tryParse(cashPaidController.text) ?? state.cartTotal;
                final customerName = nameController.text.trim();
                final customerPhone = phoneController.text.trim();

                // Generate a temporary copy of cart to show in receipt before state clearing
                final cartSnapshot = Map<Product, int>.from(state.cart);
                final subtotalSnapshot = state.cartSubtotal;
                final discountSnapshot = state.posDiscount;
                final gstSnapshot = state.cartGstAmount;
                final totalSnapshot = state.cartTotal;

                final String ordId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                // Call core checkout method
                final success = await state.checkoutPOS(
                  customerName,
                  customerPhone,
                  paidAmount: paid,
                );

                if (success && context.mounted) {
                  Navigator.of(context).pop(); // Close checkout dialog

                  // Open Printable Thermal Invoice Dialog
                  showDialog(
                    context: context,
                    builder: (context) => PosReceiptDialog(
                      orderId: ordId,
                      customerName: customerName,
                      customerPhone: customerPhone,
                      cartItems: cartSnapshot,
                      subtotal: subtotalSnapshot,
                      discount: discountSnapshot,
                      gstAmount: gstSnapshot,
                      total: totalSnapshot,
                      paidAmount: paid,
                    ),
                  );
                }
              },
              child: const Text('Generate Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  void _processScannedBarcode(String code, AppState state) {
    final cleanCode = code.toLowerCase().trim();
    Product? foundProduct;
    for (var p in state.products) {
      if (p.name.toLowerCase().contains(cleanCode) || p.category.toLowerCase().contains(cleanCode) || p.id.toString() == cleanCode) {
        foundProduct = p;
        break;
      }
    }

    if (foundProduct != null) {
      state.addToCart(foundProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned: ${foundProduct.name} added to cart!'),
          backgroundColor: AppColors.ready,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No item resolved for barcode: "$code"'),
          backgroundColor: AppColors.outOfStock,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showScanOptions(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Choose Barcode Scan Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryMaroon,
                child: Icon(Icons.photo_camera, color: Colors.white),
              ),
              title: const Text('Physical Camera scan', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Use your phone back camera to scan real barcodes'),
              onTap: () async {
                Navigator.of(context).pop(); // Close sheet
                final scannedCode = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (context) => const CameraScannerScreen()),
                );
                if (scannedCode != null && mounted) {
                  _processScannedBarcode(scannedCode, state);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.secondaryGold,
                child: Icon(Icons.developer_mode, color: Colors.white),
              ),
              title: const Text('Developer Simulation', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Simulate scan without needing physical items'),
              onTap: () {
                Navigator.of(context).pop(); // Close sheet
                _simulateBarcodeScan(state);
              },
            ),
            const SizedBox(height: 16),
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
        title: const Text('Billing Register (POS)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            onPressed: () => _showScanOptions(context, state),
            tooltip: 'Scan Barcode',
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, state, currency),
        tablet: _buildTabletLayout(context, state, currency),
        desktop: _buildTabletLayout(context, state, currency),
      ),
    );
  }

  // --- MOBILE VIEWS ---
  Widget _buildMobileLayout(BuildContext context, AppState state, NumberFormat currency) {
    return Column(
      children: [
        // 1. Search Box
        _buildSearchField(state),
        // 2. Horizontal Categories
        _buildCategoryFilterRow(state),
        // 3. Grid of Products
        Expanded(
          child: _buildProductsList(state, currency),
        ),
        // 4. Mobile Bottom Cart Panel Drawer Action Trigger
        if (state.cart.isNotEmpty) _buildMobileCartBottomTrigger(context, state, currency),
      ],
    );
  }

  // --- TABLET/DESKTOP SPLIT VIEW ---
  Widget _buildTabletLayout(BuildContext context, AppState state, NumberFormat currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Products Grid
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildSearchField(state),
              _buildCategoryFilterRow(state),
              Expanded(child: _buildProductsList(state, currency)),
            ],
          ),
        ),
        // Vertical Divider line
        const VerticalDivider(width: 1, thickness: 1),
        // Right Side Cart Panel
        Expanded(
          flex: 4,
          child: _buildCartPanel(context, state, currency),
        ),
      ],
    );
  }

  // --- REUSABLE POS LAYOUT COMPONENTS ---
  Widget _buildSearchField(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => state.setProductSearch(val),
        decoration: InputDecoration(
          hintText: 'Search product by name / scan barcode...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryMaroon),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    state.setProductSearch('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryFilterRow(AppState state) {
    final categories = ['All', ...state.categories];
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final bool isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              selectedColor: AppColors.primaryMaroon,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark),
              onSelected: (val) {
                setState(() => _selectedCategory = cat);
                state.setCategoryFilter(cat);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList(AppState state, NumberFormat currency) {
    final prodList = state.filteredProducts;

    if (prodList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.no_photography_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No products matched filters.'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: prodList.length,
      itemBuilder: (context, index) {
        final p = prodList[index];
        final int inCartQty = state.cart[p] ?? 0;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image Preview Box
              Expanded(
                child: Container(
                  color: AppColors.primaryMaroon.withOpacity(0.04),
                  child: Center(
                    child: Icon(
                      p.category == 'Cakes' ? Icons.cake : Icons.cookie,
                      color: AppColors.primaryMaroon.withOpacity(0.3),
                      size: 40,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(currency.format(p.price), style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.stock <= 0 ? 'Out of Stock' : 'Stock: ${p.stock}', style: TextStyle(fontSize: 11, color: p.stock <= 0 ? Colors.red : Colors.grey)),
                        if (p.stock > 0 && inCartQty > 0)
                          // Active adjustment tags
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.secondaryGold, borderRadius: BorderRadius.circular(4)),
                            child: Text('$inCartQty in Cart', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          )
                      ],
                    ),
                  ],
                ),
              ),
              // Cart Actions Drawer
              Container(
                color: AppColors.primaryMaroon.withOpacity(0.04),
                child: inCartQty == 0
                    ? InkWell(
                        onTap: p.stock > 0 ? () => state.addToCart(p) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_shopping_cart, size: 16, color: AppColors.primaryMaroon),
                              SizedBox(width: 4),
                              Text('ADD TO CART', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: IconButton(
                              icon: const Icon(Icons.remove, size: 16, color: AppColors.primaryMaroon),
                              onPressed: () => state.removeFromCart(p),
                            ),
                          ),
                          Text('$inCartQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 16, color: AppColors.primaryMaroon),
                              onPressed: () => state.addToCart(p),
                            ),
                          ),
                        ],
                      ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileCartBottomTrigger(BuildContext context, AppState state, NumberFormat currency) {
    return InkWell(
      onTap: () {
        // Expand active Cart Panel inside mobile modal popup
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => _buildCartPanel(context, state, currency),
          ),
        );
      },
      child: Container(
        color: AppColors.primaryMaroon,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Cart (${state.cart.length} Items)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Pay ${currency.format(state.cartTotal)}',
                  style: const TextStyle(color: AppColors.secondaryGold, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_up, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel(BuildContext context, AppState state, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cart Items (${state.cart.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (state.cart.isNotEmpty)
                TextButton(
                  onPressed: () => state.clearCart(),
                  child: const Text('Clear Cart', style: TextStyle(color: Colors.red)),
                )
            ],
          ),
          const Divider(),

          // Cart Items List
          Expanded(
            child: state.cart.isEmpty
                ? const Center(
                    child: Text('Shopping Cart is empty', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: state.cart.length,
                    itemBuilder: (context, index) {
                      final p = state.cart.keys.elementAt(index);
                      final qty = state.cart[p]!;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('$qty x ${currency.format(p.price)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currency.format(p.price * qty), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => state.removeProductEntirely(p),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),

          // Billing Math Summary
          Column(
            children: [
              _buildSummaryRow('Subtotal', currency.format(state.cartSubtotal)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount'),
                  Row(
                    children: [
                      if (state.posDiscount > 0)
                        Text('- ' + currency.format(state.posDiscount), style: const TextStyle(color: Colors.red)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryMaroon),
                        onPressed: () => _showDiscountDialog(state),
                      )
                    ],
                  ),
                ],
              ),
              _buildSummaryRow('GST (5%)', currency.format(state.cartGstAmount)),
              const Divider(),
              _buildSummaryRow('Grand Total', currency.format(state.cartTotal), isBold: true, fontSize: 16),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.cart.isEmpty
                      ? null
                      : () {
                          state.clearCart();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('POS register quote saved offline!')),
                          );
                        },
                  child: const Text('SAVE QUOTE'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.cart.isEmpty ? null : () => _showCheckoutDialog(context, state, currency),
                  child: Text('PAY ${currency.format(state.cartTotal)}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, {bool isBold = false, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: isBold ? AppColors.primaryMaroon : AppColors.textDark)),
        ],
      ),
    );
  }
}
