// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/pizza.dart';
import '../models/payment.dart';
import '../models/pending_order.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';
import '../utils/snack_bar_utils.dart';
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
import 'payment_history_page.dart';
import 'sales_statistics_page.dart';
import 'settings_page.dart';

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
  // Délais de réduction (debounce) pour éviter des variations brusques de hauteur
  Timer? _currentOrderShrinkTimer;
  int _appliedItemCountForHeight = 0;

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
    _currentOrderShrinkTimer?.cancel();
    _cacheService.clearCache(); // Nettoyer le cache pour libérer la mémoire
    super.dispose();
  }

  void _loadData() async {
    final loadedPizzas = await StorageService.loadPizzaList();
  if (!mounted) return;
  await context.read<OrderService>().loadOrders();
  if (!mounted) return;
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

  if (!mounted) return;
  if (result != null) {
      final String selectedMethod = result['method'];

      // Enregistrement de l'encaissement
      await StorageService.savePayment(Payment(
        date: DateTime.now(),
        amount: cartService.totalPrice,
        paymentMethod: selectedMethod,
        items: cartService.items,
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
  if (!mounted) return;
        showAppSnackBar(
          context,
          AppConstants.paymentSuccessMessage,
          type: AppSnackBarType.success,
        );
      
    }
  }

  // Nouvelle méthode pour mettre une commande en attente
  void putOrderOnHold() async {
    final cartService = context.read<CartService>();
    if (cartService.isEmpty) return;

    // Utiliser l'horaire mémorisé s'il existe, sinon demander un nouvel horaire
    String? selectedTime = cartService.lastPickupTime ??
        await showDialog<String>(
          context: context,
          builder: (BuildContext context) => const PickupTimeDialog(),
        );

    if (!mounted) return;
    if (selectedTime != null) {
      final orderService = context.read<OrderService>();
      await orderService.createOrder(
        items: cartService.items,
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

  if (!mounted) return;
        showAppSnackBar(
          context,
          AppConstants.orderOnHoldMessage,
          type: AppSnackBarType.info,
        );
      
    }
  }

  // Méthode pour valider la récupération d'une commande
  void validatePickup(PendingOrder order) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) =>
          PaymentMethodDialog(currentSelection: AppConstants.defaultPaymentMethod),
    );

  if (!mounted) return;
  if (result != null) {
      final String selectedMethod = result['method'];

      // Créer un encaissement à partir de la commande
      final payment = Payment(
        date: DateTime.now(),
        amount: order.amount,
        paymentMethod: selectedMethod,
        items: order.items,
      );

  await StorageService.savePayment(payment);
  if (!mounted) return;
  await context.read<OrderService>().removeOrder(order.id);

  if (mounted) {
        showAppSnackBar(
          context,
          AppConstants.orderValidatedMessage,
          type: AppSnackBarType.success,
        );
      }
    }
  }

  // Méthode pour modifier une commande en attente
  void editOrderOnHold(PendingOrder order) async {
    final cartService = context.read<CartService>();
    // Remettre la commande dans le panier
    cartService.loadFromOrder(order.items);
    
    // Mémoriser l'horaire de récupération pour pouvoir le réutiliser
    cartService.setLastPickupTime(order.plannedPickupTime);
    
    // Afficher la commande en cours avec animation
    if (!showCurrentOrder) {
      setState(() {
        showCurrentOrder = true;
      });
      _animationController.forward();
    }

    // Supprimer la commande de la file d'attente
    await context.read<OrderService>().removeOrder(order.id);

    if (mounted) {
      showAppSnackBar(
        context,
        AppConstants.orderBackToCompositionMessage,
        type: AppSnackBarType.info,
      );
    }
  }

  // Nouvelle méthode pour modifier uniquement l'horaire d'une commande
  void changeOrderTime(PendingOrder order) async {
    final selectedTime = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const PickupTimeDialog(),
    );

    if (!mounted) return;
    if (selectedTime != null) {
      final orderService = context.read<OrderService>();
      
      // Créer une nouvelle commande avec le nouvel horaire
      final updatedOrder = order.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Nouvel ID
        plannedPickupTime: selectedTime,
      );
      
      // Supprimer l'ancienne commande et ajouter la nouvelle
      await orderService.removeOrder(order.id);
      await orderService.addOrder(updatedOrder);

      if (mounted) {
        showAppSnackBar(
          context,
          'Horaire modifié : $selectedTime',
          type: AppSnackBarType.info,
        );
      }
    }
  }

  // Méthode pour afficher l'aperçu d'une commande en attente
  void showOrderPreview(PendingOrder order) {
    String formattedCompositionTime = '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    
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
                Text('Heure de récupération prévue : ${order.plannedPickupTime}', style: TextStyle(fontSize: AppConstants.subtitleFontSize, fontWeight: FontWeight.w600)),
                SizedBox(height: 16),
                Text('Articles commandés :', style: TextStyle(fontSize: AppConstants.subtitleFontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (order.items.isEmpty)
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
                  final sortedItems = _cacheService.getSortedItems(order.items);
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: sortedItems.length,
                          itemBuilder: (context, index) {
                    var item = sortedItems[index];
                        
                            // Déterminer la couleur selon le type
                            Color borderColor;
                    switch (item.type) {
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
                                      SizedBox(
                                        width: 48,
                                        child: Text('${item.quantity} x',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                            Text(item.type, style: TextStyle(fontSize: 14, color: borderColor.withValues(alpha: 0.8))),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                          child: Text(formatPrice(item.price), 
                                          style: TextStyle(fontSize: 16),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      SizedBox(
                                        width: 70,
                          child: Text(formatPrice(item.totalPrice), 
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
                Text('Montant total : ${formatPrice(order.amount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
  void cancelOrderOnHold(PendingOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer l\'annulation'),
          content: Text(
            'Êtes-vous sûr de vouloir annuler cette commande ?\n\nHeure de récupération : ${order.plannedPickupTime}\nMontant : ${formatPrice(order.amount)}',
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

    if (!mounted) return;
    if (confirmed == true) {
  await context.read<OrderService>().removeOrder(order.id);

      if (mounted) {
        showAppSnackBar(
          context,
          AppConstants.orderCancelledMessage,
          type: AppSnackBarType.warning,
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
              title: const Text('Historique des encaissements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PaymentHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistiques de vente'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SalesStatisticsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Sauvegarde & export'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsPage()),
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
                                onChangeTime: changeOrderTime,
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
                    // Calcul dynamique de la hauteur de la commande en cours
                    final screenHeight = MediaQuery.of(context).size.height;
                    const double headerHeight = 56; // bandeau "COMMANDE EN COURS"
                    const double footerHeight = 140; // total + boutons
                    const double perItemHeight = 64; // hauteur approximative par ligne du panier
                    final int itemCount = cartService.items.length;

                    // Gestion du debounce: 
                    // - si le nombre d'items augmente, on applique immédiatement la nouvelle hauteur
                    // - s'il diminue, on attend un court délai avant de réduire la hauteur
                    if (itemCount > _appliedItemCountForHeight) {
                      _currentOrderShrinkTimer?.cancel();
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _appliedItemCountForHeight = itemCount;
                          });
                        });
                      }
                    } else if (itemCount < _appliedItemCountForHeight) {
                      // Redémarrer le timer de réduction
                      _currentOrderShrinkTimer?.cancel();
                      _currentOrderShrinkTimer = Timer(AppConstants.currentOrderShrinkDelay, () {
                        if (!mounted) return;
                        final int latestCount = context.read<CartService>().items.length;
                        setState(() {
                          _appliedItemCountForHeight = latestCount;
                        });
                        // Si après délai le panier est vide, refermer la fenêtre en douceur
                        if (latestCount == 0 && showCurrentOrder) {
                          if (_animationController.status == AnimationStatus.dismissed) {
                            setState(() => showCurrentOrder = false);
                          } else if (_animationController.status != AnimationStatus.reverse) {
                            _animationController.reverse().then((_) {
                              if (mounted) setState(() => showCurrentOrder = false);
                            });
                          }
                        }
                      });
                    }

                    final double desiredHeight = headerHeight + footerHeight + (_appliedItemCountForHeight * perItemHeight);
                    final double minHeight = screenHeight * 0.25; // min 25% écran
                    final double maxHeight = screenHeight * 0.70; // max 70% écran pour laisser de la place à la file d'attente
                    final double currentOrderHeight = desiredHeight.clamp(minHeight, maxHeight).toDouble();

                    return AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: showCurrentOrder ? _slideAnimation.value : 0.0,
                            child: AnimatedContainer(
                              duration: AppConstants.animationDuration,
                              curve: Curves.easeInOut,
                              height: currentOrderHeight,
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

  Future<void> openPizzaManagementPage() async {
    final allPizzas = await StorageService.loadPizzaList(includeInactive: true);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PizzaManagementPage(
          availablePizzas: allPizzas,
          onUpdate: () async {
            final refreshed = await StorageService.loadPizzaList();
            if (!mounted) return;
            setState(() {
              availablePizzas = refreshed;
            });
          },
        ),
      ),
    );

    final refreshed = await StorageService.loadPizzaList();
    if (!mounted) return;
    setState(() {
      availablePizzas = refreshed;
    });
  }
}
