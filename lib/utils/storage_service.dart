import '../models/pizza.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../services/database_service.dart';

class StorageService {
  static Future<void> _ensureDb() async {
    await DatabaseService.instance.init();
  }

  static Future<List<Pizza>> loadPizzaList({bool includeInactive = false}) async {
    await _ensureDb();
    return DatabaseService.instance.fetchProducts(includeInactive: includeInactive);
  }

  static Future<void> savePizzaList(List<Pizza> pizzas) async {
    await _ensureDb();
    await DatabaseService.instance.replaceProducts(pizzas);
  }

  // Payments
  static Future<void> savePayment(Payment payment) async {
    await _ensureDb();
    await DatabaseService.instance.insertPayment(payment);
  }

  static Future<List<Payment>> loadPayments() async {
    await _ensureDb();
    return DatabaseService.instance.fetchPayments();
  }

  static Future<List<Payment>> loadPaymentsPage({
    required DateTime start,
    required DateTime endExclusive,
    required int limit,
    required int offset,
  }) async {
    await _ensureDb();
    return DatabaseService.instance.fetchPaymentsPage(
      start: start,
      endExclusive: endExclusive,
      limit: limit,
      offset: offset,
    );
  }

  static Future<Map<String, double>> loadPaymentTotalsByMethodBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    await _ensureDb();
    return DatabaseService.instance.fetchPaymentTotalsByMethodBetween(
      start: start,
      endExclusive: endExclusive,
    );
  }

  static Future<double> loadPaymentTotalAmountBetween({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    await _ensureDb();
    return DatabaseService.instance.fetchPaymentTotalAmountBetween(
      start: start,
      endExclusive: endExclusive,
    );
  }

  static Future<void> savePayments(List<Payment> payments) async {
    await _ensureDb();
    await DatabaseService.instance.replacePayments(payments);
  }

  static Future<void> deletePayment(int paymentId) async {
    await _ensureDb();
    await DatabaseService.instance.payments.deletePayment(paymentId);
  }

  static Future<void> updatePaymentMethod({
    required Payment payment,
    required String newMethod,
  }) async {
    await _ensureDb();
    await DatabaseService.instance.payments.updatePaymentMethod(
      payment: payment,
      newMethod: newMethod,
    );
  }

  // Pending orders
  static Future<void> savePendingOrder(PendingOrder order) async {
    await _ensureDb();
    await DatabaseService.instance.savePendingOrder(order);
  }

  static Future<List<PendingOrder>> loadPendingOrders() async {
    await _ensureDb();
    return DatabaseService.instance.fetchPendingOrders();
  }

  static Future<void> savePendingOrders(List<PendingOrder> orders) async {
    await _ensureDb();
    await DatabaseService.instance.replacePendingOrders(orders);
  }

  static Future<void> removePendingOrder(String orderId) async {
    await _ensureDb();
    await DatabaseService.instance.removePendingOrder(orderId);
  }
}
