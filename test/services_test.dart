import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_pizza/services/cart_service.dart';
import 'package:turbo_pizza/services/order_service.dart';
import 'package:turbo_pizza/models/pizza.dart';
import 'package:turbo_pizza/models/pending_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset mock storage before each test
    SharedPreferences.setMockInitialValues({});
  });
  group('CartService', () {
    test('add, adjust and total price', () {
      final cart = CartService();
      final margherita = Pizza(name: 'Margherita', price: 10.0, quantity: 0, type: 'Tomate');

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
      final items = [Pizza(name: 'Margherita', price: 10.0, quantity: 1, type: 'Tomate')];

      // Create orders with times 20:00, 18:00, 19:00
      final o1 = PendingOrder(id: '1', createdAt: DateTime.now(), plannedPickupTime: '20:00', items: items, amount: 10.0);
      final o2 = PendingOrder(id: '2', createdAt: DateTime.now(), plannedPickupTime: '18:00', items: items, amount: 10.0);
      final o3 = PendingOrder(id: '3', createdAt: DateTime.now(), plannedPickupTime: '19:00', items: items, amount: 10.0);

      // Add via service (persists using SharedPreferences behind the scenes)
      await service.addOrder(o1);
      await service.addOrder(o2);
      await service.addOrder(o3);

      final ids = service.orders.map((e) => e.id).toList();
      expect(ids, ['2', '3', '1']);
    });

    test('pickup time parsing fallback', () {
      final items = [Pizza(name: 'Margherita', price: 10.0, quantity: 1, type: 'Tomate')];
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
  });
}
