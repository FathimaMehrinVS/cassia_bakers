import 'package:flutter/material.dart';
import '../core/database_helper.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/user_model.dart';
import '../models/supplier.dart';
import '../models/supplier_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Loaded DB Lists
  List<Product> _products = [];
  List<CakeOrder> _orders = [];
  List<Customer> _customers = [];
  List<Expense> _expenses = [];
  List<String> _categories = [];
  List<Supplier> _suppliers = [];
  List<SupplierTransaction> _transactions = [];

  List<Product> get products => _products;
  List<CakeOrder> get orders => _orders;
  List<Customer> get customers => _customers;
  List<Expense> get expenses => _expenses;
  List<String> get categories => _categories;
  List<Supplier> get suppliers => _suppliers;
  List<SupplierTransaction> get transactions => _transactions;

  // Bluetooth Printer Settings
  String? _pairedPrinterName;
  bool _isPrinterConnected = false;

  String? get pairedPrinterName => _pairedPrinterName;
  bool get isPrinterConnected => _isPrinterConnected;

  // Active Session Auth
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Active POS Cart
  final Map<Product, int> _cart = {};
  Map<Product, int> get cart => _cart;
  double _posDiscount = 0.0;
  double _posGstPercent = 5.0; // Default 5% GST

  double get posDiscount => _posDiscount;
  double get posGstPercent => _posGstPercent;

  // Filtering & Search states
  String _productSearchQuery = '';
  String _customerSearchQuery = '';
  String _orderSearchQuery = '';
  String _activeCategoryFilter = 'All';

  String get productSearchQuery => _productSearchQuery;
  String get customerSearchQuery => _customerSearchQuery;
  String get orderSearchQuery => _orderSearchQuery;
  String get activeCategoryFilter => _activeCategoryFilter;

  // Constructor
  AppState() {
    loadAllData();
    _loadUserSession();
    loadPrinterSettings();
  }

  // ==========================================
  // DB DATA LOADING
  // ==========================================
  Future<void> loadAllData() async {
    try {
      _products = await _db.getProducts();
      _orders = await _db.getOrders();
      _customers = await _db.getCustomers();
      _expenses = await _db.getExpenses();
      _categories = await _db.getCategories();
      _suppliers = await _db.getSuppliers();
      _transactions = await _db.getSupplierTransactions();
      notifyListeners();
    } catch (e) {
      // Graceful error logging
    }
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('auth_username');
    final role = prefs.getString('auth_role');
    if (username != null && role != null) {
      _currentUser = User(username: username, role: role, isLoggedIn: true);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password, String role) async {
    // Standard mock credentials for student/indie project
    if ((role == 'Admin' && username.toLowerCase() == 'admin' && password == 'admin123') ||
        (role == 'Staff' && username.toLowerCase() == 'staff' && password == 'staff123')) {
      _currentUser = User(username: username, role: role, isLoggedIn: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_username', username);
      await prefs.setString('auth_role', role);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_username');
    await prefs.remove('auth_role');
    notifyListeners();
  }

  // ==========================================
  // PRODUCT / INVENTORY OPERATIONS
  // ==========================================
  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_productSearchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_productSearchQuery.toLowerCase());
      final matchesCat = _activeCategoryFilter == 'All' || p.category == _activeCategoryFilter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  void setProductSearch(String query) {
    _productSearchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _activeCategoryFilter = category;
    notifyListeners();
  }

  Future<void> addProduct(Product p) async {
    await _db.insertProduct(p);
    await loadAllData();
  }

  Future<void> updateProduct(Product p) async {
    await _db.updateProduct(p);
    await loadAllData();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    await loadAllData();
  }

  // ==========================================
  // POS CART OPERATIONS
  // ==========================================
  double get cartSubtotal {
    double sub = 0.0;
    _cart.forEach((product, qty) {
      sub += product.price * qty;
    });
    return sub;
  }

  double get cartGstAmount {
    return (cartSubtotal - _posDiscount) * (_posGstPercent / 100);
  }

  double get cartTotal {
    final t = cartSubtotal - _posDiscount + cartGstAmount;
    return t < 0 ? 0.0 : t;
  }

  void addToCart(Product p) {
    if (p.stock <= 0) return; // Out of stock
    
    Product? existingKey;
    for (var key in _cart.keys) {
      if (key.id == p.id) {
        existingKey = key;
        break;
      }
    }

    if (existingKey != null) {
      if (_cart[existingKey]! < p.stock) {
        _cart[existingKey] = _cart[existingKey]! + 1;
      }
    } else {
      _cart[p] = 1;
    }
    notifyListeners();
  }

  void removeFromCart(Product p) {
    if (_cart.containsKey(p)) {
      if (_cart[p]! > 1) {
        _cart[p] = _cart[p]! - 1;
      } else {
        _cart.remove(p);
      }
      notifyListeners();
    }
  }

  void removeProductEntirely(Product p) {
    _cart.remove(p);
    notifyListeners();
  }

  void updateCartQuantity(Product p, int qty) {
    if (qty <= 0) {
      _cart.remove(p);
    } else if (qty <= p.stock) {
      _cart[p] = qty;
    }
    notifyListeners();
  }

  void setPosDiscount(double val) {
    _posDiscount = val;
    notifyListeners();
  }

  void setPosGst(double percent) {
    _posGstPercent = percent;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _posDiscount = 0.0;
    notifyListeners();
  }

  Future<bool> checkoutPOS(String customerName, String customerPhone, {double paidAmount = 0.0}) async {
    if (_cart.isEmpty) return false;

    // 1. Deduct Stock Levels in local SQLite
    for (var entry in _cart.entries) {
      final p = entry.key;
      final qty = entry.value;
      final updatedProduct = p.copyWith(stock: p.stock - qty);
      await _db.updateProduct(updatedProduct);
    }

    // 2. Manage loyalty points (1 point per 100 ₹)
    final pointsEarned = (cartTotal / 100).floor();
    final double dues = cartTotal - paidAmount;

    // Check if customer exists
    final cList = await _db.getCustomers();
    final matchingCustIdx = cList.indexWhere((c) => c.phone == customerPhone);

    if (matchingCustIdx != -1) {
      final oldCust = cList[matchingCustIdx];
      final updatedCust = oldCust.copyWith(
        loyaltyPoints: oldCust.loyaltyPoints + pointsEarned,
        pendingDues: oldCust.pendingDues + (dues > 0 ? dues : 0.0),
      );
      await _db.updateCustomer(updatedCust);
    } else if (customerPhone.isNotEmpty && customerName.isNotEmpty) {
      final newCust = Customer(
        name: customerName,
        phone: customerPhone,
        loyaltyPoints: pointsEarned,
        pendingDues: dues > 0 ? dues : 0.0,
      );
      await _db.insertCustomer(newCust);
    }

    // 3. Save as completed POS sale order log
    final String ordId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final itemsSummary = _cart.entries.map((e) => '${e.value}x ${e.key.name}').join(', ');
    
    final newOrder = CakeOrder(
      id: ordId,
      customerName: customerName.isNotEmpty ? customerName : 'Walk-in Customer',
      customerPhone: customerPhone.isNotEmpty ? customerPhone : 'N/A',
      cakeDetails: itemsSummary,
      deliveryDate: DateTime.now().toString().split(' ')[0],
      deliveryTime: 'Immediate',
      totalAmount: cartTotal,
      advanceAmount: paidAmount,
      status: 'Delivered',
      specialInstructions: 'POS Checkout Sale',
      createdAt: DateTime.now().toString(),
    );
    await _db.insertOrder(newOrder);

    // 4. Reload lists and clear active cart selection
    clearCart();
    await loadAllData();
    return true;
  }

  // ==========================================
  // CUSTOM CAKE ORDER OPERATIONS
  // ==========================================
  List<CakeOrder> get filteredOrders {
    return _orders.where((o) {
      final matchesSearch = o.customerName.toLowerCase().contains(_orderSearchQuery.toLowerCase()) ||
          o.customerPhone.contains(_orderSearchQuery) ||
          o.cakeDetails.toLowerCase().contains(_orderSearchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  void setOrderSearch(String query) {
    _orderSearchQuery = query;
    notifyListeners();
  }

  Future<void> addOrder(CakeOrder o) async {
    await _db.insertOrder(o);
    await loadAllData();
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) {
      final updated = _orders[idx].copyWith(status: status);
      await _db.updateOrder(updated);
      await loadAllData();
    }
  }

  // ==========================================
  // CUSTOMER DIRECTORY OPERATIONS
  // ==========================================
  List<Customer> get filteredCustomers {
    return _customers.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(_customerSearchQuery.toLowerCase()) ||
          c.phone.contains(_customerSearchQuery);
      return matchesSearch;
    }).toList();
  }

  void setCustomerSearch(String query) {
    _customerSearchQuery = query;
    notifyListeners();
  }

  Future<void> addCustomer(Customer c) async {
    await _db.insertCustomer(c);
    await loadAllData();
  }

  Future<void> settleCustomerDues(Customer c, double payment) async {
    final updatedDues = c.pendingDues - payment;
    final updated = c.copyWith(pendingDues: updatedDues < 0 ? 0.0 : updatedDues);
    await _db.updateCustomer(updated);
    await loadAllData();
  }

  // ==========================================
  // EXPENSE OPERATIONS
  // ==========================================
  Future<void> addExpense(Expense e) async {
    await _db.insertExpense(e);
    await loadAllData();
  }

  // ==========================================
  // STATS & REPORT SUMMARY MATH
  // ==========================================
  double get todaySalesTotal {
    final today = DateTime.now().toString().split(' ')[0];
    double total = 0.0;
    for (var o in _orders) {
      if (o.createdAt.startsWith(today) && o.status == 'Delivered') {
        total += o.totalAmount;
      }
    }
    return total;
  }

  int get pendingOrdersCount {
    return _orders.where((o) => o.status == 'Pending' || o.status == 'Preparing').length;
  }

  double get pendingPaymentsTotal {
    double dues = 0.0;
    for (var c in _customers) {
      dues += c.pendingDues;
    }
    return dues;
  }

  int get lowStockItemsCount {
    return _products.where((p) => p.isLowStock || p.isOutOfStock).length;
  }

  // ==========================================
  // DYNAMIC STAFF & PRESET TARIFF MANAGEMENT
  // ==========================================
  final List<User> _staffList = [
    User(username: 'admin', role: 'Admin'),
    User(username: 'staff', role: 'Staff'),
  ];
  List<User> get staffList => _staffList;

  void addStaff(String username, String password, String role) {
    _staffList.add(User(username: username, role: role));
    notifyListeners();
  }

  void deleteStaff(String username) {
    _staffList.removeWhere((u) => u.username == username);
    notifyListeners();
  }

  double get defaultGstPercent => _posGstPercent;
  void setDefaultGstPercent(double rate) => setPosGst(rate);

  // ==========================================
  // DYNAMIC CATEGORY OPERATIONS
  // ==========================================
  Future<void> addCategory(String name) async {
    final clean = name.trim();
    if (clean.isNotEmpty) {
      await _db.insertCategory(clean);
      await loadAllData();
    }
  }

  // ==========================================
  // SUPPLIER & LEDGER OPERATIONS
  // ==========================================
  Future<void> addSupplier(Supplier s) async {
    await _db.insertSupplier(s);
    await loadAllData();
  }

  Future<void> updateSupplier(Supplier s) async {
    await _db.updateSupplier(s);
    await loadAllData();
  }

  Future<void> deleteSupplier(int id) async {
    await _db.deleteSupplier(id);
    await loadAllData();
  }

  Future<void> addSupplierTransaction(SupplierTransaction t) async {
    await _db.insertSupplierTransaction(t);
    await loadAllData();
  }

  Future<void> settleSupplierDues(Supplier s, double amount, String date, {String? notes}) async {
    final t = SupplierTransaction(
      supplierId: s.id!,
      productsPurchased: 'Debt Settlement Payment',
      quantity: 0,
      costPrice: 0.0,
      totalAmount: 0.0,
      paidAmount: amount,
      dueAmount: -amount,
      transactionDate: date,
      notes: notes ?? 'Ledger balance payment',
    );
    await addSupplierTransaction(t);
  }

  // ==========================================
  // BLUETOOTH THERMAL PRINTER SETTINGS
  // ==========================================
  Future<void> loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pairedPrinterName = prefs.getString('paired_printer_name');
    _isPrinterConnected = prefs.getBool('printer_connected') ?? false;
    notifyListeners();
  }

  Future<void> pairPrinter(String name) async {
    _pairedPrinterName = name;
    _isPrinterConnected = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paired_printer_name', name);
    await prefs.setBool('printer_connected', true);
    notifyListeners();
  }

  Future<void> disconnectPrinter() async {
    _pairedPrinterName = null;
    _isPrinterConnected = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('paired_printer_name');
    await prefs.setBool('printer_connected', false);
    notifyListeners();
  }

  Future<void> resetDatabaseToSeeded() async {
    await _db.resetDatabase();
    await loadAllData();
  }
}
