import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _activeStockFilter = 'All'; // All, Low Stock, Out of Stock
  String _selectedCategory = 'All'; // All, Cakes, Pastries...

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductFormDialog(BuildContext context, AppState state, [Product? product]) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: isEdit ? product.name : '');
    final priceController = TextEditingController(text: isEdit ? product.price.toStringAsFixed(0) : '');
    final stockController = TextEditingController(text: isEdit ? product.stock.toString() : '');
    final thresholdController = TextEditingController(text: isEdit ? product.lowStockThreshold.toString() : '5');
    
    String category = isEdit ? product.category : 'Cakes';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Product details' : 'Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity', prefixIcon: Icon(Icons.inventory_2_outlined)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thresholdController,
                decoration: const InputDecoration(labelText: 'Low Stock Threshold Warning', prefixIcon: Icon(Icons.warning_amber_outlined)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: state.categories.contains(category)
                    ? category
                    : (state.categories.isNotEmpty ? state.categories.first : 'Cakes'),
                decoration: const InputDecoration(labelText: 'Category'),
                items: state.categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) category = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty && stockController.text.isNotEmpty) {
                final double price = double.parse(priceController.text);
                final int stock = int.parse(stockController.text);
                final int thresh = int.parse(thresholdController.text);

                if (isEdit) {
                  state.updateProduct(
                    product.copyWith(
                      name: nameController.text,
                      price: price,
                      stock: stock,
                      category: category,
                      lowStockThreshold: thresh,
                    ),
                  );
                } else {
                  state.addProduct(
                    Product(
                      name: nameController.text,
                      price: price,
                      stock: stock,
                      category: category,
                      lowStockThreshold: thresh,
                    ),
                  );
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} saved successfully!'),
                    backgroundColor: AppColors.ready,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Apply multiple filters locally
    final List<Product> displayedProducts = state.products.where((p) {
      // 1. Search Query
      final matchesSearch = p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchController.text.toLowerCase());
      
      // 2. Category Filter
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;

      // 3. Stock Level Filter
      bool matchesStock = true;
      if (_activeStockFilter == 'Low Stock') {
        matchesStock = p.isLowStock;
      } else if (_activeStockFilter == 'Out of Stock') {
        matchesStock = p.isOutOfStock;
      }

      return matchesSearch && matchesCat && matchesStock;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => _showProductFormDialog(context, state),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Create Category Button
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md, left: AppSpacing.md, right: AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showAddCategoryDialog(context, state),
                icon: const Icon(Icons.category_outlined, color: Colors.white, size: 18),
                label: const Text(
                  'Create New Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ),
            ),
          ),
          // 1. Search textfield
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search product by name...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryMaroon),
              ),
            ),
          ),

          // 2. Overview Stats (Total, Low Stock, Out of stock summary pills)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _buildOverviewPill('Total Products', '${state.products.length}', Colors.blue[600]!, 'All'),
                const SizedBox(width: 8),
                _buildOverviewPill('Low Stock Items', '${state.lowStockItemsCount}', AppColors.pending, 'Low Stock'),
                const SizedBox(width: 8),
                _buildOverviewPill('Out of Stock', '${state.products.where((p) => p.isOutOfStock).length}', AppColors.outOfStock, 'Out of Stock'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Categorization Horizontal Slider chips
          _buildCategoryChips(state),

          // 4. Products Inventory List view
          Expanded(
            child: displayedProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No products match criteria'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final p = displayedProducts[index];
                      Color stockColor = AppColors.inStock;
                      String stockLabel = 'In Stock';

                      if (p.isOutOfStock) {
                        stockColor = AppColors.outOfStock;
                        stockLabel = 'Out of Stock';
                      } else if (p.isLowStock) {
                        stockColor = AppColors.lowStock;
                        stockLabel = 'Low Stock';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showProductFormDialog(context, state, p),
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                // Thumbnail Circle
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryMaroon.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    p.category == 'Cakes' ? Icons.cake : Icons.cookie,
                                    color: AppColors.primaryMaroon,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Product metadata details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text('Category: ${p.category} | Stock: ${p.stock} pcs', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(currency.format(p.price), style: const TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                ),

                                // Status Badge & Actions
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stockColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: stockColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        stockLabel,
                                        style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppColors.primaryMaroon, size: 20),
                                          onPressed: () => _showProductFormDialog(context, state, p),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Product?'),
                                                content: Text('Are you sure you want to delete ${p.name}?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      state.deleteProduct(p.id!);
                                                      Navigator.of(context).pop();
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildOverviewPill(String title, String val, Color color, String filterName) {
    final bool isSelected = _activeStockFilter == filterName;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeStockFilter = filterName),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.secondaryGold : color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                val,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter category name (e.g. Ice Cream)',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final String catName = controller.text.trim();
              if (catName.isNotEmpty) {
                await state.addCategory(catName);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$catName" created successfully!'),
                    backgroundColor: AppColors.ready,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(AppState state) {
    final categories = ['All', ...state.categories];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final bool isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(cat, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
            ),
          );
        },
      ),
    );
  }
}
