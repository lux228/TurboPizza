import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_pizza/constants/app_storage_keys.dart';
import 'package:turbo_pizza/models/payment.dart';
import 'package:turbo_pizza/models/pizza.dart';
import 'package:turbo_pizza/services/database_service.dart';
import 'package:turbo_pizza/services/migration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Intelligent migration', () {
    late String testDbPath;
    late DatabaseService dbService;

    setUp(() async {
      // Create temporary database for testing
      final tempDir = await Directory.systemTemp.createTemp('migration_test');
      testDbPath = '${tempDir.path}/test.db';
      dbService = DatabaseService.instance;
    });

    tearDown(() async {
      await dbService.close();
      await File(testDbPath).delete();
    });

    test('should merge data without duplicates', () async {
      // 1. Initialize database with some existing data
      await dbService.init(overridePath: testDbPath, skipMigration: true);

      // Add existing products to SQLite
      final existingPizza = Pizza(
        name: 'Margherita',
        price: 10.0,
        quantity: 1,
        type: 'Pizza',
      );
      await dbService.products.insertProduct(existingPizza);

      // Add existing payment to SQLite
      final existingPayment = Payment(
        date: DateTime(2026, 1, 1, 12, 0),
        amount: 10.0,
        paymentMethod: 'Espèces',
        items: [existingPizza],
      );
      await dbService.payments.insertPayment(existingPayment);

      // 2. Setup SharedPreferences with legacy data (including duplicates)
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.pizzas: [
          json.encode({
            'name': 'Margherita', // Duplicate - should be skipped/updated
            'price': 11.0, // Different price - should update
            'quantity': 0,
            'type': 'Pizza',
          }),
          json.encode({
            'name': 'Regina', // New - should be added
            'price': 12.0,
            'quantity': 0,
            'type': 'Pizza',
          }),
        ],
        AppStorageKeys.payments: [
          json.encode({
            'date': '2026-01-01T12:00:00.000',
            'montant': 10.0,
            'modeReglement': 'Espèces',
            'articles': [
              {
                'name': 'Margherita',
                'price': 10.0,
                'quantity': 1,
                'type': 'Pizza',
              },
            ],
          }), // Duplicate - should be skipped
          json.encode({
            'date': '2026-01-02T14:00:00.000',
            'montant': 25.0,
            'modeReglement': 'CB',
            'articles': [
              {'name': 'Regina', 'price': 12.0, 'quantity': 2, 'type': 'Pizza'},
            ],
          }), // New - should be added
        ],
        AppStorageKeys.pendingOrders: [
          json.encode({
            'id': 'order123',
            'heureComposition': '2026-02-12T10:00:00.000',
            'heureRecuperationPrevue': '18:30',
            'montant': 15.0,
            'articles': [
              {
                'name': 'Margherita',
                'price': 10.0,
                'quantity': 1,
                'type': 'Pizza',
              },
            ],
          }),
        ],
      });

      // 3. Run migration
      final migrationService = MigrationService(dbService.database);
      final stats = await migrationService.migrateFromPrefsIfNeeded();

      // 4. Verify results
      expect(stats, isNotNull);

      // Products: 1 updated (Margherita), 1 new (Regina) = 1 migrated
      expect(stats!.productsCount, equals(1));

      // Payments: 1 duplicate skipped, 1 new = 1 migrated
      expect(stats.paymentsCount, equals(1));

      // Pending orders: 1 new = 1 migrated
      expect(stats.pendingOrdersCount, equals(1));

      // Verify actual database content
      final products = await dbService.products.fetchProducts(
        includeInactive: true,
      );
      expect(products.length, equals(2)); // Margherita + Regina

      final margherita = products.firstWhere((p) => p.name == 'Margherita');
      expect(margherita.price, equals(11.0)); // Updated price

      final regina = products.firstWhere((p) => p.name == 'Regina');
      expect(regina.price, equals(12.0));

      // Verify payments
      final payments = await dbService.payments.fetchPayments();
      expect(payments.length, equals(2)); // Original + new one

      // Verify pending orders
      final orders = await dbService.pendingOrders.fetchPendingOrders();
      expect(orders.length, equals(1));
      expect(orders.first.id, equals('order123'));
    });

    test('should handle already completed migration gracefully', () async {
      // Initialize with skip migration
      await dbService.init(overridePath: testDbPath, skipMigration: true);

      // Setup SharedPreferences
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.pizzas: [
          json.encode({
            'name': 'Calzone',
            'price': 13.0,
            'quantity': 0,
            'type': 'Pizza',
          }),
        ],
      });

      // First migration
      final migrationService = MigrationService(dbService.database);
      final stats1 = await migrationService.migrateFromPrefsIfNeeded();
      expect(stats1, isNotNull);
      expect(stats1!.productsCount, equals(1));

      // Verify migration is marked as completed
      final isCompleted = await migrationService.isMigrationCompleted();
      expect(isCompleted, isTrue);

      // Add more data to SharedPreferences
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.pizzas: [
          json.encode({
            'name': 'Calzone',
            'price': 13.0,
            'quantity': 0,
            'type': 'Pizza',
          }),
          json.encode({
            'name': 'Quattro Formaggi',
            'price': 14.0,
            'quantity': 0,
            'type': 'Pizza',
          }),
        ],
      });

      // Second attempt - should return null because already completed
      final stats2 = await migrationService.migrateFromPrefsIfNeeded();
      expect(stats2, isNull);

      // Products count should still be 1 (second migration didn't run)
      final products = await dbService.products.fetchProducts();
      expect(products.length, equals(1));
    });

    test(
      'should mark migration as completed when SharedPreferences is empty',
      () async {
        await dbService.init(overridePath: testDbPath, skipMigration: true);

        // Empty SharedPreferences
        SharedPreferences.setMockInitialValues({});

        final migrationService = MigrationService(dbService.database);
        final stats = await migrationService.migrateFromPrefsIfNeeded();

        expect(stats, isNull);

        // Should still be marked as completed
        final isCompleted = await migrationService.isMigrationCompleted();
        expect(isCompleted, isTrue);
      },
    );
  });
}
