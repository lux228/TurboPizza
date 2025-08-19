import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/pizza.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';

class StorageService {
  static Future<List<Pizza>> loadPizzaList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? pizzaJson = prefs.getStringList('pizzas');
    return pizzaJson
            ?.map((string) => Pizza.fromJson(json.decode(string)))
            .toList() ??
        [];
  }

  static Future<void> savePizzaList(List<Pizza> pizzas) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pizzaJson =
        pizzas.map((pizza) => json.encode(pizza.toJson())).toList();
    await prefs.setStringList('pizzas', pizzaJson);
  }

  // Payments
  static Future<void> savePayment(Payment payment) async {
    final prefs = await SharedPreferences.getInstance();
  List<String> paymentsList = prefs.getStringList('encaissements') ?? [];
  paymentsList.add(json.encode(payment.toJson()));
  await prefs.setStringList('encaissements', paymentsList);
  }

  static Future<List<Payment>> loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
  List<String>? paymentsJson = prefs.getStringList('encaissements');
  return paymentsJson
            ?.map((string) => Payment.fromJson(json.decode(string)))
            .toList() ??
        [];
  }

  static Future<void> savePayments(List<Payment> payments) async {
    final prefs = await SharedPreferences.getInstance();
  final paymentsJson = payments.map((payment) {
      return json.encode(payment.toJson());
    }).toList();
  await prefs.setStringList('encaissements', paymentsJson);
  }

  // Pending orders
  static Future<void> savePendingOrder(PendingOrder order) async {
    final prefs = await SharedPreferences.getInstance();
  List<String> pendingOrdersList =
    prefs.getStringList('commandes_attente') ?? [];
  pendingOrdersList.add(json.encode(order.toJson()));
  await prefs.setStringList('commandes_attente', pendingOrdersList);
  }

  static Future<List<PendingOrder>> loadPendingOrders() async {
    final prefs = await SharedPreferences.getInstance();
  List<String>? pendingOrdersJson = prefs.getStringList('commandes_attente');
  return pendingOrdersJson
            ?.map((string) => PendingOrder.fromJson(json.decode(string)))
            .toList() ??
        [];
  }

  static Future<void> savePendingOrders(List<PendingOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
  final pendingOrdersJson = orders.map((order) {
      return json.encode(order.toJson());
    }).toList();
  await prefs.setStringList('commandes_attente', pendingOrdersJson);
  }

  static Future<void> removePendingOrder(String orderId) async {
  final orders = await loadPendingOrders();
  final updatedOrders = orders.where((c) => c.id != orderId).toList();
  await savePendingOrders(updatedOrders);
  }
}
