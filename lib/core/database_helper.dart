import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web Fallback Memory Cache
  final List<Product> _webProducts = [];
  final List<CakeOrder> _webOrders = [];
  final List<Customer> _webCustomers = [];
  final List<Expense> _webExpenses = [];

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
    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT,
        lowStockThreshold INTEGER NOT NULL DEFAULT 5
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

    // Seed data
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
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
  }

  // --- SEED GENERATORS ---
  List<Product> _getSeedProducts() => [
        Product(name: 'Black Forest Cake', price: 1250.0, stock: 18, category: 'Cakes', lowStockThreshold: 5),
        Product(name: 'Chocolate Pastry', price: 60.0, stock: 35, category: 'Pastries', lowStockThreshold: 10),
        Product(name: 'Veg Puff', price: 25.0, stock: 52, category: 'Pastries', lowStockThreshold: 15),
        Product(name: 'White Bread', price: 40.0, stock: 48, category: 'Bread', lowStockThreshold: 10),
        Product(name: 'Milk Bread', price: 45.0, stock: 0, category: 'Bread', lowStockThreshold: 5),
        Product(name: 'Butter Cookies', price: 120.0, stock: 18, category: 'Cookies', lowStockThreshold: 8),
        Product(name: 'Pineapple Cake (1 Kg)', price: 800.0, stock: 4, category: 'Cakes', lowStockThreshold: 5),
        Product(name: 'Red Velvet Cake (1.5 Kg)', price: 1200.0, stock: 3, category: 'Cakes', lowStockThreshold: 5),
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
