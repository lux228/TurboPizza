import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_pizza/models/pending_order.dart';
import 'package:turbo_pizza/models/pizza.dart';
import 'package:turbo_pizza/services/cart_service.dart';
import 'package:turbo_pizza/services/database_service.dart';
import 'package:turbo_pizza/services/order_exceptions.dart';
import 'package:turbo_pizza/services/order_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    // Reset mock storage before each test
    SharedPreferences.setMockInitialValues({});

    tempDir = await Directory.systemTemp.createTemp('tp_services_test');
    final dbPath = p.join(tempDir.path, 'test.db');
    await DatabaseService.instance.close();
    await DatabaseService.instance.init(
      overridePath: dbPath,
      skipMigration: true,
    );
  });

  tearDown(() async {
    await DatabaseService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
  group('CartService', () {
    test('add, adjust and total price', () {
      final cart = CartService();
      final margherita = Pizza(
        name: 'Margherita',
        price: 10.0,
        quantity: 0,
        type: 'Tomate',
      );

      cart.addToCart(margherita);
      cart.addToCart(margherita);

      expect(cart.itemCount, 1);
      expect(cart.totalPrice, 20.0);

      cart.adjustQuantity('Margherita', -1);
      expect(cart.totalPrice, 10.0);

      cart.adjustQuantity('Margherita', -1);
      expect(cart.isEmpty, true);
    });
  });

  group('OrderService sorting and status', () {
    test('orders are sorted by pickup time', () async {
      final service = OrderService();
      final items = [
        Pizza(name: 'Margherita', price: 10.0, quantity: 1, type: 'Tomate'),
      ];

      // Create orders with times 20:00, 18:00, 19:00
      final o1 = PendingOrder(
        id: '1',
        createdAt: DateTime.now(),
        plannedPickupTime: '20:00',
        items: items,
        amount: 10.0,
      );
      final o2 = PendingOrder(
        id: '2',
        createdAt: DateTime.now(),
        plannedPickupTime: '18:00',
        items: items,
        amount: 10.0,
      );
      final o3 = PendingOrder(
        id: '3',
        createdAt: DateTime.now(),
        plannedPickupTime: '19:00',
        items: items,
        amount: 10.0,
      );

      // Add via service (persists using SharedPreferences behind the scenes)
      await service.addOrder(o1);
      await service.addOrder(o2);
      await service.addOrder(o3);

      final ids = service.orders.map((e) => e.id).toList();
      expect(ids, ['2', '3', '1']);
    });

    test('pickup time parsing fallback', () {
      final items = [
        Pizza(name: 'Margherita', price: 10.0, quantity: 1, type: 'Tomate'),
      ];
      final malformed = PendingOrder(
        id: 'x',
        createdAt: DateTime.now(),
        plannedPickupTime: 'bad',
        items: items,
        amount: 10.0,
      );
      // Should not throw
      expect(() => malformed.pickupDateTime, returnsNormally);
    });

    test('createOrder rejects invalid pickup time format', () async {
      final service = OrderService();
      final items = [
        Pizza(name: 'Margherita', price: 10.0, quantity: 1, type: 'Tomate'),
      ];

      expect(
        () =>
            service.createOrder(items: items, amount: 10.0, pickupTime: 'bad'),
        throwsA(isA<InvalidPickupTimeException>()),
      );
    });

    test('createOrder generates unique UUID v4 ids', () async {
      final service = OrderService();
      final items = [
        Pizza(name: 'Margherita', price: 10.0, quantity: 1, type: 'Tomate'),
      ];

      final o1 = await service.createOrder(
        items: items,
        amount: 10.0,
        pickupTime: '18:00',
      );
      final o2 = await service.createOrder(
        items: items,
        amount: 10.0,
        pickupTime: '18:10',
      );

      final uuidV4Pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      expect(o1.id, isNot(equals(o2.id)));
      expect(uuidV4Pattern.hasMatch(o1.id), isTrue);
      expect(uuidV4Pattern.hasMatch(o2.id), isTrue);
    });
  });
}
