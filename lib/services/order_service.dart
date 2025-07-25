import 'package:flutter/material.dart';
import '../models/commande_attente.dart';
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
  List<CommandeAttente> _orders = [];
  
  List<CommandeAttente> get orders => List.unmodifiable(_orders);
  
  bool get hasOrders => _orders.isNotEmpty;
  
  int get orderCount => _orders.length;

  Future<void> loadOrders() async {
    _orders = await StorageService.loadCommandesAttente();
    _sortOrders();
    notifyListeners();
  }

  void _sortOrders() {
    _orders.sort((a, b) => a.heureRecuperationDateTime.compareTo(b.heureRecuperationDateTime));
  }

  Future<void> addOrder(CommandeAttente order) async {
    await StorageService.saveCommandeAttente(order);
    _orders.add(order);
    _sortOrders();
    notifyListeners();
  }

  Future<void> removeOrder(String orderId) async {
    await StorageService.removeCommandeAttente(orderId);
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  CommandeAttente? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  OrderStatusInfo getOrderStatus(CommandeAttente order) {
    final now = DateTime.now();
    final pickupTime = order.heureRecuperationDateTime;
    final difference = pickupTime.difference(now).inMinutes;

    if (difference < AppConstants.lateThreshold) {
      return OrderStatusInfo(
        status: OrderStatus.late,
        statusText: 'En retard',
        color: Colors.red[600]!,
        backgroundColor: Colors.red[50]!,
        icon: Icons.warning,
      );
    } else if (difference < AppConstants.slightlyLateThreshold) {
      return OrderStatusInfo(
        status: OrderStatus.slightlyLate,
        statusText: 'Légèrement en retard',
        color: Colors.orange[700]!,
        backgroundColor: Colors.orange[50]!,
        icon: Icons.access_time,
      );
    } else if (difference <= AppConstants.comingSoonThreshold) {
      return OrderStatusInfo(
        status: OrderStatus.comingSoon,
        statusText: 'Bientôt là',
        color: Colors.orange[600]!,
        backgroundColor: Colors.orange[50]!,
        icon: Icons.schedule,
      );
    } else {
      return OrderStatusInfo(
        status: OrderStatus.onTime,
        statusText: 'À l\'heure',
        color: Colors.green[600]!,
        backgroundColor: Colors.green[50]!,
        icon: Icons.check_circle,
      );
    }
  }

  Future<CommandeAttente> createOrder({
    required List<Pizza> articles,
    required double amount,
    required String pickupTime,
  }) async {
    final order = CommandeAttente(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      heureComposition: DateTime.now(),
      heureRecuperationPrevue: pickupTime,
      articles: articles,
      montant: amount,
    );
    
    await addOrder(order);
    return order;
  }
}
