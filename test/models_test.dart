import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_pizza/models/pizza.dart';
import 'package:turbo_pizza/models/encaissement.dart';

void main() {
  group('Pizza Model Tests', () {
    test('Pizza creation and total price calculation', () {
      final pizza = Pizza(
        name: 'Margherita',
        price: 12.50,
        quantity: 2,
        type: 'Tomate',
      );

      expect(pizza.name, 'Margherita');
      expect(pizza.totalPrice, 25.0);
    });

    test('Pizza JSON serialization', () {
      final pizza = Pizza(
        name: 'Margherita',
        price: 12.50,
        quantity: 1,
        type: 'Tomate',
      );

      final json = pizza.toJson();
      final fromJson = Pizza.fromJson(json);

      expect(fromJson.name, pizza.name);
      expect(fromJson.price, pizza.price);
      expect(fromJson.type, pizza.type);
    });
  });

  group('Encaissement Model Tests', () {
    test('Encaissement creation', () {
      final articles = [
        Pizza(name: 'Margherita', price: 12.50, quantity: 1, type: 'Tomate'),
      ];

      final encaissement = Encaissement(
        date: DateTime.now(),
        montant: 12.50,
        modeReglement: 'Espèces',
        articles: articles,
      );

      expect(encaissement.montant, 12.50);
      expect(encaissement.modeReglement, 'Espèces');
      expect(encaissement.articles.length, 1);
    });
  });
}
