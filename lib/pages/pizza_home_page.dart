import 'package:flutter/material.dart';
import '../models/pizza.dart';
import '../models/encaissement.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/calculator_dialog.dart';
import 'pizza_management_page.dart';
import 'encaissement_history_page.dart';

class PizzaHomePage extends StatefulWidget {
  const PizzaHomePage({super.key});

  @override
  _PizzaHomePageState createState() => _PizzaHomePageState();
}

class _PizzaHomePageState extends State<PizzaHomePage> {
  List<Pizza> availablePizzas = [];
  Map<String, Pizza> cart = {};

  @override
  void initState() {
    super.initState();
    StorageService.loadPizzaList().then((loadedPizzas) {
      setState(() {
        availablePizzas = loadedPizzas;
      });
    });
  }

  void addToCart(Pizza pizza) {
    setState(() {
      if (cart.containsKey(pizza.name)) {
        cart[pizza.name]!.quantity++;
      } else {
        cart[pizza.name] = Pizza(
            name: pizza.name,
            price: pizza.price,
            quantity: 1,
            type: pizza.type);
      }
    });
  }

  void adjustQuantity(String name, int change) {
    setState(() {
      if (cart.containsKey(name)) {
        cart[name]!.quantity += change;
        if (cart[name]!.quantity <= 0) {
          cart.remove(name);
        }
      }
    });
  }

  double get totalCartPrice =>
      cart.values.fold(0, (total, current) => total + current.totalPrice);

  String modeReglement =
      "Espèces"; // Ajout d'une variable d'état pour le mode de règlement

  void checkout() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) =>
          PaymentMethodDialog(currentSelection: modeReglement),
    );

    if (result != null) {
      final String selectedMethod = result['method'];

      setState(() {
        modeReglement = selectedMethod;
      });

      // Enregistrement de l'encaissement avec le montant total, le mode de règlement et les articles
      StorageService.saveEncaissement(Encaissement(
        date: DateTime.now(),
        montant: totalCartPrice,
        modeReglement: modeReglement,
        articles: cart.values.toList(),
      ));

      // Nettoyage du panier
      setState(() {
        cart.clear();
      });

      // Affichage d'un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Encaissement réalisé avec succès'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: 30,
            left: MediaQuery.of(context).size.width * 0.25,
            right: MediaQuery.of(context).size.width * 0.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.green[600],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Regrouper les pizzas par type
    Map<String, List<Pizza>> groupedPizzas = {};
    for (var pizza in availablePizzas) {
      groupedPizzas.putIfAbsent(pizza.type, () => []).add(pizza);
    }
    for (var group in groupedPizzas.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }

    // Ordre spécifique des catégories
    const categoryOrder = [
      'Tomate',
      'Crème', 
      'Spécialités',
      'Softs',
      'Vins',
      'Desserts',
      'Glaces'
    ];

    List<Widget> categoryWidgets = [];
    
    // Afficher les catégories dans l'ordre spécifié
    for (String categoryType in categoryOrder) {
      if (groupedPizzas.containsKey(categoryType)) {
        List<Pizza> pizzas = groupedPizzas[categoryType]!;
        
        categoryWidgets.add(
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              categoryType.toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        );

        categoryWidgets.add(
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Pour éviter le défilement imbriqué
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  6, // Modifiez cette ligne pour afficher x éléments par ligne
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: pizzas.length,
            itemBuilder: (context, index) {
              Pizza pizza = pizzas[index];
              Color? color;
              switch (pizza.type) {
                case 'Tomate':
                  color = Colors.red[100];
                  break;
                case 'Crème':
                  color = Colors.blue[100];
                  break;
                case 'Softs':
                  color = Colors.amber[100];
                  break;
                case 'Vins':
                  color = Colors.orange[100];
                  break;
                case 'Spécialités':
                  color = Colors.green[100];
                  break;
                case 'Glaces':
                  color = Colors.purple[100];
                  break;
                case 'Desserts':
                  color = Colors.pink[100];
                  break;
              }

              return GestureDetector(
                onTap: () => addToCart(pizza),
                child: Card(
                  color: color,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(pizza.name, style: const TextStyle(fontSize: 18)),
                        Text(formatPrice(pizza.price),
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('TurboPizza')),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu',
                  style: TextStyle(fontSize: 26, color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Gestion des produits'),
              onTap: () {
                Navigator.pop(context);
                openPizzaManagementPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historique des Encaissements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EncaissementHistoryPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3, // Augmenté de 2 à 3 pour donner plus d'espace à la liste des pizzas
            child: SingleChildScrollView(
              child: Column(children: categoryWidgets),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey,
          ),
          Expanded(
            flex: 1, // Reste à 1 pour que le panier prenne moins de place
            child: Container(
              color: Colors.grey[200],
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: cart.values.map((pizza) {
                        return ListTile(
                          tileColor: Colors.amber[100],
                          title: Text("${pizza.name} x${pizza.quantity}"),
                          subtitle: Text(formatPrice(pizza.price)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => adjustQuantity(pizza.name, -1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => adjustQuantity(pizza.name, 1),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // Ligne avec le total et la calculatrice
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Total: ${formatPrice(totalCartPrice)}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white,
                                elevation: 3,
                                minimumSize: const Size(100, 60),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => const CalculatorDialog(),
                                );
                              },
                              child: const Icon(Icons.calculate, size: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Bouton encaisser en pleine largeur
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: cart.isEmpty ? Colors.grey : Colors.black,
                              backgroundColor: cart.isEmpty ? Colors.grey[300] : Colors.lightBlue[100],
                              textStyle: const TextStyle(fontSize: 20),
                            ),
                            onPressed: cart.isEmpty ? null : checkout,
                            child: Text(cart.isEmpty ? "Panier vide" : "Encaisser"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openPizzaManagementPage() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => PizzaManagementPage(
              availablePizzas: availablePizzas,
              onUpdate: () => setState(() {}),
            ),
          ),
        )
        .then((_) => setState(() {}));
  }
}
