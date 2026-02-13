import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';

/// Repository for managing pending order data in the database.
class PendingOrderRepository {
  final Database db;

  PendingOrderRepository(this.db);

  /// Saves a pending order and its items to the database.
  /// 
  /// If an order with the same ID already exists, it will be replaced.
  /// This operation is atomic - either the order and all its items are saved or none are.
  Future<void> savePendingOrder(PendingOrder order) async {
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

  /// Fetches all pending orders from the database, ordered by planned pickup time.
  Future<List<PendingOrder>> fetchPendingOrders() async {
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

  /// Removes a pending order and all its items from the database.
  Future<void> removePendingOrder(String orderId) async {
    await db.transaction((txn) async {
      await txn.delete('pending_order_items', where: 'order_id = ?', whereArgs: [orderId]);
      await txn.delete('pending_orders', where: 'id = ?', whereArgs: [orderId]);
    });
  }

  /// Replaces all pending orders in the database with the provided list.
  /// 
  /// This operation is atomic - either all orders are replaced or none are.
  Future<void> replacePendingOrders(List<PendingOrder> orders) async {
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

  /// Fetches a specific pending order by ID.
  /// 
  /// Returns null if no order with the given ID exists.
  Future<PendingOrder?> fetchPendingOrderById(String orderId) async {
    final orderRows = await db.query(
      'pending_orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (orderRows.isEmpty) return null;

    final orderRow = orderRows.first;
    final itemsRows = await db.query(
      'pending_order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    final items = itemsRows
        .map((row) => Pizza(
              name: row['name'] as String,
              price: (row['unit_price'] as num).toDouble(),
              quantity: row['quantity'] as int,
              type: row['type'] as String,
            ))
        .toList();

    return PendingOrder(
      id: orderRow['id'] as String,
      createdAt: DateTime.parse(orderRow['created_at'] as String),
      plannedPickupTime: orderRow['planned_pickup'] as String,
      items: items,
      amount: (orderRow['amount'] as num).toDouble(),
    );
  }
}
