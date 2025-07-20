import 'package:flutter/material.dart';
import '../models/pizza.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';

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
  List<String> pizzaTypes = ['Tomate', 'Crème', 'Mois', 'Softs', 'Vins', 'Spécialités', 'Glaces', 'Desserts'];
  String selectedType = 'Tomate'; // La valeur par défaut

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
    StorageService.savePizzaList(widget.availablePizzas);
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
      selectedType = 'Tomate'; // Réinitialiser à la valeur par défaut
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
                    StorageService.savePizzaList(widget.availablePizzas);
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
