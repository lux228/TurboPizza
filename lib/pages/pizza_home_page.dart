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
import '../services/category_filter_service.dart';
import '../constants/app_categories.dart';
import '../constants/app_durations.dart';
import '../constants/app_payments.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'pizza_management_page.dart';
import 'payment_history_page.dart';
import 'sales_statistics_page.dart';
import 'settings_page.dart';

class PizzaHomePage extends StatefulWidget {
  const PizzaHomePage({super.key});

  @override
  _PizzaHomePageState createState() => _PizzaHomePageState();
}

class _PizzaHomePageState extends State<PizzaHomePage>
    with TickerProviderStateMixin {
  List<Pizza> availablePizzas = [];
  bool showCurrentOrder = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  Timer? _statusUpdateTimer;
  final CacheService _cacheService = CacheService();
  // Délais de réduction (debounce) pour éviter des variations brusques de hauteur
  Timer? _currentOrderShrinkTimer;
  int _appliedItemCountForHeight = 0;
  String? _selectedTopCategoryId;
  bool _isEditingOrderFlow = false;
  String? _editedOrderInitialPickupTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadData();
    _startStatusUpdateTimer();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: AppDurations.animationDuration,
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer = Timer.periodic(AppDurations.statusUpdateInterval, (
      timer,
    ) {
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

  List<Pizza> _getFilteredPizzas(
    Set<String> enabledTopCategories,
    bool showTopCategoryButtons,
  ) {
    if (!showTopCategoryButtons) return availablePizzas;
    if (_selectedTopCategoryId == null) return availablePizzas;
    if (!enabledTopCategories.contains(_selectedTopCategoryId)) {
      return availablePizzas;
    }

    final categoryTypes =
        AppCategories.topCategoryTypeMap[_selectedTopCategoryId] ??
        const <String>[];
    return availablePizzas
        .where((pizza) => categoryTypes.contains(pizza.type))
        .toList();
  }

  Widget _buildTopCategoryButtons(
    AppTextStyles textStyles,
    ColorScheme colorScheme,
    bool showTopCategoryButtons,
  ) {
    if (!showTopCategoryButtons) {
      _selectedTopCategoryId = null;
      return const SizedBox.shrink();
    }

    final visibleCategoryIds = AppCategories.topCategoryIds;

    if (_selectedTopCategoryId != null &&
        !visibleCategoryIds.contains(_selectedTopCategoryId)) {
      _selectedTopCategoryId = null;
    }

    if (visibleCategoryIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 12,
        children: [
          for (final categoryId in visibleCategoryIds)
            SizedBox(
              width: 180,
              height: 62,
              child: ChoiceChip(
                showCheckmark: false,
                label: Center(
                  child: Text(
                    AppCategories.topCategoryLabels[categoryId] ?? categoryId,
                    style: textStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                labelPadding: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.standard,
                selectedColor: colorScheme.primaryContainer,
                backgroundColor: colorScheme.surface,
                side: BorderSide(
                  color: _selectedTopCategoryId == categoryId
                      ? colorScheme.primary
                      : colorScheme.outline,
                  width: 2,
                ),
                selected: _selectedTopCategoryId == categoryId,
                onSelected: (selected) {
                  setState(() {
                    _selectedTopCategoryId = selected ? categoryId : null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // Méthode pour encaisser directement une commande
  void checkoutDirect() async {
    final cartService = context.read<CartService>();
    if (cartService.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => PaymentMethodDialog(
        currentSelection: AppPayments.defaultPaymentMethod,
      ),
    );

    if (!mounted) return;
    if (result != null) {
      final String selectedMethod = result['method'];

      // Enregistrement de l'encaissement
      await StorageService.savePayment(
        Payment(
          date: DateTime.now(),
          amount: cartService.totalPrice,
          paymentMethod: selectedMethod,
          items: cartService.items,
        ),
      );

      // Nettoyage du panier
      cartService.clear();
      _isEditingOrderFlow = false;
      _editedOrderInitialPickupTime = null;
      cartService.clearLastPickupTime();
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
        AppStrings.paymentSuccessMessage,
        type: AppSnackBarType.success,
      );
    }
  }

  // Nouvelle méthode pour mettre une commande en attente
  void putOrderOnHold() async {
    final cartService = context.read<CartService>();
    if (cartService.isEmpty) return;

    // Pré-remplir l'horaire uniquement si on vient d'une action "Modifier".
    final initialPickupTime = _isEditingOrderFlow
        ? _editedOrderInitialPickupTime
        : null;

    String? selectedTime = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          PickupTimeDialog(initialTime: initialPickupTime),
    );

    if (!mounted) return;
    if (selectedTime != null) {
      final orderService = context.read<OrderService>();
      await orderService.createOrder(
        items: cartService.items,
        amount: cartService.totalPrice,
        pickupTime: selectedTime,
      );

      _isEditingOrderFlow = false;
      _editedOrderInitialPickupTime = null;
      cartService.clearLastPickupTime();

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
        AppStrings.orderOnHoldMessage,
        type: AppSnackBarType.info,
      );
    }
  }

  // Méthode pour valider la récupération d'une commande
  void validatePickup(PendingOrder order) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => PaymentMethodDialog(
        currentSelection: AppPayments.defaultPaymentMethod,
      ),
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
          AppStrings.orderValidatedMessage,
          type: AppSnackBarType.success,
        );
      }
    }
  }

  // Méthode pour modifier une commande en attente
  void editOrderOnHold(PendingOrder order) async {
    final cartService = context.read<CartService>();

    // Évite d'écraser une modification déjà en cours dans le panier.
    if (!cartService.isEmpty && showCurrentOrder) {
      showAppSnackBar(
        context,
        'Terminez d\'abord la modification en cours (mettre en attente ou encaisser).',
        type: AppSnackBarType.warning,
      );
      return;
    }

    // Remettre la commande dans le panier
    cartService.loadFromOrder(order.items);

    // Mémoriser qu'on est en mode édition pour pré-remplir au prochain "Mise en attente".
    _isEditingOrderFlow = true;
    _editedOrderInitialPickupTime = order.plannedPickupTime;
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
        AppStrings.orderBackToCompositionMessage,
        type: AppSnackBarType.info,
      );
    }
  }

  // Nouvelle méthode pour modifier uniquement l'horaire d'une commande
  void changeOrderTime(PendingOrder order) async {
    final selectedTime = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          PickupTimeDialog(initialTime: order.plannedPickupTime),
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
    String formattedCompositionTime =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textStyles = context.appTextStyles;
        final colors = context.appColors;
        final colorScheme = Theme.of(context).colorScheme;
        final size = MediaQuery.of(context).size;
        final dialogWidth = size.width < 600 ? size.width * 0.9 : 520.0;
        final dialogHeight = size.height < 700
            ? size.height * 0.85
            : size.height * 0.7;
        return AlertDialog(
          title: Text(
            'Aperçu de la commande',
            style: textStyles.title.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heure de composition : $formattedCompositionTime',
                  style: textStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Heure de récupération prévue : ${order.plannedPickupTime}',
                  style: textStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Articles commandés :',
                  style: textStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (order.items.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Aucun article enregistré pour cette commande',
                          style: textStyles.caption.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // Utiliser le cache pour le tri des articles
                        final sortedItems = _cacheService.getSortedItems(
                          order.items,
                        );

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: sortedItems.length,
                          itemBuilder: (context, index) {
                            var item = sortedItems[index];

                            // Déterminer la couleur selon le type
                            final borderColor = colors.productTypeColor(
                              item.type,
                            );

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
                                        child: Text(
                                          '${item.quantity} x',
                                          style: textStyles.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: textStyles.body.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              item.type,
                                              style: textStyles.caption
                                                  .copyWith(
                                                    color: borderColor
                                                        .withValues(alpha: 0.8),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          formatPrice(item.price),
                                          style: textStyles.body,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      SizedBox(
                                        width: 95,
                                        child: Text(
                                          formatPrice(item.totalPrice),
                                          style: textStyles.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.successGreenDark,
                                          ),
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
                Text(
                  'Montant total : ${formatPrice(order.amount)}',
                  style: textStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer', style: textStyles.body),
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
        final textStyles = context.appTextStyles;
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Confirmer l\'annulation'),
          content: Text(
            'Êtes-vous sûr de vouloir annuler cette commande ?\n\nHeure de récupération : ${order.plannedPickupTime}\nMontant : ${formatPrice(order.amount)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Non', style: textStyles.body),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Oui, annuler', style: textStyles.body),
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
          AppStrings.orderCancelledMessage,
          type: AppSnackBarType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('TurboPizza')),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: colors.primaryBlue),
              child: Text(
                'Menu',
                style: textStyles.header.copyWith(color: colorScheme.onPrimary),
              ),
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
                    builder: (context) => const PaymentHistoryPage(),
                  ),
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
                    builder: (context) => const SalesStatisticsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const minWidth = 900.0;
          const minHeight = 600.0;
          final isWide = constraints.maxWidth >= 1100;

          if (constraints.maxWidth < minWidth ||
              constraints.maxHeight < minHeight) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Fenetre trop petite. Agrandissez la fenetre pour un affichage correct.',
                  textAlign: TextAlign.center,
                  style: textStyles.subtitle.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }

          final leftPanel = Expanded(
            flex: 2,
            child: Consumer<CategoryFilterService>(
              builder: (context, categoryFilterService, child) {
                final filteredPizzas = _getFilteredPizzas(
                  categoryFilterService.enabledTopCategories,
                  categoryFilterService.showTopCategoryButtons,
                );
                return Column(
                  children: [
                    _buildTopCategoryButtons(
                      textStyles,
                      colorScheme,
                      categoryFilterService.showTopCategoryButtons,
                    ),
                    Expanded(
                      child: ProductGrid(
                        products: filteredPizzas,
                        onProductTap: addToCart,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
          final rightPanel = Expanded(
            flex: 1,
            child: _buildQueuePanel(colors, textStyles, colorScheme),
          );

          if (isWide) {
            return Row(
              children: [
                leftPanel,
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outline,
                ),
                rightPanel,
              ],
            );
          }

          return Column(
            children: [
              leftPanel,
              Divider(height: 1, thickness: 1, color: colorScheme.outline),
              rightPanel,
            ],
          );
        },
      ),
    );
  }

  Widget _buildQueuePanel(
    AppThemeColors colors,
    AppTextStyles textStyles,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Partie haute : File d'attente des commandes
        Expanded(
          flex: 1,
          child: Container(
            color: colors.lightBlueAccent,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  color: colors.lightBlue,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'COMMANDES EN ATTENTE',
                                  style: textStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
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
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppStrings.touchForDetailsMessage,
                                      style: textStyles.small.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
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
                                    builder: (BuildContext context) =>
                                        CalculatorDialog(
                                          currentOrderTotal:
                                              cartService.totalPrice,
                                        ),
                                  );
                                },
                                tooltip: 'Calculatrice',
                                iconSize: 24,
                                color: colors.primaryBlue,
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
                        return Center(
                          child: Text(
                            AppStrings.noOrdersMessage,
                            style: textStyles.body.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
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
            const double perItemHeight =
                64; // hauteur approximative par ligne du panier
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
              _currentOrderShrinkTimer = Timer(
                AppDurations.currentOrderShrinkDelay,
                () {
                  if (!mounted) return;
                  final int latestCount = context
                      .read<CartService>()
                      .items
                      .length;
                  setState(() {
                    _appliedItemCountForHeight = latestCount;
                  });
                  // Si après délai le panier est vide, refermer la fenêtre en douceur
                  if (latestCount == 0 && showCurrentOrder) {
                    if (_animationController.status ==
                        AnimationStatus.dismissed) {
                      setState(() => showCurrentOrder = false);
                    } else if (_animationController.status !=
                        AnimationStatus.reverse) {
                      _animationController.reverse().then((_) {
                        if (mounted) setState(() => showCurrentOrder = false);
                      });
                    }
                  }
                },
              );
            }

            final double desiredHeight =
                headerHeight +
                footerHeight +
                (_appliedItemCountForHeight * perItemHeight);
            final double minHeight = screenHeight * 0.25; // min 25% écran
            final double maxHeight = screenHeight * 0.70; // max 70% écran
            final double currentOrderHeight = desiredHeight
                .clamp(minHeight, maxHeight)
                .toDouble();

            return AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: showCurrentOrder
                        ? _slideAnimation.value
                        : 0.0,
                    child: AnimatedContainer(
                      duration: AppDurations.animationDuration,
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
