import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_pizza/utils/storage_service.dart';
import 'package:turbo_pizza/models/pending_order.dart';
import 'package:turbo_pizza/models/pizza.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('savePendingOrder deduplicates by id and remove works', () async {
    final items = [Pizza(name: 'Margherita', price: 10.0, quantity: 1, type: 'Tomate')];
    final o1 = PendingOrder(id: '1', createdAt: DateTime.now(), plannedPickupTime: '18:00', items: items, amount: 10.0);
    final o1Updated = o1.copyWith(amount: 12.0);

    await StorageService.savePendingOrder(o1);
    await StorageService.savePendingOrder(o1Updated);

    final loaded = await StorageService.loadPendingOrders();
    expect(loaded.length, 1);
    expect(loaded.first.id, '1');
    expect(loaded.first.amount, 12.0);

    await StorageService.removePendingOrder('1');
    final afterRemove = await StorageService.loadPendingOrders();
    expect(afterRemove.isEmpty, true);
  });
}
