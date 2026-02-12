import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';
import '../repositories/product_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/pending_order_repository.dart';
import 'migration_service.dart';

/// Central database service managing SQLite database and repositories.
/// 
/// This service is responsible for database initialization and providing
/// access to repositories. All data access should go through the repositories.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  String? _dbPath;
  static const _dbFileName = 'turbopizza.db';

  ProductRepository? _productRepository;
  PaymentRepository? _paymentRepository;
  PendingOrderRepository? _pendingOrderRepository;

  /// Initializes the database and sets up repositories.
  /// 
  /// [overridePath] can be used for testing to specify a custom database path.
  /// [skipMigration] prevents automatic migration from SharedPreferences.
  Future<void> init({String? overridePath, bool skipMigration = false}) async {
    if (_db != null) return;

    // Initialize FFI for desktop targets
    sqfliteFfiInit();
    final dbFactory = databaseFactoryFfi;

    // Determine database path
    if (overridePath != null) {
      _dbPath = overridePath;
      await Directory(p.dirname(overridePath)).create(recursive: true);
    } else {
      final supportDir = await getApplicationSupportDirectory();
      final dbPath = p.join(supportDir.path, _dbFileName);
      await Directory(supportDir.path).create(recursive: true);
      _dbPath = dbPath;
    }

    // Open database
    _db = await _openDatabase(dbFactory, _dbPath!);

    // Initialize repositories
    _productRepository = ProductRepository(_db!);
    _paymentRepository = PaymentRepository(_db!);
    _pendingOrderRepository = PendingOrderRepository(_db!);

    // Run migration if needed
    if (!skipMigration) {
      final migrationService = MigrationService(_db!);
      await migrationService.migrateFromPrefsIfNeeded();
    }
  }

  Future<Database> _openDatabase(DatabaseFactory dbFactory, String path) {
    return dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
      ),
    );
  }

  /// Returns the absolute path to the database file.
  String get databasePath => _dbPath ?? '';

  /// Closes the database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _productRepository = null;
    _paymentRepository = null;
    _pendingOrderRepository = null;
  }

  /// Returns the database instance.
  /// 
  /// Throws an exception if the database has not been initialized.
  Database get database {
    if (_db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  // ============================================================
  // Repository Accessors
  // ============================================================

  /// Returns the product repository.
  /// 
  /// Throws an exception if the database has not been initialized.
  ProductRepository get products {
    if (_productRepository == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _productRepository!;
  }

  /// Returns the payment repository.
  /// 
  /// Throws an exception if the database has not been initialized.
  PaymentRepository get payments {
    if (_paymentRepository == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _paymentRepository!;
  }

  /// Returns the pending order repository.
  /// 
  /// Throws an exception if the database has not been initialized.
  PendingOrderRepository get pendingOrders {
    if (_pendingOrderRepository == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _pendingOrderRepository!;
  }

  // ============================================================
  // Legacy compatibility methods (delegate to repositories)
  // ============================================================

  /// @deprecated Use `DatabaseService.instance.products.fetchProducts()` instead.
  Future<List<Pizza>> fetchProducts({bool includeInactive = false}) async {
    return products.fetchProducts(includeInactive: includeInactive);
  }

  /// @deprecated Use `DatabaseService.instance.products.replaceProducts()` instead.
  Future<void> replaceProducts(List<Pizza> pizzas) async {
    return products.replaceProducts(pizzas);
  }

  /// @deprecated Use `DatabaseService.instance.payments.insertPayment()` instead.
  Future<void> insertPayment(Payment payment) async {
    return payments.insertPayment(payment);
  }

  /// @deprecated Use `DatabaseService.instance.payments.replacePayments()` instead.
  Future<void> replacePayments(List<Payment> paymentList) async {
    return payments.replacePayments(paymentList);
  }

  /// @deprecated Use `DatabaseService.instance.payments.fetchPayments()` instead.
  Future<List<Payment>> fetchPayments() async {
    return payments.fetchPayments();
  }

  /// @deprecated Use `DatabaseService.instance.payments.fetchPaymentsBetween()` instead.
  Future<List<Payment>> fetchPaymentsBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    return payments.fetchPaymentsBetween(
      start: start,
      endExclusive: endExclusive,
    );
  }

  /// @deprecated Use `DatabaseService.instance.pendingOrders.savePendingOrder()` instead.
  Future<void> savePendingOrder(PendingOrder order) async {
    return pendingOrders.savePendingOrder(order);
  }

  /// @deprecated Use `DatabaseService.instance.pendingOrders.fetchPendingOrders()` instead.
  Future<List<PendingOrder>> fetchPendingOrders() async {
    return pendingOrders.fetchPendingOrders();
  }

  /// @deprecated Use `DatabaseService.instance.pendingOrders.removePendingOrder()` instead.
  Future<void> removePendingOrder(String orderId) async {
    return pendingOrders.removePendingOrder(orderId);
  }

  /// @deprecated Use `DatabaseService.instance.pendingOrders.replacePendingOrders()` instead.
  Future<void> replacePendingOrders(List<PendingOrder> orders) async {
    return pendingOrders.replacePendingOrders(orders);
  }

  // ============================================================
  // Database Schema
  // ============================================================

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE meta (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        price REAL NOT NULL,
        type TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_payments_date ON payments(date);');
    await db.execute('CREATE INDEX idx_payments_method ON payments(payment_method);');

    await db.execute('''
      CREATE TABLE payment_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payment_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY(payment_id) REFERENCES payments(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE pending_orders (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        planned_pickup TEXT NOT NULL,
        amount REAL NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE pending_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY(order_id) REFERENCES pending_orders(id) ON DELETE CASCADE
      );
    ''');
  }

  // ============================================================
  // Database Export/Import
  // ============================================================

  /// Exports the database to a file.
  /// 
  /// The database file will be copied to the specified [destinationPath].
  Future<void> exportDatabase(String destinationPath) async {
    await init();
    final src = File(databasePath);
    await File(destinationPath).parent.create(recursive: true);
    await src.copy(destinationPath);
  }

  /// Imports a database from a file.
  /// 
  /// The current database will be replaced with the one at [sourcePath].
  /// An automatic backup of the current database is created before import.
  /// The database connection will be reopened after import.
  /// 
  /// Returns the path to the backup file created.
  Future<String> importDatabase(String sourcePath, {bool createBackup = true}) async {
    if (_dbPath == null) {
      await init();
    }

    final dbFactory = databaseFactoryFfi;
    final dst = File(databasePath);
    
    // Create automatic backup before import
    String? backupPath;
    if (createBackup && await dst.exists()) {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      backupPath = '$databasePath.backup_$timestamp';
      await dst.copy(backupPath);
      debugPrint('[DatabaseService] 💾 Backup créé: $backupPath');
    }

    // Close current database
    await _db?.close();
    _db = null;

    // Import new database
    await dst.parent.create(recursive: true);
    await File(sourcePath).copy(dst.path);
    debugPrint('[DatabaseService] ✅ Base de données importée depuis: $sourcePath');

    // Reopen database
    _db = await _openDatabase(dbFactory, dst.path);

    // Reinitialize repositories with new database
    _productRepository = ProductRepository(_db!);
    _paymentRepository = PaymentRepository(_db!);
    _pendingOrderRepository = PendingOrderRepository(_db!);

    return backupPath ?? 'no_backup';
  }

  /// Restores a database from a backup file.
  /// 
  /// This is a shortcut for importDatabase that doesn't create another backup.
  Future<void> restoreFromBackup(String backupPath) async {
    await importDatabase(backupPath, createBackup: false);
  }
}
