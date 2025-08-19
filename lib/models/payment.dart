import 'pizza.dart';

class Payment {
  DateTime date;
  double amount;
  String paymentMethod;
  List<Pizza> items;
  bool isSelected;

  Payment({
    required this.date,
    required this.amount,
    required this.paymentMethod,
    this.items = const [],
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        // Keep original JSON keys for backward compatibility
        'date': date.toIso8601String(),
        'montant': amount,
        'modeReglement': paymentMethod,
        'articles': items.map((pizza) => pizza.toJson()).toList(),
      };

  static Payment fromJson(Map<String, dynamic> json) => Payment(
        date: DateTime.parse(json['date']),
        amount: (json['montant'] as num).toDouble(),
        paymentMethod: json['modeReglement'],
        items: json['articles'] != null
            ? (json['articles'] as List)
                .map((item) => Pizza.fromJson(item))
                .toList()
            : [],
      );
}
