import 'pizza.dart';

class Payment {
  int? id;
  DateTime date;
  double amount;
  String paymentMethod;
  List<Pizza> items;
  bool isSelected;

  Payment({
    this.id,
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

  Payment copyWith({
    int? id,
    DateTime? date,
    double? amount,
    String? paymentMethod,
    List<Pizza>? items,
    bool? isSelected,
  }) {
    return Payment(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          amount == other.amount &&
          paymentMethod == other.paymentMethod &&
          _listEquals(items, other.items) &&
          isSelected == other.isSelected;

  @override
  int get hashCode => Object.hash(
    date,
    amount,
    paymentMethod,
    Object.hashAll(items),
    isSelected,
  );

  // Simple list equality to avoid importing collection just for this
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
