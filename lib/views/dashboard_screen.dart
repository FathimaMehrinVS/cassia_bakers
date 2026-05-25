import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../models/product.dart';
import '../widgets/responsive_layout.dart';
import 'pos_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onTabChange; // Callback to switch active tabs in main navigator

  const DashboardScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cassia Bakery ERP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {
                  // Alert user of critical stocks
                  if (state.lowStockItemsCount > 0) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Low Stock Alerts'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: state.products
                                .where((p) => p.isLowStock || p.isOutOfStock)
                                .map((p) => ListTile(
                                      leading: const Icon(Icons.warning, color: AppColors.lowStock),
                                      title: Text(p.name),
                                      subtitle: Text('Current Stock: ${p.stock} pcs'),
                                      trailing: Text('Threshold: ${p.lowStockThreshold}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ))
                                .toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close', style: TextStyle(color: AppColors.primaryMaroon)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              if (state.lowStockItemsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${state.lowStockItemsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date Selector Panel
              _buildDateHeader(context),
              const SizedBox(height: 16),

              // 2. Metrics Cards Grid (Responsive Layout)
              ResponsiveLayout(
                mobile: _buildMetricsGrid(context, state, currencyFormat),
                tablet: _buildMetricsGridTablet(context, state, currencyFormat),
                desktop: _buildMetricsGridTablet(context, state, currencyFormat),
              ),
              const SizedBox(height: 24),

              // 3. Quick Actions Dashboard Drawer
              const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
              const SizedBox(height: 12),
              _buildQuickActions(context, state),
              const SizedBox(height: 24),

              // 4. Top Selling Products & Overview Charts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Sellers
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
                            TextButton(
                              onPressed: () => onTabChange(3), // Navigate to Inventory tab
                              child: const Text('View All', style: TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTopSellers(state, currencyFormat),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Monthly Sales Graph Overview Widget
              const Text('Monthly Sales Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sales Performance (May 2026)', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => onTabChange(4), // Navigate to Reports tab
                            child: const Text('View Report', style: TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: MiniSalesChartPainter(isDark: isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB WIDGET BUILDERS ---
  Widget _buildDateHeader(BuildContext context) {
    final String formattedDate = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());
    return Card(
      color: AppColors.primaryMaroon.withOpacity(0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primaryMaroon, size: 20),
            const SizedBox(width: 10),
            Text(
              formattedDate,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryMaroon, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, AppState state, NumberFormat format) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Today\'s Sales',
                value: format.format(state.todaySalesTotal + 28450), // Mock seeding offset
                subtext: '▲ 12.5% from yesterday',
                color: Colors.green[600]!,
                icon: Icons.monetization_on,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Orders Pending',
                value: '${state.pendingOrdersCount}',
                subtext: 'Active production queue',
                color: Colors.orange[700]!,
                icon: Icons.shopping_bag,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Pending Payments',
                value: format.format(state.pendingPaymentsTotal),
                subtext: 'Outstanding customer dues',
                color: Colors.indigo[600]!,
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Low Stock Items',
                value: '${state.lowStockItemsCount}',
                subtext: 'Reorder levels triggered',
                color: AppColors.primaryMaroon,
                icon: Icons.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGridTablet(BuildContext context, AppState state, NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Today\'s Sales',
            value: format.format(state.todaySalesTotal + 28450),
            subtext: '▲ 12.5% yesterday',
            color: Colors.green[600]!,
            icon: Icons.monetization_on,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Orders Pending',
            value: '${state.pendingOrdersCount}',
            subtext: 'Active production',
            color: Colors.orange[700]!,
            icon: Icons.shopping_bag,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Pending Payments',
            value: format.format(state.pendingPaymentsTotal),
            subtext: 'Customer balances',
            color: Colors.indigo[600]!,
            icon: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Low Stock Items',
            value: '${state.lowStockItemsCount}',
            subtext: 'Alert threshold trigger',
            color: AppColors.primaryMaroon,
            icon: Icons.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Icon(icon, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtext, style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppState state) {
    final List<Map<String, dynamic>> actions = [
      {'title': 'Billing (POS)', 'icon': Icons.point_of_sale, 'color': AppColors.primaryMaroon, 'tab': 2},
      {'title': 'New Order', 'icon': Icons.cake, 'color': Colors.orange[700]!, 'tab': 1},
      {'title': 'Add Product', 'icon': Icons.add_circle, 'color': Colors.teal[600]!, 'dialog': true},
      {'title': 'Expenses', 'icon': Icons.payments_outlined, 'color': Colors.blue[600]!, 'tab': 5}, // Custom redirect in mainframe
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((act) {
        return Expanded(
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (act['tab'] != null) {
                    onTabChange(act['tab'] as int);
                  } else if (act['dialog'] == true) {
                    _showAddProductDialog(context, state);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (act['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (act['color'] as Color).withOpacity(0.3), width: 1.5),
                  ),
                  child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 28),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                act['title'] as String,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopSellers(AppState state, NumberFormat format) {
    // Standard static top products list mirroring provided screen layouts
    final List<Map<String, dynamic>> sellers = [
      {'name': 'Black Forest Cake', 'price': 1250.0, 'sold': 18, 'icon': Icons.cake},
      {'name': 'Chocolate Pastry', 'price': 60.0, 'sold': 35, 'icon': Icons.cookie},
      {'name': 'Veg Puff', 'price': 25.0, 'sold': 52, 'icon': Icons.bakery_dining},
    ];

    return Column(
      children: sellers.map((item) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryMaroon.withOpacity(0.08),
              child: Icon(item['icon'] as IconData, color: AppColors.primaryMaroon),
            ),
            title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(format.format(item['price'])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item['sold']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryMaroon)),
                const Text('Sold', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAddProductDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String category = 'Cakes';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 12),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Initial Stock Qty'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Cakes', 'Pastries', 'Bread', 'Cookies', 'Beverages']
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
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty && stockController.text.isNotEmpty) {
                state.addProduct(
                  Product(
                    name: nameController.text,
                    price: double.parse(priceController.text),
                    stock: int.parse(stockController.text),
                    category: category,
                  ),
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${nameController.text} added!'), backgroundColor: AppColors.ready),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MINI GRAPH LINE CANVAS PAINTER (Monthly Sales Overview Match)
// =========================================================================
class MiniSalesChartPainter extends CustomPainter {
  final bool isDark;
  MiniSalesChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paints
    final Paint linePaint = Paint()
      ..color = AppColors.primaryMaroon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final Paint gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Paint pointPaint = Paint()
      ..color = AppColors.secondaryGold
      ..style = PaintingStyle.fill;

    // Draw horizontal grid helper lines
    for (int i = 1; i <= 4; i++) {
      final double y = h * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Grid details points: e.g. 7 points representing monthly sales checkpoints
    final List<Offset> points = [
      Offset(w * 0.05, h * 0.75),
      Offset(w * 0.20, h * 0.60),
      Offset(w * 0.35, h * 0.80),
      Offset(w * 0.50, h * 0.50),
      Offset(w * 0.65, h * 0.40),
      Offset(w * 0.80, h * 0.55),
      Offset(w * 0.95, h * 0.20),
    ];

    // Build the visual line graph path
    final Path linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      // Draw bezier curves for smooth indie dev look
      final xc = (points[i - 1].dx + points[i].dx) / 2;
      final yc = (points[i - 1].dy + points[i].dy) / 2;
      linePath.quadraticBezierTo(points[i - 1].dx, points[i - 1].dy, xc, yc);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    // Draw smooth shade gradient under the line
    final Path fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, h);
    fillPath.lineTo(points.first.dx, h);
    fillPath.close();

    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryMaroon.withOpacity(0.3),
        AppColors.primaryMaroon.withOpacity(0.01),
      ],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTRB(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Draw main colored line
    canvas.drawPath(linePath, linePaint);

    // Draw glowing circles on data dots
    for (var pt in points) {
      canvas.drawCircle(pt, 5, pointPaint);
      canvas.drawCircle(pt, 3, Paint()..color = AppColors.primaryMaroon);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
