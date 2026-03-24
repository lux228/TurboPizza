import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';
import '../repositories/product_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/pending_order_repository.dart';
import '../utils/payment_fingerprint.dart';
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
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );
  static final Uuid _uuid = Uuid();

  static bool _looksLikeUuid(String value) {
    return value.length == 36 && _uuidPattern.hasMatch(value);
  }

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

    // One-shot compatibility migration: convert legacy pending order IDs to UUID.
    await _migrateLegacyPendingOrderIdsToUuid(_db!);
  }

  Future<Database> _openDatabase(DatabaseFactory dbFactory, String path) {
    return dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _migrateToV2(db);
          }
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

  /// @deprecated Use `DatabaseService.instance.payments.fetchPaymentsPage()` instead.
  Future<List<Payment>> fetchPaymentsPage({
    required DateTime start,
    required DateTime endExclusive,
    required int limit,
    required int offset,
  }) async {
    return payments.fetchPaymentsPage(
      start: start,
      endExclusive: endExclusive,
      limit: limit,
      offset: offset,
    );
  }

  /// @deprecated Use `DatabaseService.instance.payments.fetchTotalsByMethodBetween()` instead.
  Future<Map<String, double>> fetchPaymentTotalsByMethodBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    return payments.fetchTotalsByMethodBetween(
      start: start,
      endExclusive: endExclusive,
    );
  }

  /// @deprecated Use `DatabaseService.instance.payments.fetchTotalAmountBetween()` instead.
  Future<double> fetchPaymentTotalAmountBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    return payments.fetchTotalAmountBetween(
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
        payment_method TEXT NOT NULL,
        fingerprint TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_payments_date ON payments(date);');
    await db.execute(
      'CREATE INDEX idx_payments_method ON payments(payment_method);',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_payments_fingerprint ON payments(fingerprint);',
    );

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
    await db.execute(
      'CREATE INDEX idx_payment_items_payment_id ON payment_items(payment_id);',
    );

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

  Future<void> _migrateToV2(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(payments);');
    final hasFingerprint = columns.any((row) => row['name'] == 'fingerprint');
    if (!hasFingerprint) {
      await db.execute('ALTER TABLE payments ADD COLUMN fingerprint TEXT;');
    }

    final rows = await db.rawQuery('''
      SELECT
        p.id AS payment_id,
        p.date,
        p.amount,
        p.payment_method,
        i.id AS item_id,
        i.name,
        i.type,
        i.unit_price,
        i.quantity
      FROM payments p
      LEFT JOIN payment_items i ON i.payment_id = p.id
      ORDER BY p.date DESC, p.id DESC, i.id ASC
    ''');

    final paymentsById = <int, Payment>{};
    final ordered = <Payment>[];

    for (final row in rows) {
      final paymentId = row['payment_id'] as int;
      var payment = paymentsById[paymentId];
      if (payment == null) {
        payment = Payment(
          id: paymentId,
          date: DateTime.parse(row['date'] as String),
          amount: (row['amount'] as num).toDouble(),
          paymentMethod: row['payment_method'] as String,
          items: [],
          isSelected: false,
        );
        paymentsById[paymentId] = payment;
        ordered.add(payment);
      }

      final itemId = row['item_id'] as int?;
      if (itemId != null) {
        payment.items.add(
          Pizza(
            name: row['name'] as String,
            price: (row['unit_price'] as num).toDouble(),
            quantity: row['quantity'] as int,
            type: row['type'] as String,
          ),
        );
      }
    }

    final seen = <String, int>{};
    final duplicates = <int>[];

    for (final payment in ordered) {
      final fingerprint = buildPaymentFingerprint(payment);
      final id = payment.id!;
      if (seen.containsKey(fingerprint)) {
        duplicates.add(id);
        continue;
      }
      seen[fingerprint] = id;
      await db.update(
        'payments',
        {'fingerprint': fingerprint},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    for (final id in duplicates) {
      await db.delete(
        'payment_items',
        where: 'payment_id = ?',
        whereArgs: [id],
      );
      await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    }

    if (duplicates.isNotEmpty) {
      await db.insert('meta', {
        'key': 'db_payment_duplicates_removed',
        'value': json.encode({
          'count': duplicates.length,
          'date': DateTime.now().toIso8601String(),
        }),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_fingerprint ON payments(fingerprint);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payment_items_payment_id ON payment_items(payment_id);',
    );
  }

  Future<void> _migrateLegacyPendingOrderIdsToUuid(Database db) async {
    final orderRows = await db.query(
      'pending_orders',
      columns: ['id', 'created_at', 'planned_pickup', 'amount'],
    );

    if (orderRows.isEmpty) return;

    final legacyRows = orderRows
        .where((row) => !_looksLikeUuid(row['id'] as String))
        .toList();

    if (legacyRows.isEmpty) return;

    final existingIds = orderRows.map((row) => row['id'] as String).toSet();

    await db.transaction((txn) async {
      for (final row in legacyRows) {
        final oldId = row['id'] as String;

        var newId = _uuid.v4();
        while (existingIds.contains(newId)) {
          newId = _uuid.v4();
        }
        existingIds.add(newId);

        await txn.insert('pending_orders', {
          'id': newId,
          'created_at': row['created_at'],
          'planned_pickup': row['planned_pickup'],
          'amount': row['amount'],
        });

        await txn.update(
          'pending_order_items',
          {'order_id': newId},
          where: 'order_id = ?',
          whereArgs: [oldId],
        );

        await txn.delete('pending_orders', where: 'id = ?', whereArgs: [oldId]);
      }
    });

    debugPrint(
      '[DatabaseService] IDs legacy pending_orders migrés vers UUID: ${legacyRows.length}',
    );
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
  Future<String> importDatabase(
    String sourcePath, {
    bool createBackup = true,
  }) async {
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
    debugPrint(
      '[DatabaseService] ✅ Base de données importée depuis: $sourcePath',
    );

    // Reopen database
    _db = await _openDatabase(dbFactory, dst.path);

    // Ensure imported DB also uses UUID IDs for pending orders.
    await _migrateLegacyPendingOrderIdsToUuid(_db!);

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
