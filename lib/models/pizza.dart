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
        price: json['price'],
        quantity: json['quantity'] ?? 0,
        type:
            json['type'] ?? 'tomate', // Attribuer "tomate" si "type" est absent
      );
}
