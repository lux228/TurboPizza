import 'pizza.dart';

class PendingOrder {
  String id;
  DateTime createdAt;
  String plannedPickupTime; // Format HH:mm
  List<Pizza> items;
  double amount;

  PendingOrder({
    required this.id,
    required this.createdAt,
    required this.plannedPickupTime,
    required this.items,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        // Keep original JSON keys for backward compatibility
        'id': id,
        'heureComposition': createdAt.toIso8601String(),
        'heureRecuperationPrevue': plannedPickupTime,
        'articles': items.map((pizza) => pizza.toJson()).toList(),
        'montant': amount,
      };

  static PendingOrder fromJson(Map<String, dynamic> json) => PendingOrder(
        id: json['id'],
        createdAt: DateTime.parse(json['heureComposition']),
        plannedPickupTime: json['heureRecuperationPrevue'],
        items: (json['articles'] as List).map((item) => Pizza.fromJson(item)).toList(),
        amount: (json['montant'] as num).toDouble(),
      );

  // Helper to get pickup DateTime for sorting
  DateTime get pickupDateTime {
    final parts = plannedPickupTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
