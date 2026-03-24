import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:turbo_pizza/models/payment.dart';
import 'package:turbo_pizza/models/pending_order.dart';
import 'package:turbo_pizza/models/pizza.dart';
import 'package:turbo_pizza/services/backup_service.dart';
import 'package:turbo_pizza/services/database_service.dart';

void main() {
  sqfliteFfiInit();

  final db = DatabaseService.instance;
  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tp_db_test');
    dbPath = p.join(tempDir.path, 'test.db');
    await db.close();
    await db.init(overridePath: dbPath, skipMigration: true);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('products roundtrip', () async {
    final pizzas = [
      Pizza(name: 'Margherita', price: 8.0, quantity: 0, type: 'Tomate'),
      Pizza(name: 'Reine', price: 10.0, quantity: 0, type: 'Tomate'),
    ];

    await db.replaceProducts(pizzas);
    final fetched = await db.fetchProducts();

    expect(fetched.length, 2);
    expect(fetched.first.name, 'Margherita');
  });

  test('payments with items roundtrip', () async {
    final payment = Payment(
      date: DateTime.utc(2024, 1, 5, 12, 0),
      amount: 20.5,
      paymentMethod: 'Espèces',
      items: [
        Pizza(name: 'Margherita', price: 8.0, quantity: 1, type: 'Tomate'),
        Pizza(name: 'Soft', price: 2.5, quantity: 2, type: 'Softs'),
      ],
    );

    await db.replacePayments([payment]);
    final fetched = await db.fetchPayments();

    expect(fetched.length, 1);
    expect(fetched.single.amount, 20.5);
    expect(fetched.single.items.length, 2);
    expect(fetched.single.items.first.name, 'Margherita');
  });

  test('pending orders roundtrip', () async {
    final order = PendingOrder(
      id: 'order-1',
      createdAt: DateTime.utc(2024, 1, 5, 10, 0),
      plannedPickupTime: '12:30',
      items: [Pizza(name: 'Reine', price: 10, quantity: 1, type: 'Tomate')],
      amount: 10,
    );

    await db.replacePendingOrders([order]);
    final fetched = await db.fetchPendingOrders();

    expect(fetched.length, 1);
    expect(fetched.single.plannedPickupTime, '12:30');
    expect(fetched.single.items.single.name, 'Reine');
  });

  test(
    'legacy pending order IDs are migrated to UUID while keeping items',
    () async {
      final createdAt = DateTime.utc(2024, 1, 5, 10, 0).toIso8601String();

      await db.database.insert('pending_orders', {
        'id': 'legacy-order-123',
        'created_at': createdAt,
        'planned_pickup': '12:30',
        'amount': 10.0,
      });

      await db.database.insert('pending_order_items', {
        'order_id': 'legacy-order-123',
        'name': 'Reine',
        'type': 'Tomate',
        'unit_price': 10.0,
        'quantity': 1,
      });

      // Reopen DB to trigger startup migration.
      await db.close();
      await db.init(overridePath: dbPath, skipMigration: true);

      final fetched = await db.fetchPendingOrders();
      expect(fetched.length, 1);
      expect(fetched.single.id, isNot('legacy-order-123'));

      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
      );
      expect(fetched.single.id.length, 36);
      expect(uuidPattern.hasMatch(fetched.single.id), isTrue);
      expect(fetched.single.items.length, 1);
      expect(fetched.single.items.single.name, 'Reine');
    },
  );

  test('fetch payments between dates', () async {
    final p1 = Payment(
      date: DateTime.utc(2024, 1, 1, 9),
      amount: 10,
      paymentMethod: 'Espèces',
      items: const [],
    );
    final p2 = Payment(
      date: DateTime.utc(2024, 1, 5, 9),
      amount: 15,
      paymentMethod: 'Chèque',
      items: const [],
    );

    await db.replacePayments([p1, p2]);
    final ranged = await db.fetchPaymentsBetween(
      start: DateTime.utc(2024, 1, 2),
      endExclusive: DateTime.utc(2024, 1, 6),
    );

    expect(ranged.length, 1);
    expect(ranged.single.paymentMethod, 'Chèque');
  });

  test('export/import database and CSV', () async {
    final payment = Payment(
      date: DateTime.utc(2024, 2, 1, 18, 30),
      amount: 30,
      paymentMethod: 'Espèces',
      items: [Pizza(name: '4 Fromages', price: 12, quantity: 2, type: 'Crème')],
    );
    await db.replacePayments([payment]);

    final backupPath = p.join(tempDir.path, 'backup.db');
    await BackupService.instance.exportDatabase(backupPath);

    // CSV export
    final csvPath = p.join(tempDir.path, 'export.csv');
    final csvFile = await BackupService.instance.exportPaymentsCsv(
      start: DateTime.utc(2024, 1, 1),
      endExclusive: DateTime.utc(2024, 3, 1),
      destinationPath: csvPath,
    );
    final csvContent = await csvFile.readAsString();
    expect(csvContent.contains('payment_method'), isTrue);
    expect(csvContent.split('\n').length >= 2, isTrue);

    // Simulate data loss then restore from backup
    await db.replacePayments([]);
    expect((await db.fetchPayments()).isEmpty, isTrue);

    await BackupService.instance.importDatabase(backupPath);
    final restored = await db.fetchPayments();
    expect(restored.length, 1);
    expect(restored.single.amount, 30);
  });
}
