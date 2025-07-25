import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/pizza.dart';
import '../models/encaissement.dart';
import '../models/commande_attente.dart';

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

  // Méthodes pour les commandes en attente
  static Future<void> saveCommandeAttente(CommandeAttente commande) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> commandes = prefs.getStringList('commandes_attente') ?? [];
    commandes.add(json.encode(commande.toJson()));
    await prefs.setStringList('commandes_attente', commandes);
  }

  static Future<List<CommandeAttente>> loadCommandesAttente() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? commandesJson = prefs.getStringList('commandes_attente');
    return commandesJson
            ?.map((string) => CommandeAttente.fromJson(json.decode(string)))
            .toList() ??
        [];
  }

  static Future<void> saveCommandesAttente(List<CommandeAttente> commandes) async {
    final prefs = await SharedPreferences.getInstance();
    final commandesJson = commandes.map((commande) {
      return json.encode(commande.toJson());
    }).toList();
    await prefs.setStringList('commandes_attente', commandesJson);
  }

  static Future<void> removeCommandeAttente(String commandeId) async {
    final commandes = await loadCommandesAttente();
    final updatedCommandes = commandes.where((c) => c.id != commandeId).toList();
    await saveCommandesAttente(updatedCommandes);
  }
}
