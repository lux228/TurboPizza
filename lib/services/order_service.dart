import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';
import '../services/order_exceptions.dart';
import '../utils/storage_service.dart';
import '../utils/time_validator.dart';
import '../constants/app_strings.dart';
import '../constants/app_thresholds.dart';

enum OrderStatus { onTime, comingSoon, slightlyLate, late }

class OrderStatusInfo {
  final OrderStatus status;
  final String statusText;
  final IconData icon;

  OrderStatusInfo({
    required this.status,
    required this.statusText,
    required this.icon,
  });
}

class OrderService extends ChangeNotifier {
  static final Uuid _uuid = Uuid();
  List<PendingOrder> _orders = [];

  List<PendingOrder> get orders => List.unmodifiable(_orders);

  bool get hasOrders => _orders.isNotEmpty;

  int get orderCount => _orders.length;

  Future<void> loadOrders() async {
    _orders = await StorageService.loadPendingOrders();
    _sortOrders();
    notifyListeners();
  }

  void _sortOrders() {
    _orders.sort((a, b) => a.pickupDateTime.compareTo(b.pickupDateTime));
  }

  Future<void> addOrder(PendingOrder order) async {
    await StorageService.savePendingOrder(order);
    _orders.add(order);
    _sortOrders();
    notifyListeners();
  }

  Future<void> removeOrder(String orderId) async {
    await StorageService.removePendingOrder(orderId);
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  PendingOrder? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  OrderStatusInfo getOrderStatus(PendingOrder order) {
    final now = DateTime.now();
    final pickupTime = order.pickupDateTime;
    final difference = pickupTime.difference(now).inMinutes;

    if (difference < AppThresholds.lateMinutes) {
      return OrderStatusInfo(
        status: OrderStatus.late,
        statusText: AppStrings.orderStatusLate,
        icon: Icons.warning,
      );
    } else if (difference < AppThresholds.slightlyLateMinutes) {
      return OrderStatusInfo(
        status: OrderStatus.slightlyLate,
        statusText: AppStrings.orderStatusSlightlyLate,
        icon: Icons.access_time,
      );
    } else if (difference <= AppThresholds.comingSoonMinutes) {
      return OrderStatusInfo(
        status: OrderStatus.comingSoon,
        statusText: AppStrings.orderStatusComingSoon,
        icon: Icons.schedule,
      );
    } else {
      return OrderStatusInfo(
        status: OrderStatus.onTime,
        statusText: AppStrings.orderStatusOnTime,
        icon: Icons.check_circle,
      );
    }
  }

  Future<PendingOrder> createOrder({
    required List<Pizza> items,
    required double amount,
    required String pickupTime,
  }) async {
    if (items.isEmpty) {
      throw const EmptyOrderItemsException();
    }
    if (amount <= 0) {
      throw InvalidOrderAmountException(amount);
    }
    if (!TimeValidator.isValidHHmm(pickupTime)) {
      throw InvalidPickupTimeException(pickupTime);
    }

    final order = PendingOrder(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      plannedPickupTime: pickupTime,
      items: items,
      amount: amount,
    );
    await addOrder(order);
    return order;
  }
}
