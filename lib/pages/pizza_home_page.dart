import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/pizza.dart';
import '../models/encaissement.dart';
import '../models/commande_attente.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';
import '../utils/cache_service.dart';
import '../widgets/lazy_order_list.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/calculator_dialog.dart';
import '../widgets/pickup_time_dialog.dart';
import '../widgets/product_grid.dart';
import '../widgets/current_order_widget.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../constants/app_constants.dart';
import 'pizza_management_page.dart';
import 'encaissement_history_page.dart';

class PizzaHomePage extends StatefulWidget {
  const PizzaHomePage({super.key});

  @override
  _PizzaHomePageState createState() => _PizzaHomePageState();
}

class _PizzaHomePageState extends State<PizzaHomePage> with TickerProviderStateMixin {
  List<Pizza> availablePizzas = [];
  bool showCurrentOrder = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  Timer? _statusUpdateTimer;
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadData();
    _startStatusUpdateTimer();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer = Timer.periodic(AppConstants.statusUpdateInterval, (timer) {
      if (mounted && context.read<OrderService>().hasOrders) {
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
    _cacheService.clearCache(); // Nettoyer le cache pour libérer la mémoire
    super.dispose();
  }

  void _loadData() async {
    final loadedPizzas = await StorageService.loadPizzaList();
    await context.read<OrderService>().loadOrders();
    setState(() {
      availablePizzas = loadedPizzas;
    });
  }

  void addToCart(Pizza pizza) {
    final cartService = context.read<CartService>();
    cartService.addToCart(pizza);
    
    // Afficher la commande en cours avec animation quand on ajoute un produit
    if (!showCurrentOrder) {
      setState(() {
        showCurrentOrder = true;
      });
      _animationController.forward();
    }
  }

  // Méthode pour encaisser directement une commande
  void checkoutDirect() async {
    final cartService = context.read<CartService>();
    if (cartService.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) =>
          PaymentMethodDialog(currentSelection: AppConstants.defaultPaymentMethod),
    );

    if (result != null) {
      final String selectedMethod = result['method'];

      // Enregistrement de l'encaissement
      await StorageService.saveEncaissement(Encaissement(
        date: DateTime.now(),
        montant: cartService.totalPrice,
        modeReglement: selectedMethod,
        articles: cartService.items,
      ));

      // Nettoyage du panier
      cartService.clear();
      if (showCurrentOrder) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              showCurrentOrder = false;
            });
          }
        });
      }

      // Affichage d'un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(AppConstants.paymentSuccessMessage),
              ],
            ),
            duration: AppConstants.snackBarDuration,
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppConstants.successGreen,
          ),
        );
      }
    }
  }

  // Nouvelle méthode pour mettre une commande en attente
  void putOrderOnHold() async {
    final cartService = context.read<CartService>();
    if (cartService.isEmpty) return;

    final selectedTime = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const PickupTimeDialog(),
    );

    if (selectedTime != null) {
      final orderService = context.read<OrderService>();
      await orderService.createOrder(
        articles: cartService.items,
        amount: cartService.totalPrice,
        pickupTime: selectedTime,
      );

      cartService.clear();
      if (showCurrentOrder) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              showCurrentOrder = false;
            });
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(AppConstants.orderOnHoldMessage),
              ],
            ),
            duration: AppConstants.snackBarDuration,
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppConstants.warningOrange,
          ),
        );
      }
    }
  }

  // Méthode pour valider la récupération d'une commande
  void validatePickup(CommandeAttente commande) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) =>
          PaymentMethodDialog(currentSelection: AppConstants.defaultPaymentMethod),
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
      await context.read<OrderService>().removeOrder(commande.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(AppConstants.orderValidatedMessage),
              ],
            ),
            duration: AppConstants.snackBarDuration,
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppConstants.successGreen,
          ),
        );
      }
    }
  }

  // Méthode pour modifier une commande en attente
  void editOrderOnHold(CommandeAttente commande) async {
    final cartService = context.read<CartService>();
    // Remettre la commande dans le panier
    cartService.loadFromOrder(commande.articles);
    
    // Afficher la commande en cours avec animation
    if (!showCurrentOrder) {
      setState(() {
        showCurrentOrder = true;
      });
      _animationController.forward();
    }

    // Supprimer la commande de la file d'attente
    await context.read<OrderService>().removeOrder(commande.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.orderBackToCompositionMessage),
          duration: AppConstants.snackBarDuration,
        ),
      );
    }
  }

  // Méthode pour afficher l'aperçu d'une commande en attente
  void showOrderPreview(CommandeAttente commande) {
    String formattedCompositionTime = '${commande.heureComposition.hour.toString().padLeft(2, '0')}:${commande.heureComposition.minute.toString().padLeft(2, '0')}';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aperçu de la commande', style: TextStyle(fontSize: AppConstants.titleFontSize, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Heure de composition : $formattedCompositionTime', style: TextStyle(fontSize: AppConstants.subtitleFontSize, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Heure de récupération prévue : ${commande.heureRecuperationPrevue}', style: TextStyle(fontSize: AppConstants.subtitleFontSize, fontWeight: FontWeight.w600)),
                SizedBox(height: 16),
                Text('Articles commandés :', style: TextStyle(fontSize: AppConstants.subtitleFontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (commande.articles.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                        SizedBox(width: 8),
                        Text('Aucun article enregistré pour cette commande', 
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600])),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // Utiliser le cache pour le tri des articles
                        final sortedArticles = _cacheService.getSortedArticles(commande.articles);
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: sortedArticles.length,
                          itemBuilder: (context, index) {
                            var article = sortedArticles[index];
                        
                            // Déterminer la couleur selon le type
                            Color borderColor;
                            switch (article.type) {
                              case 'Tomate':
                                borderColor = Colors.red;
                                break;
                              case 'Crème':
                                borderColor = Colors.blue;
                                break;
                              case 'Softs':
                                borderColor = Colors.amber;
                                break;
                              case 'Vins':
                                borderColor = Colors.orange;
                                break;
                              case 'Spécialités':
                                borderColor = Colors.green;
                                break;
                              case 'Glaces':
                                borderColor = Colors.purple;
                                break;
                              case 'Desserts':
                                borderColor = Colors.pink;
                                break;
                              default:
                                borderColor = Colors.grey;
                            }
                            
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: borderColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(article.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                            Text(article.type, style: TextStyle(fontSize: 14, color: borderColor.withValues(alpha: 0.8))),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text('x${article.quantity}', 
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(formatPrice(article.price), 
                                          style: TextStyle(fontSize: 16),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      SizedBox(
                                        width: 70,
                                        child: Text(formatPrice(article.totalPrice), 
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16),
                Text('Montant total : ${formatPrice(commande.montant)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
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
      await context.read<OrderService>().removeOrder(commande.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.orderCancelledMessage),
            duration: AppConstants.snackBarDuration,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TurboPizza'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu',
                  style: TextStyle(fontSize: AppConstants.headerFontSize, color: Colors.white)),
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
            child: ProductGrid(
              products: availablePizzas,
              onProductTap: addToCart,
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
                    color: AppConstants.lightBlueAccent,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          color: AppConstants.lightBlue,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          'COMMANDES EN ATTENTE',
                                          style: TextStyle(
                                            fontSize: AppConstants.subtitleFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.touch_app,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              AppConstants.touchForDetailsMessage,
                                              style: TextStyle(
                                                fontSize: AppConstants.smallFontSize,
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Consumer<CartService>(
                                    builder: (context, cartService, child) {
                                      return IconButton(
                                        icon: const Icon(Icons.calculate),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) => CalculatorDialog(
                                              currentOrderTotal: cartService.totalPrice,
                                            ),
                                          );
                                        },
                                        tooltip: 'Calculatrice',
                                        iconSize: 24,
                                        color: AppConstants.primaryBlue,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Consumer<OrderService>(
                            builder: (context, orderService, child) {
                              if (!orderService.hasOrders) {
                                return const Center(
                                  child: Text(
                                    AppConstants.noOrdersMessage,
                                    style: TextStyle(
                                      fontSize: AppConstants.bodyFontSize,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              }

                              return LazyOrderList(
                                orders: orderService.orders,
                                orderService: orderService,
                                onTap: showOrderPreview,
                                onValidate: validatePickup,
                                onEdit: editOrderOnHold,
                                onCancel: cancelOrderOnHold,
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
                Consumer<CartService>(
                  builder: (context, cartService, child) {
                    return AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: showCurrentOrder ? _slideAnimation.value : 0.0,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: CurrentOrderWidget(
                                onPutOnHold: putOrderOnHold,
                                onCheckoutDirect: checkoutDirect,
                              ),
                            ),
                          ),
                        );
                      },
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
