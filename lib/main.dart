import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TurboPizza',
      home: PizzaHomePage(),
    );
  }
}

String formatPrice(double price) {
  final NumberFormat formatter = NumberFormat('0.00', 'fr_FR');
  return '${formatter.format(price)}€';
}

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
    loadPizzaList().then((loadedPizzas) {
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
      saveEncaissement(Encaissement(
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

  Future<void> saveEncaissement(Encaissement encaissement) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encaissements = prefs.getStringList('encaissements') ?? [];
    encaissements.add(json.encode(encaissement.toJson()));
    await prefs.setStringList('encaissements', encaissements);
  }

  Future<List<Encaissement>> loadEncaissements() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? encaissementsJson = prefs.getStringList('encaissements');
    return encaissementsJson
            ?.map((string) => Encaissement.fromJson(json.decode(string)))
            .toList() ??
        [];
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
              case 'tomate':
                color = Colors.red[100];
                break;
              case 'crème':
                color = Colors.blue[100];
                break;
              case 'mois':
                color = Colors.green[100];
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

Future<List<Pizza>> loadPizzaList() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? pizzaJson = prefs.getStringList('pizzas');
  return pizzaJson
          ?.map((string) => Pizza.fromJson(json.decode(string)))
          .toList() ??
      [];
}

void savePizzaList(List<Pizza> pizzas) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> pizzaJson =
      pizzas.map((pizza) => json.encode(pizza.toJson())).toList();
  await prefs.setStringList('pizzas', pizzaJson);
}

class PizzaManagementPage extends StatefulWidget {
  final List<Pizza> availablePizzas;
  final Function onUpdate;

  const PizzaManagementPage(
      {super.key, required this.availablePizzas, required this.onUpdate});

  @override
  _PizzaManagementPageState createState() => _PizzaManagementPageState();
}

class _PizzaManagementPageState extends State<PizzaManagementPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  List<String> pizzaTypes = ['tomate', 'crème', 'mois'];
  String selectedType = 'tomate'; // La valeur par défaut

  void _addOrUpdatePizza({String? originalName}) {
    final newOrUpdatedPizza = Pizza(
      name: _nameController.text,
      price: double.parse(_priceController.text),
      type: selectedType, // Utiliser le type sélectionné
      quantity: originalName == null
          ? 0
          : widget.availablePizzas
              .firstWhere((p) => p.name == originalName)
              .quantity,
    );

    setState(() {
      if (originalName != null) {
        final index =
            widget.availablePizzas.indexWhere((p) => p.name == originalName);
        if (index != -1) {
          widget.availablePizzas[index] = newOrUpdatedPizza;
        }
      } else {
        widget.availablePizzas.add(newOrUpdatedPizza);
      }
    });
    widget.onUpdate();
    savePizzaList(widget.availablePizzas);
    Navigator.of(context).pop();
  }

  void _showAddEditPizzaDialog({Pizza? pizza}) {
    if (pizza != null) {
      _nameController.text = pizza.name;
      _priceController.text = pizza.price.toString();
      selectedType = pizza.type; // Définir le type actuel
    } else {
      _nameController.clear();
      _priceController.clear();
      selectedType = 'tomate'; // Réinitialiser à la valeur par défaut
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pizza != null ? 'Modifier Pizza' : 'Ajouter Pizza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              DropdownButtonFormField<String>(
                value: selectedType, // Initialiser avec le type actuel
                decoration: const InputDecoration(labelText: 'Type'),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
                items: pizzaTypes.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sauvegarder'),
              onPressed: () => _addOrUpdatePizza(originalName: pizza?.name),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer Pizzas')),
      body: ListView.builder(
        itemCount: widget.availablePizzas.length,
        itemBuilder: (context, index) {
          final pizza = widget.availablePizzas[index];
          Color bgColor = index % 2 == 0
              ? Colors.grey[200]!
              : Colors.white; // Couleurs alternées

          return ListTile(
            tileColor: bgColor, // Applique la couleur alternée
            title: Text(pizza.name),
            subtitle: Text(formatPrice(pizza.price)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showAddEditPizzaDialog(pizza: pizza),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      widget.availablePizzas.removeAt(index);
                    });
                    widget.onUpdate();
                    savePizzaList(widget.availablePizzas);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddEditPizzaDialog(),
      ),
    );
  }
}

class EncaissementHistoryPage extends StatefulWidget {
  const EncaissementHistoryPage({super.key});

  @override
  _EncaissementHistoryPageState createState() =>
      _EncaissementHistoryPageState();
}

class _EncaissementHistoryPageState extends State<EncaissementHistoryPage> {
  DateTime selectedDate = DateTime.now();
  List<Encaissement> encaissements = [];
  List<Encaissement> filteredEncaissements = [];

  double totalCheques = 0.0;
  double totalEspeces = 0.0;
  double totalGroupe = 0.0;

  double totalPointeCheques = 0.0;
  double totalPointeEspeces = 0.0;
  double totalPointeGroupe = 0.0;

  @override
  void initState() {
    super.initState();
    loadEncaissements().then((loadedEncaissements) {
      setState(() {
        encaissements = loadedEncaissements;
        filterEncaissements();
      });
    });
  }

  Future<List<Encaissement>> loadEncaissements() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? encaissementsJson = prefs.getStringList('encaissements');
    return encaissementsJson
            ?.map((string) => Encaissement.fromJson(json.decode(string)))
            .toList() ??
        [];
  }

  void filterEncaissements() {
    setState(() {
      filteredEncaissements = encaissements
          .where((encaissement) =>
              encaissement.date.year == selectedDate.year &&
              encaissement.date.month == selectedDate.month &&
              encaissement.date.day == selectedDate.day)
          .toList();
    });

    // Réinitialiser les totaux
    totalCheques = 0.0;
    totalEspeces = 0.0;

    // Calculer les totaux
    for (var encaissement in filteredEncaissements) {
      if (encaissement.modeReglement == "Chèque") {
        totalCheques += encaissement.montant;
      } else if (encaissement.modeReglement == "Espèces") {
        totalEspeces += encaissement.montant;
      }
    }
    totalGroupe = totalEspeces + totalCheques;
  }

  void _saveEncaissements(List<Encaissement> encaissements) async {
    final prefs = await SharedPreferences.getInstance();
    final encaissementsJson = encaissements.map((encaissement) {
      return json.encode(encaissement.toJson());
    }).toList();
    await prefs.setStringList('encaissements', encaissementsJson);
  }

  void _deleteEncaissement(Encaissement encaissement) {
    // Supprimer l'encaissement de la liste
    setState(() {
      encaissements.remove(encaissement);
    });

    // Enregistrer les modifications dans SharedPreferences
    _saveEncaissements(encaissements);

    // Mettre à jour la liste filtrée après la suppression
    filterEncaissements();
  }

  void calculatePointedTotals() {
    totalPointeCheques = 0.0;
    totalPointeEspeces = 0.0;
    totalPointeGroupe = 0.0;

    for (var encaissement in filteredEncaissements) {
      if (encaissement.isSelected) {
        if (encaissement.modeReglement == "Chèque") {
          totalPointeCheques += encaissement.montant;
        } else if (encaissement.modeReglement == "Espèces") {
          totalPointeEspeces += encaissement.montant;
        }
      }
    }
    totalPointeGroupe = totalPointeEspeces + totalPointeCheques;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2099));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        filterEncaissements();
      });
    }
  }

  void _toggleEncaissementSelection(Encaissement encaissement) {
    setState(() {
      encaissement.isSelected = !encaissement.isSelected;
      calculatePointedTotals(); // Recalculer les totaux après chaque changement
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Historique des Encaissements"),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sélectionner la date:",
                  style: TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text("${selectedDate.toLocal()}".split(' ')[0]),
                ),
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: filteredEncaissements.length,
                  itemBuilder: (context, index) {
                    var encaissement = filteredEncaissements[index];
                    // ignore: unused_local_variable
                    String formattedDate = DateFormat('dd/MM/yyyy à H:mm')
                        .format(encaissement.date);

                    // Utiliser l'index pour alterner la couleur de fond
                    Color bgColor = index % 2 == 0
                        ? Colors.grey[200]!
                        : Colors.white; // Couleurs alternées

                    return ListTile(
                        tileColor: bgColor, // Appliquer la couleur de fond
                        leading: Checkbox(
                          value: encaissement.isSelected,
                          onChanged: (bool? value) {
                            _toggleEncaissementSelection(encaissement);
                          },
                        ),
                        title: Text(
                          "Montant: ${formatPrice(encaissement.montant)}",
                          style: TextStyle(
                            color: encaissement.isSelected ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          "Mode: ${encaissement.modeReglement}",
                          style: TextStyle(
                            color: encaissement.isSelected ? Colors.grey : null,
                          ),
                        ),
                        trailing:
                            PopupMenuButton<String>(itemBuilder: (context) {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ];
                        }, onSelected: (String value) {
                          if (value == 'delete') {
                            _deleteEncaissement(encaissement);
                          }
                        }));
                  })),
          Container(
              color: Colors
                  .lightBlue[100], // Définit la couleur de fond pour les totaux
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "Total pointé Chèques: ${formatPrice(totalPointeCheques)}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total pointé Espèces: ${formatPrice(totalPointeEspeces)}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total pointé: ${formatPrice(totalPointeGroupe)}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Total Chèques: ${formatPrice(totalCheques)}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Total Espèces: ${formatPrice(totalEspeces)}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Total: ${formatPrice(totalGroupe)}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ])
              ]))
        ]));
  }
}

class PaymentMethodDialog extends StatefulWidget {
  final String currentSelection;

  const PaymentMethodDialog({Key? key, required this.currentSelection})
      : super(key: key);

  @override
  _PaymentMethodDialogState createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  final _amountGivenController = TextEditingController();

  ElevatedButton _createLargeButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 50), // Agrandit le bouton
        textStyle: const TextStyle(fontSize: 18), // Agrandit le texte
      ),
      child: Text(text),
    );
  }

  void _handlePaymentMethodSelection(String method) {
    if (method == 'Espèces') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Espèces'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _createLargeButton('Appoint', () {
                  Navigator.of(context)
                      .pop(); // Ferme le dialogue intermédiaire
                  Navigator.of(context)
                      .pop({'method': method}); // Envoie "Espèces" sans montant
                }),
                const SizedBox(
                    height: 20), // Ajoute un espace entre les boutons
                _createLargeButton('Rendu monnaie', () {
                  Navigator.of(context)
                      .pop(); // Ferme le dialogue intermédiaire
                  _showEnterAmountDialog(); // Affiche le dialogue pour entrer le montant donné
                }),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.of(context).pop({'method': method});
    }
  }

  void _showEnterAmountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Montant donné par le client'),
          content: TextField(
            controller: _amountGivenController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Montant donné'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                final double amountGiven =
                    double.tryParse(_amountGivenController.text) ?? 0.0;
                Navigator.of(context)
                    .pop(); // Ferme le dialogue de montant donné
                Navigator.of(context).pop({
                  'method': 'Espèces',
                  'amountGiven': amountGiven
                }); // Envoie le montant donné
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Choisir le mode de règlement"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _createLargeButton(
              "Espèces", () => _handlePaymentMethodSelection("Espèces")),
          const SizedBox(height: 20), // Ajoute un espace entre les boutons
          _createLargeButton(
              "Chèque", () => _handlePaymentMethodSelection("Chèque")),
        ],
      ),
    );
  }
}

class Encaissement {
  DateTime date;
  double montant;
  String modeReglement;
  String commentaire;
  bool isSelected;

  Encaissement({
    required this.date,
    required this.montant,
    required this.modeReglement,
    this.commentaire = '',
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'montant': montant,
        'modeReglement': modeReglement,
      };

  static Encaissement fromJson(Map<String, dynamic> json) => Encaissement(
        date: DateTime.parse(json['date']),
        montant: json['montant'],
        modeReglement: json['modeReglement'],
      );
}
