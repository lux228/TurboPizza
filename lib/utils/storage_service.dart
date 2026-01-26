import '../models/pizza.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../services/database_service.dart';

class StorageService {
  static Future<void> _ensureDb() async {
    await DatabaseService.instance.init();
  }

  static Future<List<Pizza>> loadPizzaList() async {
    await _ensureDb();
    return DatabaseService.instance.fetchProducts();
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

  static Future<void> savePayments(List<Payment> payments) async {
    await _ensureDb();
    await DatabaseService.instance.replacePayments(payments);
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
