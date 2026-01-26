import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../constants/app_constants.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  String? _dbPath;
  static const _dbFileName = 'turbopizza.db';
  static const _migrationMetaKey = 'migrated_from_prefs';

  Future<void> init({String? overridePath, bool skipMigration = false}) async {
    if (_db != null) return;

    // Init FFI for desktop targets
    sqfliteFfiInit();
    final dbFactory = databaseFactoryFfi;

    if (overridePath != null) {
      _dbPath = overridePath;
      await Directory(p.dirname(overridePath)).create(recursive: true);
    } else {
      final supportDir = await getApplicationSupportDirectory();
      final dbPath = p.join(supportDir.path, _dbFileName);
      await Directory(supportDir.path).create(recursive: true);
      _dbPath = dbPath;
    }

    _db = await _openDatabase(dbFactory, _dbPath!);

    if (!skipMigration) {
      await _maybeMigrateFromPrefs();
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

  String get databasePath => _dbPath ?? '';

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

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

  Future<void> _maybeMigrateFromPrefs() async {
    final db = _db!;
    final existing = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: [_migrationMetaKey],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // Legacy loads from SharedPreferences
    final legacyPizzas = await _loadLegacyPizzas(prefs);
    final legacyPayments = await _loadLegacyPayments(prefs);
    final legacyPending = await _loadLegacyPendingOrders(prefs);

    await db.transaction((txn) async {
      // Products
      for (final pizza in legacyPizzas) {
        await txn.insert(
          'products',
          {
            'name': pizza.name,
            'price': pizza.price,
            'type': pizza.type,
            'active': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Payments + items
      for (final payment in legacyPayments) {
        final paymentId = await txn.insert('payments', {
          'date': payment.date.toIso8601String(),
          'amount': payment.amount,
          'payment_method': payment.paymentMethod,
        });
        for (final item in payment.items) {
          await txn.insert('payment_items', {
            'payment_id': paymentId,
            'name': item.name,
            'type': item.type,
            'unit_price': item.price,
            'quantity': item.quantity,
          });
        }
      }

      // Pending orders + items
      for (final order in legacyPending) {
        await txn.insert('pending_orders', {
          'id': order.id,
          'created_at': order.createdAt.toIso8601String(),
          'planned_pickup': order.plannedPickupTime,
          'amount': order.amount,
        });
        for (final item in order.items) {
          await txn.insert('pending_order_items', {
            'order_id': order.id,
            'name': item.name,
            'type': item.type,
            'unit_price': item.price,
            'quantity': item.quantity,
          });
        }
      }

      await txn.insert('meta', {
        'key': _migrationMetaKey,
        'value': '1',
      });
    });
  }

  Future<List<Pizza>> _loadLegacyPizzas(SharedPreferences prefs) async {
    final pizzaJson = prefs.getStringList(AppConstants.spKeyPizzas);
    try {
      return pizzaJson
              ?.map((s) {
                final decoded = jsonDecodeSafe(s);
                if (decoded == null) return null;
                return Pizza.fromJson(decoded);
              })
              .whereType<Pizza>()
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Payment>> _loadLegacyPayments(SharedPreferences prefs) async {
    final paymentsJson = prefs.getStringList(AppConstants.spKeyPayments);
    try {
      return paymentsJson
              ?.map((s) {
                final decoded = jsonDecodeSafe(s);
                if (decoded == null) return null;
                return Payment.fromJson(decoded);
              })
              .whereType<Payment>()
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  Future<List<PendingOrder>> _loadLegacyPendingOrders(
      SharedPreferences prefs) async {
    final pendingJson = prefs.getStringList(AppConstants.spKeyPendingOrders);
    try {
      return pendingJson
              ?.map((s) {
                final decoded = jsonDecodeSafe(s);
                if (decoded == null) return null;
                return PendingOrder.fromJson(decoded);
              })
              .whereType<PendingOrder>()
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  // Products
  Future<List<Pizza>> fetchProducts({bool includeInactive = false}) async {
    final db = _db!;
    final rows = await db.query(
      'products',
      where: includeInactive ? null : 'active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows
        .map((r) => Pizza(
              name: r['name'] as String,
              price: (r['price'] as num).toDouble(),
              quantity: 0,
              type: r['type'] as String,
            ))
        .toList();
  }

  Future<void> replaceProducts(List<Pizza> pizzas) async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (final pizza in pizzas) {
        await txn.insert('products', {
          'name': pizza.name,
          'price': pizza.price,
          'type': pizza.type,
          'active': 1,
        });
      }
    });
  }

  // Payments
  Future<void> insertPayment(Payment payment) async {
    final db = _db!;
    await db.transaction((txn) async {
      final paymentId = await txn.insert('payments', {
        'date': payment.date.toIso8601String(),
        'amount': payment.amount,
        'payment_method': payment.paymentMethod,
      });
      for (final item in payment.items) {
        await txn.insert('payment_items', {
          'payment_id': paymentId,
          'name': item.name,
          'type': item.type,
          'unit_price': item.price,
          'quantity': item.quantity,
        });
      }
    });
  }

  Future<void> replacePayments(List<Payment> payments) async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.delete('payment_items');
      await txn.delete('payments');
      for (final payment in payments) {
        final paymentId = await txn.insert('payments', {
          'date': payment.date.toIso8601String(),
          'amount': payment.amount,
          'payment_method': payment.paymentMethod,
        });
        for (final item in payment.items) {
          await txn.insert('payment_items', {
            'payment_id': paymentId,
            'name': item.name,
            'type': item.type,
            'unit_price': item.price,
            'quantity': item.quantity,
          });
        }
      }
    });
  }

  Future<List<Payment>> fetchPayments() async {
    final db = _db!;
    final paymentsRows = await db.query('payments', orderBy: 'date DESC');
    final itemsRows = await db.query('payment_items');

    final itemsByPayment = <int, List<Pizza>>{};
    for (final row in itemsRows) {
      final pid = row['payment_id'] as int;
      itemsByPayment.putIfAbsent(pid, () => []).add(
            Pizza(
              name: row['name'] as String,
              price: (row['unit_price'] as num).toDouble(),
              quantity: row['quantity'] as int,
              type: row['type'] as String,
            ),
          );
    }

    return paymentsRows.map((r) {
      final id = r['id'] as int;
      return Payment(
        date: DateTime.parse(r['date'] as String),
        amount: (r['amount'] as num).toDouble(),
        paymentMethod: r['payment_method'] as String,
        items: itemsByPayment[id] ?? const [],
        isSelected: false,
      );
    }).toList();
  }

  Future<List<Payment>> fetchPaymentsBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final db = _db!;
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final paymentsRows = await db.query(
      'payments',
      where: 'date >= ? AND date < ?',
      whereArgs: [startIso, endIso],
      orderBy: 'date ASC',
    );

    final ids = paymentsRows.map((r) => r['id'] as int).toList();
    Map<int, List<Pizza>> itemsByPayment = {};
    if (ids.isNotEmpty) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final itemsRows = await db.query(
        'payment_items',
        where: 'payment_id IN ($placeholders)',
        whereArgs: ids,
      );
      for (final row in itemsRows) {
        final pid = row['payment_id'] as int;
        itemsByPayment.putIfAbsent(pid, () => []).add(
              Pizza(
                name: row['name'] as String,
                price: (row['unit_price'] as num).toDouble(),
                quantity: row['quantity'] as int,
                type: row['type'] as String,
              ),
            );
      }
    }

    return paymentsRows.map((r) {
      final id = r['id'] as int;
      return Payment(
        date: DateTime.parse(r['date'] as String),
        amount: (r['amount'] as num).toDouble(),
        paymentMethod: r['payment_method'] as String,
        items: itemsByPayment[id] ?? const [],
        isSelected: false,
      );
    }).toList();
  }

  // Pending orders
  Future<void> savePendingOrder(PendingOrder order) async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.delete('pending_orders', where: 'id = ?', whereArgs: [order.id]);
      await txn.delete('pending_order_items', where: 'order_id = ?', whereArgs: [order.id]);

      await txn.insert('pending_orders', {
        'id': order.id,
        'created_at': order.createdAt.toIso8601String(),
        'planned_pickup': order.plannedPickupTime,
        'amount': order.amount,
      });

      for (final item in order.items) {
        await txn.insert('pending_order_items', {
          'order_id': order.id,
          'name': item.name,
          'type': item.type,
          'unit_price': item.price,
          'quantity': item.quantity,
        });
      }
    });
  }

  Future<List<PendingOrder>> fetchPendingOrders() async {
    final db = _db!;
    final ordersRows = await db.query('pending_orders', orderBy: 'planned_pickup ASC');
    final itemsRows = await db.query('pending_order_items');

    final itemsByOrder = <String, List<Pizza>>{};
    for (final row in itemsRows) {
      final oid = row['order_id'] as String;
      itemsByOrder.putIfAbsent(oid, () => []).add(
            Pizza(
              name: row['name'] as String,
              price: (row['unit_price'] as num).toDouble(),
              quantity: row['quantity'] as int,
              type: row['type'] as String,
            ),
          );
    }

    return ordersRows.map((r) {
      final id = r['id'] as String;
      return PendingOrder(
        id: id,
        createdAt: DateTime.parse(r['created_at'] as String),
        plannedPickupTime: r['planned_pickup'] as String,
        items: itemsByOrder[id] ?? const [],
        amount: (r['amount'] as num).toDouble(),
      );
    }).toList();
  }

  Future<void> removePendingOrder(String orderId) async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.delete('pending_order_items', where: 'order_id = ?', whereArgs: [orderId]);
      await txn.delete('pending_orders', where: 'id = ?', whereArgs: [orderId]);
    });
  }

  Future<void> replacePendingOrders(List<PendingOrder> orders) async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.delete('pending_order_items');
      await txn.delete('pending_orders');
      for (final order in orders) {
        await txn.insert('pending_orders', {
          'id': order.id,
          'created_at': order.createdAt.toIso8601String(),
          'planned_pickup': order.plannedPickupTime,
          'amount': order.amount,
        });
        for (final item in order.items) {
          await txn.insert('pending_order_items', {
            'order_id': order.id,
            'name': item.name,
            'type': item.type,
            'unit_price': item.price,
            'quantity': item.quantity,
          });
        }
      }
    });
  }

  Future<void> exportDatabase(String destinationPath) async {
    await init();
    final src = File(databasePath);
    await File(destinationPath).parent.create(recursive: true);
    await src.copy(destinationPath);
  }

  Future<void> importDatabase(String sourcePath) async {
    if (_dbPath == null) {
      await init();
    }
    final dbFactory = databaseFactoryFfi;
    final dst = File(databasePath);
    await _db?.close();
    _db = null;
    await dst.parent.create(recursive: true);
    await File(sourcePath).copy(dst.path);
    _db = await _openDatabase(dbFactory, dst.path);
  }
}

// Safe JSON decode that tolerates errors
Map<String, dynamic>? jsonDecodeSafe(String source) {
  try {
    return json.decode(source) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
