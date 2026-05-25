import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/supplier.dart';
import '../models/supplier_transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web Fallback Memory Cache
  final List<Product> _webProducts = [];
  final List<CakeOrder> _webOrders = [];
  final List<Customer> _webCustomers = [];
  final List<Expense> _webExpenses = [];
  final List<String> _webCategories = [];
  final List<Supplier> _webSuppliers = [];
  final List<SupplierTransaction> _webSupplierTransactions = [];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web. Using memory fallback.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('cassio_bakers.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Products Table with barcode field
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT,
        lowStockThreshold INTEGER NOT NULL DEFAULT 5,
        barcode TEXT NOT NULL UNIQUE
      )
    ''');

    // Orders Table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customerName TEXT NOT NULL,
        customerPhone TEXT NOT NULL,
        cakeDetails TEXT NOT NULL,
        deliveryDate TEXT NOT NULL,
        deliveryTime TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        advanceAmount REAL NOT NULL,
        status TEXT NOT NULL,
        specialInstructions TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        loyaltyPoints INTEGER NOT NULL DEFAULT 0,
        pendingDues REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Dynamic Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Suppliers Table
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        email TEXT,
        pendingDues REAL NOT NULL DEFAULT 0.0,
        paidAmount REAL NOT NULL DEFAULT 0.0,
        notes TEXT
      )
    ''');

    // Supplier Transactions Table
    await db.execute('''
      CREATE TABLE supplier_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        productsPurchased TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        costPrice REAL NOT NULL,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        dueAmount REAL NOT NULL,
        transactionDate TEXT NOT NULL,
        attachmentPath TEXT,
        notes TEXT,
        FOREIGN KEY (supplierId) REFERENCES suppliers (id) ON DELETE CASCADE
      )
    ''');

    // Seed data
    await _seedDatabase(db);
  }

  Future<void> resetDatabase() async {
    if (kIsWeb) {
      _webProducts.clear();
      _webOrders.clear();
      _webCustomers.clear();
      _webExpenses.clear();
      _webCategories.clear();
      _webSuppliers.clear();
      _webSupplierTransactions.clear();

      _webProducts.addAll(_getSeedProducts());
      _webCustomers.addAll(_getSeedCustomers());
      _webOrders.addAll(_getSeedOrders());
      _webExpenses.addAll(_getSeedExpenses());
      _webCategories.addAll(_getSeedCategories());
      _webSuppliers.addAll(_getSeedSuppliers());
      _webSupplierTransactions.addAll(_getSeedSupplierTransactions());
      return;
    }
    final db = await database;
    await db.delete('products');
    await db.delete('orders');
    await db.delete('customers');
    await db.delete('expenses');
    await db.delete('categories');
    await db.delete('suppliers');
    await db.delete('supplier_transactions');
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    // Seed Categories
    final categories = _getSeedCategories();
    for (var cat in categories) {
      await db.insert('categories', {'name': cat});
    }

    // Seed Products
    final products = _getSeedProducts();
    for (var p in products) {
      await db.insert('products', p.toMap());
    }

    // Seed Customers
    final customers = _getSeedCustomers();
    for (var c in customers) {
      await db.insert('customers', c.toMap());
    }

    // Seed Orders
    final orders = _getSeedOrders();
    for (var o in orders) {
      await db.insert('orders', o.toMap());
    }

    // Seed Expenses
    final expenses = _getSeedExpenses();
    for (var e in expenses) {
      await db.insert('expenses', e.toMap());
    }

    // Seed Suppliers
    final suppliers = _getSeedSuppliers();
    for (var s in suppliers) {
      await db.insert('suppliers', s.toMap());
    }

    // Seed Supplier Transactions
    final transactions = _getSeedSupplierTransactions();
    for (var t in transactions) {
      await db.insert('supplier_transactions', t.toMap());
    }
  }

  // --- SEED GENERATORS ---
  List<Product> _getSeedProducts() => [
        Product(name: 'Black Forest Cake', price: 1250.0, stock: 18, category: 'Cakes', lowStockThreshold: 5, barcode: '789012'),
        Product(name: 'Chocolate Pastry', price: 60.0, stock: 35, category: 'Pastries', lowStockThreshold: 10, barcode: '789013'),
        Product(name: 'Veg Puff', price: 25.0, stock: 52, category: 'Pastries', lowStockThreshold: 15, barcode: 'puff'),
        Product(name: 'White Bread', price: 40.0, stock: 48, category: 'Bread', lowStockThreshold: 10, barcode: '789015'),
        Product(name: 'Milk Bread', price: 45.0, stock: 0, category: 'Bread', lowStockThreshold: 5, barcode: '789016'),
        Product(name: 'Butter Cookies', price: 120.0, stock: 18, category: 'Cookies', lowStockThreshold: 8, barcode: 'cookies'),
        Product(name: 'Pineapple Cake (1 Kg)', price: 800.0, stock: 4, category: 'Cakes', lowStockThreshold: 5, barcode: '789018'),
        Product(name: 'Red Velvet Cake (1.5 Kg)', price: 1200.0, stock: 3, category: 'Cakes', lowStockThreshold: 5, barcode: 'blackforest'),
      ];

  List<String> _getSeedCategories() => [
        'Cakes',
        'Pastries',
        'Bread',
        'Cookies',
        'Beverages',
        'Shake',
        'Juice',
        'Tea/Coffee',
        'Burger/Sandwich',
        'Ice Cream',
        'Chips',
      ];

  List<Supplier> _getSeedSuppliers() => [
        Supplier(name: 'Royal Flour Mills', phone: '9888112233', email: 'royalflour@gmail.com', pendingDues: 4500.0, paidAmount: 12000.0, notes: 'Wholesale dealer in high-grade flour'),
        Supplier(name: 'Sugar Standard Distributors', phone: '9777223344', email: 'sugarstand@gmail.com', pendingDues: 0.0, paidAmount: 8500.0, notes: 'Bulk sugar and refined syrups'),
        Supplier(name: 'Dairy Fresh Farms', phone: '9666334455', email: 'dairyfresh@gmail.com', pendingDues: 2500.0, paidAmount: 18000.0, notes: 'Fresh cream, milk and block butter'),
      ];

  List<SupplierTransaction> _getSeedSupplierTransactions() => [
        SupplierTransaction(
          supplierId: 1,
          productsPurchased: 'Premium Maida Flour (10 Bags)',
          quantity: 10,
          costPrice: 850.0,
          totalAmount: 8500.0,
          paidAmount: 4000.0,
          dueAmount: 4500.0,
          transactionDate: '2026-05-24',
          notes: 'Half payment made in cash, rest due next week',
        ),
        SupplierTransaction(
          supplierId: 2,
          productsPurchased: 'Refined Sugar (5 Bags)',
          quantity: 5,
          costPrice: 600.0,
          totalAmount: 3000.0,
          paidAmount: 3000.0,
          dueAmount: 0.0,
          transactionDate: '2026-05-23',
          notes: 'Paid fully through UPI payment',
        ),
        SupplierTransaction(
          supplierId: 3,
          productsPurchased: 'Salted Butter (50 Blocks)',
          quantity: 50,
          costPrice: 150.0,
          totalAmount: 7500.0,
          paidAmount: 5000.0,
          dueAmount: 2500.0,
          transactionDate: '2026-05-22',
          notes: '2500 balance outstanding in running account ledger',
        ),
      ];

  List<Customer> _getSeedCustomers() => [
        Customer(name: 'Neha Sharma', phone: '9876543210', loyaltyPoints: 120, pendingDues: 1250.0),
        Customer(name: 'Rahul Verma', phone: '9123456780', loyaltyPoints: 45, pendingDues: 0.0),
        Customer(name: 'Aisha Khan', phone: '9988776655', loyaltyPoints: 230, pendingDues: 2300.0),
        Customer(name: 'James David', phone: '9876501234', loyaltyPoints: 90, pendingDues: 0.0),
        Customer(name: 'Priya Patel', phone: '9090909090', loyaltyPoints: 75, pendingDues: 750.0),
      ];

  List<CakeOrder> _getSeedOrders() => [
        CakeOrder(
          id: 'ORD-00032',
          customerName: 'Neha Sharma',
          customerPhone: '9876543210',
          cakeDetails: '2 Tier Chocolate Cake (2 Kg)',
          deliveryDate: '2026-05-28',
          deliveryTime: '05:00 PM',
          totalAmount: 1600.0,
          advanceAmount: 800.0,
          status: 'Pending',
          specialInstructions: 'Add extra choco chips. Write: Happy Birthday Neha!',
          createdAt: '2026-05-25 10:00:00',
        ),
        CakeOrder(
          id: 'ORD-00031',
          customerName: 'Rahul Verma',
          customerPhone: '9123456780',
          cakeDetails: 'Pineapple Cake (1 Kg)',
          deliveryDate: '2026-05-26',
          deliveryTime: '04:00 PM',
          totalAmount: 800.0,
          advanceAmount: 500.0,
          status: 'Preparing',
          specialInstructions: 'Eggless, moderate sugar',
          createdAt: '2026-05-25 11:30:00',
        ),
        CakeOrder(
          id: 'ORD-00030',
          customerName: 'Aisha Khan',
          customerPhone: '9988776655',
          cakeDetails: 'Red Velvet Cake (1.5 Kg)',
          deliveryDate: '2026-05-25',
          deliveryTime: '02:00 PM',
          totalAmount: 1200.0,
          advanceAmount: 700.0,
          status: 'Ready',
          specialInstructions: 'Heart shaped, cream cheese icing',
          createdAt: '2026-05-24 15:00:00',
        ),
      ];

  List<Expense> _getSeedExpenses() => [
        Expense(title: 'Shop Rent', amount: 15000.0, category: 'Rent', date: '2026-05-20'),
        Expense(title: 'Electricity Bill', amount: 2450.0, category: 'Electricity', date: '2026-05-18'),
        Expense(title: 'Staff Salary (Aman)', amount: 12000.0, category: 'Salary', date: '2026-05-18'),
        Expense(title: 'Transport/Fuel', amount: 1200.0, category: 'Transport', date: '2026-05-17'),
        Expense(title: 'Other raw materials', amount: 980.0, category: 'Other', date: '2026-05-16'),
      ];

  // --- INITIALIZATION FOR WEB FALLBACK ---
  void initWebMemory() {
    if (_webProducts.isEmpty) {
      _webProducts.addAll(_getSeedProducts());
      _webCustomers.addAll(_getSeedCustomers());
      _webOrders.addAll(_getSeedOrders());
      _webExpenses.addAll(_getSeedExpenses());
      _webCategories.addAll(_getSeedCategories());
      _webSuppliers.addAll(_getSeedSuppliers());
      _webSupplierTransactions.addAll(_getSeedSupplierTransactions());
    }
  }

  // ==========================================
  // PRODUCTS CRUD
  // ==========================================
  Future<List<Product>> getProducts() async {
    if (kIsWeb) {
      initWebMemory();
      return List.from(_webProducts);
    }
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> insertProduct(Product product) async {
    if (kIsWeb) {
      initWebMemory();
      final id = _webProducts.length + 1;
      final newProduct = product.copyWith(id: id);
      _webProducts.add(newProduct);
      return id;
    }
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    if (kIsWeb) {
      initWebMemory();
      final idx = _webProducts.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        _webProducts[idx] = product;
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    if (kIsWeb) {
      initWebMemory();
      _webProducts.removeWhere((p) => p.id == id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // ORDERS CRUD
  // ==========================================
  Future<List<CakeOrder>> getOrders() async {
    if (kIsWeb) {
      initWebMemory();
      return List.from(_webOrders);
    }
    final db = await instance.database;
    final result = await db.query('orders', orderBy: 'createdAt DESC');
    return result.map((json) => CakeOrder.fromMap(json)).toList();
  }

  Future<int> insertOrder(CakeOrder order) async {
    if (kIsWeb) {
      initWebMemory();
      _webOrders.insert(0, order);
      return 1;
    }
    final db = await instance.database;
    return await db.insert('orders', order.toMap());
  }

  Future<int> updateOrder(CakeOrder order) async {
    if (kIsWeb) {
      initWebMemory();
      final idx = _webOrders.indexWhere((o) => o.id == order.id);
      if (idx != -1) {
        _webOrders[idx] = order;
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // ==========================================
  // CUSTOMERS CRUD
  // ==========================================
  Future<List<Customer>> getCustomers() async {
    if (kIsWeb) {
      initWebMemory();
      return List.from(_webCustomers);
    }
    final db = await instance.database;
    final result = await db.query('customers');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    if (kIsWeb) {
      initWebMemory();
      final id = _webCustomers.length + 1;
      final newCustomer = customer.copyWith(id: id);
      _webCustomers.add(newCustomer);
      return id;
    }
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    if (kIsWeb) {
      initWebMemory();
      final idx = _webCustomers.indexWhere((c) => c.id == customer.id);
      if (idx != -1) {
        _webCustomers[idx] = customer;
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // ==========================================
  // EXPENSES CRUD
  // ==========================================
  Future<List<Expense>> getExpenses() async {
    if (kIsWeb) {
      initWebMemory();
      return List.from(_webExpenses);
    }
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) {
      initWebMemory();
      final id = _webExpenses.length + 1;
      final newExpense = expense.copyWith(id: id);
      _webExpenses.insert(0, newExpense);
      return id;
    }
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  // ==========================================
  // CATEGORIES CRUD
  // ==========================================
  Future<List<String>> getCategories() async {
    if (kIsWeb) {
      initWebMemory();
      return List.from(_webCategories);
    }
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<int> insertCategory(String name) async {
    if (kIsWeb) {
      initWebMemory();
      if (!_webCategories.contains(name)) {
        _webCategories.add(name);
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    try {
      return await db.insert('categories', {'name': name});
    } catch (e) {
      return 0;
    }
  }

  // ==========================================
  // SUPPLIERS CRUD
  // ==========================================
  Future<List<Supplier>> getSuppliers() async {
    if (kIsWeb) {
      initWebMemory();
      return List.from(_webSuppliers);
    }
    final db = await instance.database;
    final result = await db.query('suppliers');
    return result.map((json) => Supplier.fromMap(json)).toList();
  }

  Future<int> insertSupplier(Supplier supplier) async {
    if (kIsWeb) {
      initWebMemory();
      final id = _webSuppliers.length + 1;
      final newSupplier = supplier.copyWith(id: id);
      _webSuppliers.add(newSupplier);
      return id;
    }
    final db = await instance.database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<int> updateSupplier(Supplier supplier) async {
    if (kIsWeb) {
      initWebMemory();
      final idx = _webSuppliers.indexWhere((s) => s.id == supplier.id);
      if (idx != -1) {
        _webSuppliers[idx] = supplier;
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    if (kIsWeb) {
      initWebMemory();
      _webSuppliers.removeWhere((s) => s.id == id);
      _webSupplierTransactions.removeWhere((t) => t.supplierId == id);
      return 1;
    }
    final db = await instance.database;
    await db.delete('supplier_transactions', where: 'supplierId = ?', whereArgs: [id]);
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // SUPPLIER TRANSACTIONS CRUD
  // ==========================================
  Future<List<SupplierTransaction>> getSupplierTransactions() async {
    if (kIsWeb) {
      initWebMemory();
      return List.from(_webSupplierTransactions);
    }
    final db = await instance.database;
    final result = await db.query('supplier_transactions', orderBy: 'transactionDate DESC');
    return result.map((json) => SupplierTransaction.fromMap(json)).toList();
  }

  Future<int> insertSupplierTransaction(SupplierTransaction transaction) async {
    if (kIsWeb) {
      initWebMemory();
      final id = _webSupplierTransactions.length + 1;
      final newTrans = transaction.copyWith(id: id);
      _webSupplierTransactions.insert(0, newTrans);

      // Update supplier running balances dynamically in memory
      final supIdx = _webSuppliers.indexWhere((s) => s.id == transaction.supplierId);
      if (supIdx != -1) {
        final s = _webSuppliers[supIdx];
        _webSuppliers[supIdx] = s.copyWith(
          pendingDues: s.pendingDues + transaction.dueAmount,
          paidAmount: s.paidAmount + transaction.paidAmount,
        );
      }
      return id;
    }
    final db = await instance.database;
    
    // Perform double-ledger dynamic balance updates under a single atomic SQLite transaction
    return await db.transaction((txn) async {
      final id = await txn.insert('supplier_transactions', transaction.toMap());
      
      final list = await txn.query('suppliers', where: 'id = ?', whereArgs: [transaction.supplierId]);
      if (list.isNotEmpty) {
        final s = Supplier.fromMap(list.first);
        await txn.update(
          'suppliers',
          s.copyWith(
            pendingDues: s.pendingDues + transaction.dueAmount,
            paidAmount: s.paidAmount + transaction.paidAmount,
          ).toMap(),
          where: 'id = ?',
          whereArgs: [s.id],
        );
      }
      return id;
    });
  }
}

// =========================================================================
// DECOUPLED FIREBASE SYNC HOOK INTERFACE
// =========================================================================
class FirebaseSyncHelper {
  // Sync local changes to cloud
  static Future<bool> syncLocalToCloud() async {
    try {
      // 1. Fetch all local unsynced records
      // 2. Format as documents for Firestore
      // 3. Perform batch write: firestoreInstance.batch().set(...)
      // 4. Return success state
      await Future.delayed(const Duration(seconds: 1)); // simulated sync network latency
      return true; 
    } catch (e) {
      return false;
    }
  }

  // Pull latest updates from Cloud
  static Future<bool> syncCloudToLocal() async {
    try {
      // 1. Fetch latest changes from Firestore
      // 2. Iterate and update local SQLite engine using insert/update CRUD methods
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
}
