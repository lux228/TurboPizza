import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/pizza.dart';
import '../models/encaissement.dart';

class StorageService {
  static Future<List<Pizza>> loadPizzaList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? pizzaJson = prefs.getStringList('pizzas');
    return pizzaJson
            ?.map((string) => Pizza.fromJson(json.decode(string)))
            .toList() ??
        [];
  }

  static Future<void> savePizzaList(List<Pizza> pizzas) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pizzaJson =
        pizzas.map((pizza) => json.encode(pizza.toJson())).toList();
    await prefs.setStringList('pizzas', pizzaJson);
  }

  static Future<void> saveEncaissement(Encaissement encaissement) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encaissements = prefs.getStringList('encaissements') ?? [];
    encaissements.add(json.encode(encaissement.toJson()));
    await prefs.setStringList('encaissements', encaissements);
  }

  static Future<List<Encaissement>> loadEncaissements() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? encaissementsJson = prefs.getStringList('encaissements');
    return encaissementsJson
            ?.map((string) => Encaissement.fromJson(json.decode(string)))
            .toList() ??
        [];
  }

  static Future<void> saveEncaissements(List<Encaissement> encaissements) async {
    final prefs = await SharedPreferences.getInstance();
    final encaissementsJson = encaissements.map((encaissement) {
      return json.encode(encaissement.toJson());
    }).toList();
    await prefs.setStringList('encaissements', encaissementsJson);
  }
}
