import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/payment.dart';
import '../models/pizza.dart';
import '../utils/payment_fingerprint.dart';

/// Repository for managing payment data in the database.
class PaymentRepository {
  final Database db;

  PaymentRepository(this.db);

  List<Payment> _mapPaymentsFromJoinRows(List<Map<String, Object?>> rows) {
    final paymentsById = <int, Payment>{};
    final ordered = <Payment>[];

    for (final row in rows) {
      final paymentId = row['payment_id'] as int;
      var payment = paymentsById[paymentId];
      if (payment == null) {
        payment = Payment(
          id: paymentId,
          date: DateTime.parse(row['date'] as String),
          amount: (row['amount'] as num).toDouble(),
          paymentMethod: row['payment_method'] as String,
          items: [],
          isSelected: false,
        );
        paymentsById[paymentId] = payment;
        ordered.add(payment);
      }

      final itemId = row['item_id'] as int?;
      if (itemId != null) {
        payment.items.add(
          Pizza(
            name: row['name'] as String,
            price: (row['unit_price'] as num).toDouble(),
            quantity: row['quantity'] as int,
            type: row['type'] as String,
          ),
        );
      }
    }

    return ordered;
  }

  /// Inserts a payment and its items into the database.
  /// 
  /// This operation is atomic - either the payment and all its items are saved or none are.
  Future<void> insertPayment(Payment payment) async {
    await db.transaction((txn) async {
      final fingerprint = buildPaymentFingerprint(payment);
      final paymentId = await txn.insert('payments', {
        'date': payment.date.toIso8601String(),
        'amount': payment.amount,
        'payment_method': payment.paymentMethod,
        'fingerprint': fingerprint,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      if (paymentId == 0) return;
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
        final fingerprint = buildPaymentFingerprint(payment);
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
      }
    });
  }

  /// Fetches all payments from the database, ordered by date (most recent first).
  Future<List<Payment>> fetchPayments() async {
    final rows = await db.rawQuery('''
      SELECT
        p.id AS payment_id,
        p.date,
        p.amount,
        p.payment_method,
        i.id AS item_id,
        i.name,
        i.type,
        i.unit_price,
        i.quantity
      FROM payments p
      LEFT JOIN payment_items i ON i.payment_id = p.id
      ORDER BY p.date DESC, p.id DESC, i.id ASC
    ''');

    return _mapPaymentsFromJoinRows(rows);
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

    final rows = await db.rawQuery('''
      SELECT
        p.id AS payment_id,
        p.date,
        p.amount,
        p.payment_method,
        i.id AS item_id,
        i.name,
        i.type,
        i.unit_price,
        i.quantity
      FROM payments p
      LEFT JOIN payment_items i ON i.payment_id = p.id
      WHERE p.date >= ? AND p.date < ?
      ORDER BY p.date ASC, p.id ASC, i.id ASC
    ''', [startIso, endIso]);

    return _mapPaymentsFromJoinRows(rows);
  }

  /// Fetches payments for a date range using pagination.
  /// 
  /// [start] is inclusive, [endExclusive] is exclusive.
  /// Results are ordered by date (most recent first).
  Future<List<Payment>> fetchPaymentsPage({
    required DateTime start,
    required DateTime endExclusive,
    required int limit,
    required int offset,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final rows = await db.rawQuery('''
      WITH paged AS (
        SELECT id, date, amount, payment_method
        FROM payments
        WHERE date >= ? AND date < ?
        ORDER BY date DESC, id DESC
        LIMIT ? OFFSET ?
      )
      SELECT
        p.id AS payment_id,
        p.date,
        p.amount,
        p.payment_method,
        i.id AS item_id,
        i.name,
        i.type,
        i.unit_price,
        i.quantity
      FROM paged p
      LEFT JOIN payment_items i ON i.payment_id = p.id
      ORDER BY p.date DESC, p.id DESC, i.id ASC
    ''', [startIso, endIso, limit, offset]);

    return _mapPaymentsFromJoinRows(rows);
  }

  /// Returns totals by payment method for a date range.
  /// 
  /// The returned map uses payment_method as key and sum(amount) as value.
  Future<Map<String, double>> fetchTotalsByMethodBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final rows = await db.rawQuery('''
      SELECT payment_method, SUM(amount) AS total
      FROM payments
      WHERE date >= ? AND date < ?
      GROUP BY payment_method
    ''', [startIso, endIso]);

    final totals = <String, double>{};
    for (final row in rows) {
      final method = row['payment_method'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[method] = total;
    }
    return totals;
  }

  /// Returns the total amount for a date range.
  Future<double> fetchTotalAmountBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final rows = await db.rawQuery('''
      SELECT SUM(amount) AS total
      FROM payments
      WHERE date >= ? AND date < ?
    ''', [startIso, endIso]);

    if (rows.isEmpty) return 0.0;
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Deletes a payment and all its items from the database.
  Future<void> deletePayment(int paymentId) async {
    await db.transaction((txn) async {
      await txn.delete('payment_items', where: 'payment_id = ?', whereArgs: [paymentId]);
      await txn.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
    });
  }

  /// Returns top products by quantity sold within a date range.
  /// 
  /// [limit] specifies the maximum number of products to return (default: 10).
  /// Returns a list of maps with keys: name, type, total_quantity, total_revenue.
  Future<List<Map<String, dynamic>>> fetchTopProductsByQuantity({
    required DateTime start,
    required DateTime endExclusive,
    int limit = 10,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final rows = await db.rawQuery('''
      SELECT 
        i.name,
        i.type,
        SUM(i.quantity) AS total_quantity,
        SUM(i.quantity * i.unit_price) AS total_revenue
      FROM payment_items i
      JOIN payments p ON p.id = i.payment_id
      WHERE p.date >= ? AND p.date < ?
      GROUP BY i.name, i.type
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [startIso, endIso, limit]);

    return rows;
  }

  /// Returns top products by revenue within a date range.
  /// 
  /// [limit] specifies the maximum number of products to return (default: 10).
  /// Returns a list of maps with keys: name, type, total_quantity, total_revenue.
  Future<List<Map<String, dynamic>>> fetchTopProductsByRevenue({
    required DateTime start,
    required DateTime endExclusive,
    int limit = 10,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final rows = await db.rawQuery('''
      SELECT 
        i.name,
        i.type,
        SUM(i.quantity) AS total_quantity,
        SUM(i.quantity * i.unit_price) AS total_revenue
      FROM payment_items i
      JOIN payments p ON p.id = i.payment_id
      WHERE p.date >= ? AND p.date < ?
      GROUP BY i.name, i.type
      ORDER BY total_revenue DESC
      LIMIT ?
    ''', [startIso, endIso, limit]);

    return rows;
  }

  /// Returns daily revenue totals within a date range.
  /// 
  /// Returns a list of maps with keys: date (YYYY-MM-DD string), total.
  Future<List<Map<String, dynamic>>> fetchDailyRevenue({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final rows = await db.rawQuery('''
      SELECT 
        DATE(date) AS date,
        SUM(amount) AS total
      FROM payments
      WHERE date >= ? AND date < ?
      GROUP BY DATE(date)
      ORDER BY date ASC
    ''', [startIso, endIso]);

    return rows;
  }

  /// Returns totals by pizza type within a date range.
  /// 
  /// The returned map uses type as key and map with quantity and revenue as value.
  Future<Map<String, Map<String, num>>> fetchTotalsByType({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final startIso = start.toIso8601String();
    final endIso = endExclusive.toIso8601String();

    final rows = await db.rawQuery('''
      SELECT 
        i.type,
        SUM(i.quantity) AS total_quantity,
        SUM(i.quantity * i.unit_price) AS total_revenue
      FROM payment_items i
      JOIN payments p ON p.id = i.payment_id
      WHERE p.date >= ? AND p.date < ?
      GROUP BY i.type
    ''', [startIso, endIso]);

    final totals = <String, Map<String, num>>{};
    for (final row in rows) {
      final type = row['type'] as String;
      final quantity = (row['total_quantity'] as num?) ?? 0;
      final revenue = (row['total_revenue'] as num?) ?? 0;
      totals[type] = {'quantity': quantity, 'revenue': revenue};
    }
    return totals;
  }
}
