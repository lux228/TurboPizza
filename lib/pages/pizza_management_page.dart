// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../models/pizza.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';
import '../constants/app_constants.dart';

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
  List<String> pizzaTypes = AppConstants.categoryOrder;
  String selectedType = AppConstants.categoryOrder.first;

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
          title: Text(pizza != null ? 'Modifier produit' : 'Ajouter produit'),
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

  void _showDeleteConfirmationDialog(Pizza pizza) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${pizza.name}" ?\n\nCette action est irréversible.',
            style: const TextStyle(fontSize: AppConstants.subtitleFontSize),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                setState(() {
                  widget.availablePizzas.removeAt(
                    widget.availablePizzas.indexWhere((p) => p.name == pizza.name)
                  );
                });
                widget.onUpdate();
                StorageService.savePizzaList(widget.availablePizzas);
                
                // Afficher un message de confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${pizza.name} supprimé avec succès'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String type) {
    return AppConstants.productTypeBackgroundColors[type] ?? Colors.grey[100]!;
  }

  @override
  Widget build(BuildContext context) {
    // Regrouper les pizzas par type
    Map<String, List<Pizza>> groupedPizzas = {};
    for (var pizza in widget.availablePizzas) {
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
        
        // En-tête de catégorie
        categoryWidgets.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(top: 8.0),
            color: _getCategoryColor(categoryType),
            child: Text(
              categoryType.toUpperCase(),
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        );

        // Items de la catégorie en grille 2 colonnes
        categoryWidgets.add(
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 7.0, // Ratio beaucoup plus élevé pour des cartes très fines
            ),
            itemCount: pizzas.length,
            itemBuilder: (context, index) {
              final pizza = pizzas[index];
              
              return Card(
                elevation: 2,
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border(
                      left: BorderSide(
                        color: _getCategoryColor(categoryType).withValues(alpha: 0.8),
                        width: 4.0,
                      ),
                    ),
                  ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pizza.name,
                              style: const TextStyle(
                                fontSize: AppConstants.mediumFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formatPrice(pizza.price),
                              style: const TextStyle(
                                fontSize: AppConstants.bodyFontSize,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            iconSize: 22,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditPizzaDialog(pizza: pizza),
                          ),
                          IconButton(
                            iconSize: 22,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(pizza),
                          ),
                        ],
                      ),
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
      appBar: AppBar(title: const Text(AppConstants.productManagementTitle)),
      body: widget.availablePizzas.isEmpty
          ? const Center(
              child: Text(
                AppConstants.noProductsMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppConstants.subtitleFontSize, color: Colors.grey),
              ),
            )
          : ListView(children: categoryWidgets),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddEditPizzaDialog(),
      ),
    );
  }
}
