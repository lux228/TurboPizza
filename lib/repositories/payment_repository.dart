import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/payment.dart';
import '../models/pizza.dart';

/// Repository for managing payment data in the database.
class PaymentRepository {
  final Database db;

  PaymentRepository(this.db);

  /// Inserts a payment and its items into the database.
  /// 
  /// This operation is atomic - either the payment and all its items are saved or none are.
  Future<void> insertPayment(Payment payment) async {
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

  /// Replaces all payments in the database with the provided list.
  /// 
  /// This operation is atomic - either all payments are replaced or none are.
  Future<void> replacePayments(List<Payment> payments) async {
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

  /// Fetches all payments from the database, ordered by date (most recent first).
  Future<List<Payment>> fetchPayments() async {
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

  /// Fetches payments within a specific date range.
  /// 
  /// [start] is inclusive, [endExclusive] is exclusive.
  /// Results are ordered by date (oldest first).
  Future<List<Payment>> fetchPaymentsBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final paymentsRows = await db.query(
      'payments',
      where: 'date >= ? AND date < ?',
      whereArgs: [startIso, endIso],
      orderBy: 'date ASC',
    );

    final ids = paymentsRows.map((r) => r['id'] as int).toList();
    final itemsByPayment = <int, List<Pizza>>{};
    
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

  /// Deletes a payment and all its items from the database.
  Future<void> deletePayment(int paymentId) async {
    await db.transaction((txn) async {
      await txn.delete('payment_items', where: 'payment_id = ?', whereArgs: [paymentId]);
      await txn.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
    });
  }
}
