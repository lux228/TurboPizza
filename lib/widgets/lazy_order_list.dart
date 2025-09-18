import 'package:flutter/material.dart';
import '../models/pending_order.dart';
import '../services/order_service.dart';
import '../widgets/order_status_card.dart';

/// Widget optimisé pour l'affichage lazy des commandes
class LazyOrderList extends StatelessWidget {
  final List<PendingOrder> orders;
  final Function(PendingOrder) onTap;
  final Function(PendingOrder) onValidate;
  final Function(PendingOrder) onEdit;
  final Function(PendingOrder) onChangeTime;
  final Function(PendingOrder) onCancel;
  final OrderService orderService;

  const LazyOrderList({
    super.key,
    required this.orders,
    required this.onTap,
    required this.onValidate,
    required this.onEdit,
    required this.onChangeTime,
    required this.onCancel,
    required this.orderService,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: orders.length,
      // Optimisation: Ne construire que les éléments visibles
      itemBuilder: (context, index) {
        return _LazyOrderCard(
          order: orders[index],
          orderService: orderService,
          onTap: onTap,
          onValidate: onValidate,
          onEdit: onEdit,
          onChangeTime: onChangeTime,
          onCancel: onCancel,
        );
      },
    );
  }
}

/// Widget de carte optimisé avec construction lazy
class _LazyOrderCard extends StatelessWidget {
  final PendingOrder order;
  final OrderService orderService;
  final Function(PendingOrder) onTap;
  final Function(PendingOrder) onValidate;
  final Function(PendingOrder) onEdit;
  final Function(PendingOrder) onChangeTime;
  final Function(PendingOrder) onCancel;

  const _LazyOrderCard({
    required this.order,
    required this.orderService,
    required this.onTap,
    required this.onValidate,
    required this.onEdit,
    required this.onChangeTime,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul du statut seulement au moment de l'affichage
    final statusInfo = orderService.getOrderStatus(order);
    
    return OrderStatusCard(
      order: order,
      statusInfo: statusInfo,
      onTap: () => onTap(order),
      onValidate: () => onValidate(order),
      onEdit: () => onEdit(order),
      onChangeTime: () => onChangeTime(order),
      onCancel: () => onCancel(order),
    );
  }
}
