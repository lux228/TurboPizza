import 'package:flutter/material.dart';
import '../models/pending_order.dart';
import '../models/pizza.dart';
import '../utils/storage_service.dart';
import '../constants/app_constants.dart';

enum OrderStatus {
  onTime,
  comingSoon,
  slightlyLate,
  late,
}

class OrderStatusInfo {
  final OrderStatus status;
  final String statusText;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  OrderStatusInfo({
    required this.status,
    required this.statusText,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });
}

class OrderService extends ChangeNotifier {
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

    if (difference < AppConstants.lateThreshold) {
      return OrderStatusInfo(
        status: OrderStatus.late,
        statusText: 'En retard',
        color: AppConstants.lateColor,
        backgroundColor: AppConstants.lateBackgroundColor,
        icon: Icons.warning,
      );
    } else if (difference < AppConstants.slightlyLateThreshold) {
      return OrderStatusInfo(
        status: OrderStatus.slightlyLate,
        statusText: 'Légèrement en retard',
        color: AppConstants.slightlyLateColor,
        backgroundColor: AppConstants.slightlyLateBackgroundColor,
        icon: Icons.access_time,
      );
    } else if (difference <= AppConstants.comingSoonThreshold) {
      return OrderStatusInfo(
        status: OrderStatus.comingSoon,
        statusText: 'Bientôt là',
        color: AppConstants.comingSoonColor,
        backgroundColor: AppConstants.comingSoonBackgroundColor,
        icon: Icons.schedule,
      );
    } else {
      return OrderStatusInfo(
        status: OrderStatus.onTime,
        statusText: 'À l\'heure',
        color: AppConstants.onTimeColor,
        backgroundColor: AppConstants.onTimeBackgroundColor,
        icon: Icons.check_circle,
      );
    }
  }

  Future<PendingOrder> createOrder({
    required List<Pizza> items,
    required double amount,
    required String pickupTime,
  }) async {
    final order = PendingOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      plannedPickupTime: pickupTime,
      items: items,
      amount: amount,
    );
    await addOrder(order);
    return order;
  }
}
