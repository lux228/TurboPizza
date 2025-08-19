import 'package:flutter/foundation.dart';
import '../models/pizza.dart';

class CartService extends ChangeNotifier {
  final Map<String, Pizza> _cart = {};
  
  Map<String, Pizza> get cart => Map.unmodifiable(_cart);
  
  bool get isEmpty => _cart.isEmpty;
  
  int get itemCount => _cart.length;
  
  double get totalPrice => _cart.values.fold(0, (total, pizza) => total + pizza.totalPrice);
  
  List<Pizza> get items => _cart.values.toList();

  void addToCart(Pizza pizza) {
    if (_cart.containsKey(pizza.name)) {
      _cart[pizza.name]!.quantity++;
    } else {
      _cart[pizza.name] = Pizza(
        name: pizza.name,
        price: pizza.price,
        quantity: 1,
        type: pizza.type,
      );
    }
    notifyListeners();
  }

  void adjustQuantity(String pizzaName, int change) {
    if (_cart.containsKey(pizzaName)) {
      _cart[pizzaName]!.quantity += change;
      if (_cart[pizzaName]!.quantity <= 0) {
        _cart.remove(pizzaName);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String pizzaName) {
    _cart.remove(pizzaName);
    notifyListeners();
  }

  void clear() {
    _cart.clear();
    notifyListeners();
  }

  void loadFromOrder(List<Pizza> items) {
    _cart.clear();
    for (var item in items) {
      _cart[item.name] = Pizza(
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        type: item.type,
      );
    }
    notifyListeners();
  }
}
