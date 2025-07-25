import 'package:flutter/material.dart';
import 'dart:async';
import '../models/pizza.dart';
import '../models/encaissement.dart';
import '../models/commande_attente.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/calculator_dialog.dart';
import '../widgets/pickup_time_dialog.dart';
import 'pizza_management_page.dart';
import 'encaissement_history_page.dart';

class PizzaHomePage extends StatefulWidget {
  const PizzaHomePage({super.key});

  @override
  _PizzaHomePageState createState() => _PizzaHomePageState();
}

class _PizzaHomePageState extends State<PizzaHomePage> with TickerProviderStateMixin {
  List<Pizza> availablePizzas = [];
  Map<String, Pizza> cart = {};
  List<CommandeAttente> commandesAttente = [];
  bool showCurrentOrder = false; // Pour contrôler l'affichage de la commande en cours
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadData();
    
    // Timer pour mettre à jour les statuts toutes les minutes
    _statusUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && commandesAttente.isNotEmpty) {
        setState(() {
          // Force la reconstruction pour mettre à jour les couleurs des statuts
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _loadData() async {
    final loadedPizzas = await StorageService.loadPizzaList();
    final loadedCommandes = await StorageService.loadCommandesAttente();
    setState(() {
      availablePizzas = loadedPizzas;
      commandesAttente = loadedCommandes;
      // Trier les commandes par heure de récupération
      commandesAttente.sort((a, b) => a.heureRecuperationDateTime.compareTo(b.heureRecuperationDateTime));
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
      
      // Afficher la commande en cours avec animation quand on ajoute un produit
      if (!showCurrentOrder) {
        showCurrentOrder = true;
        _animationController.forward();
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
      // Masquer la commande en cours avec animation si le panier est vide
      if (cart.isEmpty && showCurrentOrder) {
        _animationController.reverse().then((_) {
          setState(() {
            showCurrentOrder = false;
          });
        });
      }
    });
  }

  double get totalCartPrice =>
      cart.values.fold(0, (total, current) => total + current.totalPrice);

  // Méthode pour déterminer le statut d'une commande selon l'heure
  Map<String, dynamic> getOrderStatus(CommandeAttente commande) {
    final now = DateTime.now();
    final pickupTime = commande.heureRecuperationDateTime;
    final difference = pickupTime.difference(now).inMinutes;

    if (difference < -10) {
      // Plus de 10 minutes de retard
      return {
        'status': 'En retard',
        'color': Colors.red[600]!,
        'backgroundColor': Colors.red[50]!,
        'icon': Icons.warning,
      };
    } else if (difference < 0) {
      // Légèrement en retard (moins de 10 minutes)
      return {
        'status': 'Légèrement en retard',
        'color': Colors.orange[700]!,
        'backgroundColor': Colors.orange[50]!,
        'icon': Icons.access_time,
      };
    } else if (difference <= 15) {
      // Bientôt là (dans les 15 prochaines minutes)
      return {
        'status': 'Bientôt là',
        'color': Colors.orange[600]!,
        'backgroundColor': Colors.orange[50]!,
        'icon': Icons.schedule,
      };
    } else {
      // À l'heure (plus de 15 minutes d'avance)
      return {
        'status': 'À l\'heure',
        'color': Colors.green[600]!,
        'backgroundColor': Colors.green[50]!,
        'icon': Icons.check_circle,
      };
    }
  }

  // Méthode pour encaisser directement une commande
  void checkoutDirect() async {
    if (cart.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) =>
          PaymentMethodDialog(currentSelection: "Espèces"),
    );

    if (result != null) {
      final String selectedMethod = result['method'];

      // Enregistrement de l'encaissement avec le montant total, le mode de règlement et les articles
      await StorageService.saveEncaissement(Encaissement(
        date: DateTime.now(),
        montant: totalCartPrice,
        modeReglement: selectedMethod,
        articles: cart.values.toList(),
      ));

      // Nettoyage du panier
      setState(() {
        cart.clear();
        if (showCurrentOrder) {
          _animationController.reverse().then((_) {
            setState(() {
              showCurrentOrder = false;
            });
          });
        }
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
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  // Nouvelle méthode pour mettre une commande en attente
  void putOrderOnHold() async {
    if (cart.isEmpty) return;

    final selectedTime = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const PickupTimeDialog(),
    );

    if (selectedTime != null) {
      final commande = CommandeAttente(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        heureComposition: DateTime.now(),
        heureRecuperationPrevue: selectedTime,
        articles: cart.values.toList(),
        montant: totalCartPrice,
      );

      await StorageService.saveCommandeAttente(commande);
      
      setState(() {
        commandesAttente.add(commande);
        // Trier les commandes par heure de récupération
        commandesAttente.sort((a, b) => a.heureRecuperationDateTime.compareTo(b.heureRecuperationDateTime));
        cart.clear();
        if (showCurrentOrder) {
          _animationController.reverse().then((_) {
            setState(() {
              showCurrentOrder = false;
            });
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.access_time, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Commande mise en attente'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange[600],
        ),
      );
    }
  }

  // Méthode pour valider la récupération d'une commande
  void validatePickup(CommandeAttente commande) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) =>
          PaymentMethodDialog(currentSelection: "Espèces"),
    );

    if (result != null) {
      final String selectedMethod = result['method'];

      // Créer un encaissement à partir de la commande
      final encaissement = Encaissement(
        date: DateTime.now(),
        montant: commande.montant,
        modeReglement: selectedMethod,
        articles: commande.articles,
      );

      await StorageService.saveEncaissement(encaissement);
      await StorageService.removeCommandeAttente(commande.id);

      setState(() {
        commandesAttente.removeWhere((c) => c.id == commande.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Commande validée et encaissée'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  // Méthode pour afficher l'aperçu d'une commande en attente
  void showOrderPreview(CommandeAttente commande) {
    final orderStatus = getOrderStatus(commande);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Aperçu de la commande',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de la commande avec statut
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: orderStatus['backgroundColor'],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: orderStatus['color'], width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statut de la commande
                      Row(
                        children: [
                          Icon(
                            orderStatus['icon'],
                            color: orderStatus['color'],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            orderStatus['status'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: orderStatus['color'],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Heure de composition :',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${commande.heureComposition.hour.toString().padLeft(2, '0')}:${commande.heureComposition.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Heure de récupération :',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            commande.heureRecuperationPrevue,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: orderStatus['color'],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Montant total :',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            formatPrice(commande.montant),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Articles commandés :',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: commande.articles.length,
                      itemBuilder: (context, index) {
                        var article = commande.articles[index];
                        
                        // Déterminer la couleur selon le type
                        Color borderColor;
                        switch (article.type) {
                          case 'Tomate':
                            borderColor = Colors.red[300]!;
                            break;
                          case 'Crème':
                            borderColor = Colors.blue[300]!;
                            break;
                          case 'Softs':
                            borderColor = Colors.amber[300]!;
                            break;
                          case 'Vins':
                            borderColor = Colors.orange[300]!;
                            break;
                          case 'Spécialités':
                            borderColor = Colors.green[300]!;
                            break;
                          case 'Glaces':
                            borderColor = Colors.purple[300]!;
                            break;
                          case 'Desserts':
                            borderColor = Colors.pink[300]!;
                            break;
                          default:
                            borderColor = Colors.grey[300]!;
                        }
                        
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: borderColor, width: 4),
                            ),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      article.type,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'x${article.quantity}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatPrice(article.price),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                editOrderOnHold(commande);
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                validatePickup(commande);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[800],
              ),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour modifier une commande en attente
  void editOrderOnHold(CommandeAttente commande) async {
    // Remettre la commande dans le panier
    setState(() {
      cart.clear();
      for (var article in commande.articles) {
        cart[article.name] = Pizza(
          name: article.name,
          price: article.price,
          quantity: article.quantity,
          type: article.type,
        );
      }
      
      // Afficher la commande en cours avec animation
      if (!showCurrentOrder) {
        showCurrentOrder = true;
        _animationController.forward();
      }
    });

    // Supprimer la commande de la file d'attente
    await StorageService.removeCommandeAttente(commande.id);
    setState(() {
      commandesAttente.removeWhere((c) => c.id == commande.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande remise en composition'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Méthode pour annuler une commande en attente
  void cancelOrderOnHold(CommandeAttente commande) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer l\'annulation'),
          content: Text(
            'Êtes-vous sûr de vouloir annuler cette commande ?\n\nHeure de récupération : ${commande.heureRecuperationPrevue}\nMontant : ${formatPrice(commande.montant)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await StorageService.removeCommandeAttente(commande.id);
      setState(() {
        commandesAttente.removeWhere((c) => c.id == commande.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande annulée'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
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
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
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
          // 2/3 gauche : liste des produits
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(children: categoryWidgets),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey,
          ),
          // 1/3 droite : file d'attente + composition
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Partie haute : File d'attente des commandes
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.lightBlue[50],
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          color: Colors.lightBlue[100],
                          child: Column(
                            children: [
                              const Text(
                                'COMMANDES EN ATTENTE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Toucher pour voir le détail',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: commandesAttente.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aucune commande en attente',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount: commandesAttente.length,
                                  itemBuilder: (context, index) {
                                    final commande = commandesAttente[index];
                                    final orderStatus = getOrderStatus(commande);
                                    
                                    return GestureDetector(
                                      onTap: () => showOrderPreview(commande),
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 8.0),
                                        elevation: 2,
                                        color: orderStatus['backgroundColor'],
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: orderStatus['color'],
                                              width: 2,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          orderStatus['icon'],
                                                          size: 16,
                                                          color: orderStatus['color'],
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Récup: ${commande.heureRecuperationPrevue}',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '(${commande.heureComposition.hour.toString().padLeft(2, '0')}:${commande.heureComposition.minute.toString().padLeft(2, '0')})',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey[600],
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: Center(
                                                        child: Text(
                                                          orderStatus['status'],
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: orderStatus['color'],
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      formatPrice(commande.montant),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  commande.articles
                                                      .map((a) => '${a.name} x${a.quantity}')
                                                      .join(', '),
                                                  style: const TextStyle(fontSize: 12),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () => validatePickup(commande),
                                                        icon: const Icon(Icons.check, size: 16),
                                                        label: const Text('Valider', style: TextStyle(fontSize: 12)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green[100],
                                                          foregroundColor: Colors.green[800],
                                                          minimumSize: const Size(0, 32),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () => editOrderOnHold(commande),
                                                        icon: const Icon(Icons.edit, size: 16),
                                                        label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.orange[100],
                                                          foregroundColor: Colors.orange[800],
                                                          minimumSize: const Size(0, 32),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () => cancelOrderOnHold(commande),
                                                        icon: const Icon(Icons.delete, size: 16),
                                                        label: const Text('Annuler', style: TextStyle(fontSize: 12)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red[100],
                                                          foregroundColor: Colors.red[800],
                                                          minimumSize: const Size(0, 32),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                // Partie basse : Composition actuelle avec animation depuis le bas
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: showCurrentOrder ? _slideAnimation.value : 0.0,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.4, // Hauteur fixe
                          color: Colors.grey[200],
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12.0),
                                color: Colors.grey[300],
                                child: const Text(
                                  'COMMANDE EN COURS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
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
                                              builder: (BuildContext context) => CalculatorDialog(
                                                currentOrderTotal: totalCartPrice,
                                              ),
                                            );
                                          },
                                          child: const Icon(Icons.calculate, size: 28),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Deux boutons : Mettre en attente et Encaisser directement
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 50,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: cart.isEmpty ? Colors.grey : Colors.black,
                                                backgroundColor: cart.isEmpty ? Colors.grey[300] : Colors.orange[100],
                                                textStyle: const TextStyle(fontSize: 16),
                                              ),
                                              onPressed: cart.isEmpty ? null : putOrderOnHold,
                                              child: Text(cart.isEmpty ? "Panier vide" : "En attente"),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 50,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: cart.isEmpty ? Colors.grey : Colors.black,
                                                backgroundColor: cart.isEmpty ? Colors.grey[300] : Colors.green[100],
                                                textStyle: const TextStyle(fontSize: 16),
                                              ),
                                              onPressed: cart.isEmpty ? null : checkoutDirect,
                                              child: Text(cart.isEmpty ? "Panier vide" : "Encaisser"),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
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
