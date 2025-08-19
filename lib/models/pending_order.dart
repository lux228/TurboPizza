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
    final now = DateTime.now();
    try {
      final parts = plannedPickupTime.split(':');
      if (parts.length != 2) {
        // format inattendu, fallback: 23:59 aujourd'hui
        return DateTime(now.year, now.month, now.day, 23, 59);
      }
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) {
        return DateTime(now.year, now.month, now.day, 23, 59);
      }
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      // fallback en cas d'erreur
      return DateTime(now.year, now.month, now.day, 23, 59);
    }
  }

  PendingOrder copyWith({
    String? id,
    DateTime? createdAt,
    String? plannedPickupTime,
    List<Pizza>? items,
    double? amount,
  }) {
    return PendingOrder(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      plannedPickupTime: plannedPickupTime ?? this.plannedPickupTime,
      items: items ?? this.items,
      amount: amount ?? this.amount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingOrder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          createdAt == other.createdAt &&
          plannedPickupTime == other.plannedPickupTime &&
          _listEquals(items, other.items) &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(
        id,
        createdAt,
        plannedPickupTime,
        Object.hashAll(items),
        amount,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
