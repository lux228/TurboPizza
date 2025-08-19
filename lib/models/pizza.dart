class Pizza {
  String name;
  double price;
  int quantity;
  String type; // Nouvel attribut pour le type de pizza

  Pizza(
      {required this.name,
      required this.price,
      this.quantity = 0,
      required this.type});

  double get totalPrice => quantity * price;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'type': type, // Inclure le type dans la sérialisation
      };

  static Pizza fromJson(Map<String, dynamic> json) => Pizza(
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    quantity: (json['quantity'] as int?) ?? 0,
    type: (json['type'] as String?)?.trim().isNotEmpty == true
    ? json['type']
    : 'Tomate', // Valeur par défaut normalisée
  );

  Pizza copyWith({
    String? name,
    double? price,
    int? quantity,
    String? type,
  }) {
    return Pizza(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pizza &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          price == other.price &&
          quantity == other.quantity &&
          type == other.type;

  @override
  int get hashCode => Object.hash(name, price, quantity, type);
}
