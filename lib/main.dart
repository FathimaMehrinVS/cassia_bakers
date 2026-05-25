import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/database_helper.dart';
import 'providers/app_state.dart';
import 'providers/theme_provider.dart';
import 'views/splash_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/pos_screen.dart';
import 'views/orders_screen.dart';
import 'views/inventory_screen.dart';
import 'views/customers_screen.dart';
import 'views/expenses_screen.dart';
import 'views/reports_screen.dart';
import 'views/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Trigger database engine pre-initialization
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Cassia Bakery ERP',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

// =========================================================================
// RESPONSIVE MAIN ERP NAVIGATION FRAME
// =========================================================================
class MainNavigationFrame extends StatefulWidget {
  const MainNavigationFrame({super.key});

  @override
  State<MainNavigationFrame> createState() => _MainNavigationFrameState();
}

class _MainNavigationFrameState extends State<MainNavigationFrame> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 800; // Tablet / Web Layout breakpoint

    // Define child screens linked with index
    final List<Widget> screens = [
      DashboardScreen(onTabChange: (index) {
        setState(() => _currentIndex = index);
      }),
      const OrdersScreen(),
      const PosScreen(),
      const InventoryScreen(),
      const CustomersScreen(),
      const ExpensesScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            // Vertical Side Navigation Rail for Large Screens
            NavigationRail(
              selectedIndex: _currentIndex >= 8 ? 0 : _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.primaryMaroon,
              selectedIconTheme: const IconThemeData(color: AppColors.secondaryGold),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(color: AppColors.secondaryGold, fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70, fontSize: 10),
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  const Icon(Icons.cookie, color: AppColors.secondaryGold, size: 36),
                  const SizedBox(height: 24),
                ],
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.cake_outlined), selectedIcon: Icon(Icons.cake), label: Text('Orders')),
                NavigationRailDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: Text('POS Billing')),
                NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Inventory')),
                NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Customers')),
                NavigationRailDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: Text('Expenses')),
                NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Reports')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Screen Area
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    // Standard Mobile Layout
    return Scaffold(
      body: screens[_currentIndex],
      // Bottom Navigation Bar manages 5 Primary tabs for Mobile, routing others to the More drawer
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex >= 5 ? 4 : _currentIndex,
        onTap: (index) {
          if (index == 4) {
            // Open More Operations Bottom Sheet Drawer
            _showMoreOperationsSheet(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.cake_outlined), activeIcon: Icon(Icons.cake), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined), activeIcon: Icon(Icons.point_of_sale), label: 'POS Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined), activeIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  // --- MOBILE MORE OPERATIONS DRAWER ---
  void _showMoreOperationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                'More Business Operations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.warmBrown),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.pink),
              title: const Text('Customer Directory', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Outstanding ledgers and loyalty points'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 4); // Index of Customers
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments, color: Colors.green),
              title: const Text('Operational Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Shop rent, utility bills, and raw materials'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 5); // Index of Expenses
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.purple),
              title: const Text('Reports & Performance', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Visual sales charts and P&L ledger statistics'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 6); // Index of Reports
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blueGrey),
              title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tax configurations and staff roster controls'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 7); // Index of Settings
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
