import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _activeReportTab = 'Sales'; // Sales, P&L, Expenses...
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 24)),
    end: DateTime.now(),
  );

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Calculate totals for ledger summary
    double totalRevenue = state.todaySalesTotal + 28450 + 45000; // Seeding offset
    double totalExpenses = state.expenses.fold(0.0, (sum, item) => sum + item.amount);
    double netProfit = totalRevenue - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date Range picker bar
            _buildDateRangePickerBar(context),
            const SizedBox(height: 20),

            // 2. Grid of 6 Reports selectors matching mockup exactly
            _buildReportsSelectorsGrid(),
            const SizedBox(height: 24),

            // 3. Main Analytics Custom-Painted Visual Graph
            Text(
              '$_activeReportTab Performance Chart',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown),
            ),
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
                        Text(
                          '${DateFormat('dd MMM').format(_selectedDateRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _activeReportTab == 'Sales'
                              ? 'Total: ${currency.format(totalRevenue)}'
                              : _activeReportTab == 'Expenses'
                                  ? 'Total: ${currency.format(totalExpenses)}'
                                  : 'Profit: ${currency.format(netProfit)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // High fidelity visual custom painter chart
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: AnalyticsChartPainter(
                          isDark: isDark,
                          reportType: _activeReportTab,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // X-Axis labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('1 May', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('7 May', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('14 May', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('20 May', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('25 May', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Financial Ledger summary table
            const Text('Financial Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _buildLedgerRow('Total Sales Revenue', currency.format(totalRevenue), Colors.green[600]!),
                    const Divider(),
                    _buildLedgerRow('Operational Expenses', currency.format(totalExpenses), Colors.red[600]!),
                    const Divider(),
                    _buildLedgerRow('Net Profit Margin', currency.format(netProfit), AppColors.primaryMaroon, isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB WIDGET BUILDERS ---
  Widget _buildDateRangePickerBar(BuildContext context) {
    return InkWell(
      onTap: _showDateRangePicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryMaroon.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, color: AppColors.primaryMaroon),
                const SizedBox(width: 10),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)}  -  ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                ),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryMaroon),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSelectorsGrid() {
    final List<Map<String, dynamic>> selectors = [
      {'title': 'Sales Report', 'tab': 'Sales', 'icon': Icons.trending_up, 'color': Colors.green},
      {'title': 'Profit & Loss', 'tab': 'P&L', 'icon': Icons.pie_chart_outline, 'color': Colors.amber},
      {'title': 'Expense Report', 'tab': 'Expenses', 'icon': Icons.account_balance_wallet, 'color': Colors.purple},
      {'title': 'Stock Report', 'tab': 'Stock', 'icon': Icons.inventory, 'color': Colors.blue},
      {'title': 'Customer Report', 'tab': 'Customers', 'icon': Icons.people_outline, 'color': Colors.pink},
      {'title': 'Purchase Report', 'tab': 'Purchase', 'icon': Icons.shopping_cart_outlined, 'color': Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: selectors.length,
      itemBuilder: (context, index) {
        final sel = selectors[index];
        final bool isActive = _activeReportTab == sel['tab'];

        return GestureDetector(
          onTap: () => setState(() => _activeReportTab = sel['tab'] as String),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? sel['color'] as Color : (sel['color'] as Color).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.secondaryGold : (sel['color'] as Color).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sel['icon'] as IconData,
                  color: isActive ? Colors.white : sel['color'] as Color,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  sel['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLedgerRow(String label, String val, Color valColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 16 : 14,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// INTERACTIVE ANALYTICS CUSTOM CANVAS LINE GRAPH PAINTER
// =========================================================================
class AnalyticsChartPainter extends CustomPainter {
  final bool isDark;
  final String reportType;

  AnalyticsChartPainter({required this.isDark, required this.reportType});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paints configuration
    Color mainColor = AppColors.primaryMaroon;
    if (reportType == 'Sales') mainColor = Colors.green[600]!;
    if (reportType == 'Expenses') mainColor = Colors.purple[600]!;
    if (reportType == 'P&L') mainColor = Colors.teal[600]!;

    final Paint linePaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    final Paint gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Paint dotPaint = Paint()
      ..color = AppColors.secondaryGold
      ..style = PaintingStyle.fill;

    // Draw background grid lines
    for (int i = 1; i <= 4; i++) {
      final double y = h * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Set points according to selected report tab to mock visual differences
    List<Offset> points = [];
    if (reportType == 'Sales') {
      points = [
        Offset(0, h * 0.8),
        Offset(w * 0.2, h * 0.65),
        Offset(w * 0.4, h * 0.75),
        Offset(w * 0.6, h * 0.45),
        Offset(w * 0.8, h * 0.50),
        Offset(w, h * 0.2),
      ];
    } else if (reportType == 'Expenses') {
      points = [
        Offset(0, h * 0.3),
        Offset(w * 0.2, h * 0.45),
        Offset(w * 0.4, h * 0.25),
        Offset(w * 0.6, h * 0.6),
        Offset(w * 0.8, h * 0.7),
        Offset(w, h * 0.75),
      ];
    } else {
      // P&L or other tabs
      points = [
        Offset(0, h * 0.6),
        Offset(w * 0.2, h * 0.55),
        Offset(w * 0.4, h * 0.5),
        Offset(w * 0.6, h * 0.35),
        Offset(w * 0.8, h * 0.45),
        Offset(w, h * 0.3),
      ];
    }

    // Draw main analytical line
    final Path linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final xc = (points[i - 1].dx + points[i].dx) / 2;
      final yc = (points[i - 1].dy + points[i].dy) / 2;
      linePath.quadraticBezierTo(points[i - 1].dx, points[i - 1].dy, xc, yc);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    // Draw gradient shade underneath
    final Path fillPath = Path.from(linePath);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        mainColor.withOpacity(0.35),
        mainColor.withOpacity(0.01),
      ],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTRB(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Draw path line
    canvas.drawPath(linePath, linePaint);

    // Draw visual active data checkpoints
    for (var pt in points) {
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 3, Paint()..color = mainColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
