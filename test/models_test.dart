import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_pizza/models/pizza.dart';
import 'package:turbo_pizza/models/payment.dart';
import 'package:turbo_pizza/models/pending_order.dart';
import 'package:turbo_pizza/utils/time_validator.dart';

void main() {
  group('Pizza Model Tests', () {
    test('Pizza creation and total price calculation', () {
      final pizza = Pizza(
        name: 'Margherita',
        price: 12.50,
        quantity: 2,
        type: 'Tomate',
      );

      expect(pizza.name, 'Margherita');
      expect(pizza.totalPrice, 25.0);
    });

    test('Pizza JSON serialization', () {
      final pizza = Pizza(
        name: 'Margherita',
        price: 12.50,
        quantity: 1,
        type: 'Tomate',
      );

      final json = pizza.toJson();
      final fromJson = Pizza.fromJson(json);

      expect(fromJson.name, pizza.name);
      expect(fromJson.price, pizza.price);
      expect(fromJson.type, pizza.type);
    });
  });

  group('Payment Model Tests', () {
    test('Payment creation', () {
      final articles = [
        Pizza(name: 'Margherita', price: 12.50, quantity: 1, type: 'Tomate'),
      ];

      final payment = Payment(
        date: DateTime.now(),
        amount: 12.50,
        paymentMethod: 'Espèces',
        items: articles,
      );

      expect(payment.amount, 12.50);
      expect(payment.paymentMethod, 'Espèces');
      expect(payment.items.length, 1);
    });
  });

  group('PendingOrder Model Tests', () {
    test('accepts valid HH:mm pickup time', () {
      final order = PendingOrder(
        id: 'id-1',
        createdAt: DateTime(2026, 1, 1, 12, 0),
        plannedPickupTime: '18:30',
        items: [
          Pizza(name: 'Margherita', price: 12.5, quantity: 1, type: 'Tomate'),
        ],
        amount: 12.5,
      );

      expect(order.plannedPickupTime, '18:30');
    });

    test('detects invalid HH:mm values', () {
      expect(TimeValidator.isValidHHmm('25:99'), isFalse);
      expect(TimeValidator.isValidHHmm('bad'), isFalse);
    });

    test('accepts edge HH:mm values', () {
      final min = PendingOrder(
        id: 'id-3',
        createdAt: DateTime(2026, 1, 1, 12, 0),
        plannedPickupTime: '00:00',
        items: [],
        amount: 0,
      );
      final max = PendingOrder(
        id: 'id-4',
        createdAt: DateTime(2026, 1, 1, 12, 0),
        plannedPickupTime: '23:59',
        items: [],
        amount: 0,
      );

      expect(min.plannedPickupTime, '00:00');
      expect(max.plannedPickupTime, '23:59');
    });

    test('pickupDateTime fallback does not throw for malformed time', () {
      final malformed = PendingOrder(
        id: 'id-5',
        createdAt: DateTime(2026, 1, 1, 12, 0),
        plannedPickupTime: 'bad',
        items: [],
        amount: 0,
      );

      expect(() => malformed.pickupDateTime, returnsNormally);
    });
  });
}
