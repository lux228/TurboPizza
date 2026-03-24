import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../constants/app_storage_keys.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';
import '../utils/payment_fingerprint.dart';

/// Statistics about migration from SharedPreferences to SQLite.
class MigrationStats {
  final int productsCount;
  final int paymentsCount;
  final int pendingOrdersCount;
  final DateTime migrationDate;

  MigrationStats({
    required this.productsCount,
    required this.paymentsCount,
    required this.pendingOrdersCount,
    required this.migrationDate,
  });

  @override
  String toString() {
    return 'Migration: $productsCount produits, $paymentsCount paiements, '
        '$pendingOrdersCount commandes (${migrationDate.toIso8601String()})';
  }
}

/// Service responsible for migrating data from SharedPreferences to SQLite.
class MigrationService {
  static const _migrationMetaKey = 'migrated_from_prefs';
  static const _migrationStatsKey = 'migration_stats';
  static const _migrationDuplicatesKey = 'migration_payment_duplicates';

  final Database db;

  MigrationService(this.db);

  /// Checks if migration from SharedPreferences has already been performed.
  Future<bool> isMigrationCompleted() async {
    final existing = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: [_migrationMetaKey],
      limit: 1,
    );
    return existing.isNotEmpty;
  }

  /// Migrates data from SharedPreferences to SQLite intelligently.
  ///
  /// This operation merges legacy data with existing SQLite data without creating duplicates:
  /// - Products: UPSERT based on name
  /// - Payments: Skip exact duplicates (same date, amount, method)
  /// - Pending orders: UPSERT based on order ID
  ///
  /// Returns migration statistics if any data was migrated, null if:
  /// - Migration was already completed
  /// - No legacy data found
  Future<MigrationStats?> migrateFromPrefsIfNeeded() async {
    // Check if migration was already completed
    if (await isMigrationCompleted()) {
      debugPrint('[Migration] Déjà effectuée, ignore.');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    // Load legacy data from SharedPreferences
    final legacyPizzas = await _loadLegacyPizzas(prefs);
    final legacyPayments = await _loadLegacyPayments(prefs);
    final legacyPending = await _loadLegacyPendingOrders(prefs);

    // Check if there's any legacy data to migrate
    if (legacyPizzas.isEmpty &&
        legacyPayments.isEmpty &&
        legacyPending.isEmpty) {
      debugPrint(
        '[Migration] Aucune donnée legacy trouvée dans SharedPreferences.',
      );

      // Mark as completed even if no data (to avoid checking every time)
      await _markMigrationCompleted(0, 0, 0);
      return null;
    }

    debugPrint(
      '[Migration] Début de la migration intelligente depuis SharedPreferences...',
    );
    debugPrint(
      '[Migration] Trouvé: ${legacyPizzas.length} produits, '
      '${legacyPayments.length} paiements, ${legacyPending.length} commandes',
    );

    int migratedProducts = 0;
    int migratedPayments = 0;
    int migratedPendingOrders = 0;
    int duplicatePaymentsSkipped = 0;

    // Migrate all data in a single transaction
    await db.transaction((txn) async {
      // Migrate products (UPSERT based on name)
      for (final pizza in legacyPizzas) {
        final existing = await txn.query(
          'products',
          where: 'name = ?',
          whereArgs: [pizza.name],
          limit: 1,
        );

        if (existing.isEmpty) {
          await txn.insert('products', {
            'name': pizza.name,
            'price': pizza.price,
            'type': pizza.type,
            'active': 1,
          });
          migratedProducts++;
        } else {
          // Product exists, update price/type if different
          final existingProduct = existing.first;
          if (existingProduct['price'] != pizza.price ||
              existingProduct['type'] != pizza.type) {
            await txn.update(
              'products',
              {'price': pizza.price, 'type': pizza.type},
              where: 'name = ?',
              whereArgs: [pizza.name],
            );
            debugPrint('[Migration] Produit "${pizza.name}" mis à jour');
          }
        }
      }

      // Migrate payments (avoid exact duplicates)
      for (final payment in legacyPayments) {
        final fingerprint = buildPaymentFingerprint(payment);
        // Check if a payment with same fingerprint already exists
        final duplicates = await txn.query(
          'payments',
          where: 'fingerprint = ?',
          whereArgs: [fingerprint],
          limit: 1,
        );

        if (duplicates.isEmpty) {
          final paymentId = await txn.insert('payments', {
            'date': payment.date.toIso8601String(),
            'amount': payment.amount,
            'payment_method': payment.paymentMethod,
            'fingerprint': fingerprint,
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
          migratedPayments++;
        } else {
          duplicatePaymentsSkipped++;
          debugPrint(
            '[Migration] Paiement doublé ignoré: ${payment.date} - ${payment.amount}€',
          );
        }
      }

      // Migrate pending orders (UPSERT based on ID)
      for (final order in legacyPending) {
        final existing = await txn.query(
          'pending_orders',
          where: 'id = ?',
          whereArgs: [order.id],
          limit: 1,
        );

        if (existing.isEmpty) {
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
          migratedPendingOrders++;
        } else {
          debugPrint(
            '[Migration] Commande "${order.id}" déjà existante, ignorée',
          );
        }
      }
    });

    debugPrint(
      '[Migration] ✅ Terminée: $migratedProducts produits, '
      '$migratedPayments paiements, $migratedPendingOrders commandes migrées',
    );

    // Save migration stats
    await _markMigrationCompleted(
      migratedProducts,
      migratedPayments,
      migratedPendingOrders,
    );

    await _recordDuplicateStats(duplicatePaymentsSkipped);

    return MigrationStats(
      productsCount: migratedProducts,
      paymentsCount: migratedPayments,
      pendingOrdersCount: migratedPendingOrders,
      migrationDate: DateTime.now(),
    );
  }

  /// Marks migration as completed and saves statistics.
  Future<void> _markMigrationCompleted(
    int productsCount,
    int paymentsCount,
    int pendingOrdersCount,
  ) async {
    final stats = {
      'products': productsCount,
      'payments': paymentsCount,
      'pending_orders': pendingOrdersCount,
      'date': DateTime.now().toIso8601String(),
    };

    await db.insert('meta', {
      'key': _migrationStatsKey,
      'value': json.encode(stats),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('meta', {
      'key': _migrationMetaKey,
      'value': '1',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _recordDuplicateStats(int duplicatePaymentsSkipped) async {
    if (duplicatePaymentsSkipped == 0) return;
    await db.insert('meta', {
      'key': _migrationDuplicatesKey,
      'value': json.encode({
        'count': duplicatePaymentsSkipped,
        'date': DateTime.now().toIso8601String(),
      }),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves migration statistics if available.
  Future<MigrationStats?> getMigrationStats() async {
    final rows = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: [_migrationStatsKey],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    try {
      final data = json.decode(rows.first['value'] as String);
      return MigrationStats(
        productsCount: data['products'] as int,
        paymentsCount: data['payments'] as int,
        pendingOrdersCount: data['pending_orders'] as int,
        migrationDate: DateTime.parse(data['date'] as String),
      );
    } catch (e) {
      debugPrint('[Migration] Erreur lecture stats: $e');
      return null;
    }
  }

  Future<List<Pizza>> _loadLegacyPizzas(SharedPreferences prefs) async {
    final pizzaJson = prefs.getStringList(AppStorageKeys.pizzas);
    try {
      return pizzaJson
              ?.map((s) {
                final decoded = _jsonDecodeSafe(s);
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
    final paymentsJson = prefs.getStringList(AppStorageKeys.payments);
    try {
      return paymentsJson
              ?.map((s) {
                final decoded = _jsonDecodeSafe(s);
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
    SharedPreferences prefs,
  ) async {
    final pendingJson = prefs.getStringList(AppStorageKeys.pendingOrders);
    try {
      return pendingJson
              ?.map((s) {
                final decoded = _jsonDecodeSafe(s);
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

  /// Safe JSON decode that tolerates errors.
  Map<String, dynamic>? _jsonDecodeSafe(String source) {
    try {
      return json.decode(source) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
