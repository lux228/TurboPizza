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
      final double? amountGiven = result['amountGiven'];

      setState(() {
        modeReglement = selectedMethod;
      });

      double amountToReturn =
          0.0; // Définissez amountToReturn ici pour qu'elle soit accessible dans toute la méthode

      if (selectedMethod == 'Espèces' && amountGiven != null) {
        amountToReturn = amountGiven - totalCartPrice;
        // Affichage du montant à rendre si nécessaire
        if (amountToReturn > 0) {
          // Assurez-vous que amountToReturn est positif avant d'afficher le dialogue
          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Rendu de monnaie',
                    style: TextStyle(fontSize: 20)),
                content: Text(
                    'Montant à rendre : ${formatPrice(amountToReturn)}',
                    style: const TextStyle(fontSize: 18)),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK', style: TextStyle(fontSize: 18)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        }
      }

      // Enregistrement de l'encaissement avec le montant total et le mode de règlement
      StorageService.saveEncaissement(Encaissement(
        date: DateTime.now(),
        montant: totalCartPrice,
        modeReglement: modeReglement,
        commentaire: selectedMethod == 'Espèces' && amountGiven != null
            ? 'Montant donné: ${formatPrice(amountGiven)}, Montant à rendre: ${formatPrice(amountToReturn)}'
            : '',
      ));

      // Nettoyage du panier
      setState(() {
        cart.clear();
      });

      // Affichage d'un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encaissement réalisé avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Regrouper et trier les pizzas par type
    Map<String, List<Pizza>> groupedPizzas = {};
    for (var pizza in availablePizzas) {
      groupedPizzas.putIfAbsent(pizza.type, () => []).add(pizza);
    }
    for (var group in groupedPizzas.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }

    List<Widget> categoryWidgets = [];
    groupedPizzas.forEach((type, pizzas) {
      categoryWidgets.add(
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            type.toUpperCase(),
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
    });

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
              title: const Text('Gestion des Pizzas'),
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
            flex: 2, // Ajuster la flexibilité selon la préférence d'affichage
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
                    child: Row(
                      children: [
                        Text(
                          "Total: ${formatPrice(totalCartPrice)}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(), // Ajoute un espace flexible qui pousse les widgets suivants vers la droite
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.grey[300],
                            minimumSize: const Size(120, 75),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => const CalculatorDialog(),
                            );
                          },
                          child: const Icon(Icons.calculate, size: 30),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.lightBlue[100],
                            minimumSize: const Size(225, 75),
                            textStyle: const TextStyle(fontSize: 20),
                          ),
                          onPressed: checkout,
                          child: const Text("Encaisser"),
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
