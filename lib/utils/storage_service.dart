import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/pizza.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../constants/app_constants.dart';

class StorageService {
  static Future<List<Pizza>> loadPizzaList() async {
    final prefs = await SharedPreferences.getInstance();
  List<String>? pizzaJson = prefs.getStringList(AppConstants.spKeyPizzas);
    try {
      return pizzaJson
              ?.map((string) => Pizza.fromJson(json.decode(string)))
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePizzaList(List<Pizza> pizzas) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pizzaJson =
        pizzas.map((pizza) => json.encode(pizza.toJson())).toList();
  await prefs.setStringList(AppConstants.spKeyPizzas, pizzaJson);
  }

  // Payments
  static Future<void> savePayment(Payment payment) async {
    final prefs = await SharedPreferences.getInstance();
  List<String> paymentsList = prefs.getStringList(AppConstants.spKeyPayments) ?? [];
  paymentsList.add(json.encode(payment.toJson()));
  await prefs.setStringList(AppConstants.spKeyPayments, paymentsList);
  }

  static Future<List<Payment>> loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
  List<String>? paymentsJson = prefs.getStringList(AppConstants.spKeyPayments);
  try {
    return paymentsJson
              ?.map((string) => Payment.fromJson(json.decode(string)))
              .toList() ??
          [];
  } catch (_) {
    return [];
  }
  }

  static Future<void> savePayments(List<Payment> payments) async {
    final prefs = await SharedPreferences.getInstance();
  final paymentsJson = payments.map((payment) {
      return json.encode(payment.toJson());
    }).toList();
  await prefs.setStringList(AppConstants.spKeyPayments, paymentsJson);
  }

  // Pending orders
  static Future<void> savePendingOrder(PendingOrder order) async {
    final prefs = await SharedPreferences.getInstance();
  List<String> pendingOrdersList =
    prefs.getStringList(AppConstants.spKeyPendingOrders) ?? [];
  pendingOrdersList.add(json.encode(order.toJson()));
  await prefs.setStringList(AppConstants.spKeyPendingOrders, pendingOrdersList);
  }

  static Future<List<PendingOrder>> loadPendingOrders() async {
    final prefs = await SharedPreferences.getInstance();
  List<String>? pendingOrdersJson = prefs.getStringList(AppConstants.spKeyPendingOrders);
  try {
    return pendingOrdersJson
              ?.map((string) => PendingOrder.fromJson(json.decode(string)))
              .toList() ??
          [];
  } catch (_) {
    return [];
  }
  }

  static Future<void> savePendingOrders(List<PendingOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
  final pendingOrdersJson = orders.map((order) {
      return json.encode(order.toJson());
    }).toList();
  await prefs.setStringList(AppConstants.spKeyPendingOrders, pendingOrdersJson);
  }

  static Future<void> removePendingOrder(String orderId) async {
  final orders = await loadPendingOrders();
  final updatedOrders = orders.where((c) => c.id != orderId).toList();
  await savePendingOrders(updatedOrders);
  }
}
