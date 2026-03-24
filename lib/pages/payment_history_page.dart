// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/payment.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';
import '../utils/snack_bar_utils.dart';
import '../constants/app_locales.dart';
import '../constants/app_payments.dart';
import '../constants/app_strings.dart';
import '../widgets/payment_method_dialog.dart';
import '../theme/app_theme.dart';

enum ViewMode { daily, weekly, monthly }

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  DateTime selectedDate = DateTime.now();
  ViewMode currentViewMode = ViewMode.daily;
  List<Payment> payments = [];
  List<Payment> filteredPayments = [];

  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 50;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  DateTime? _currentStart;
  DateTime? _currentEndExclusive;

  double totalChecks = 0.0;
  double totalCash = 0.0;
  double totalTransfers = 0.0;
  double totalSum = 0.0;

  double totalSelectedChecks = 0.0;
  double totalSelectedCash = 0.0;
  double totalSelectedTransfers = 0.0;
  double totalSelectedSum = 0.0;

  double previousYearTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialiser les données de localisation pour le français
    initializeDateFormatting(AppLocales.french, null).then((_) {
      _reloadForCurrentPeriod();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reloadForCurrentPeriod() async {
    final range = _getPeriodRange(selectedDate, currentViewMode);
    _currentStart = range.$1;
    _currentEndExclusive = range.$2;

    setState(() {
      _isLoading = false;
      _hasMore = true;
      _currentOffset = 0;
      payments = [];
      filteredPayments = [];
    });

    await _loadTotalsForCurrentPeriod();
    await _loadNextPage();
  }

  Future<void> _loadTotalsForCurrentPeriod() async {
    final start =
        _currentStart ?? _getPeriodRange(selectedDate, currentViewMode).$1;
    final endExclusive =
        _currentEndExclusive ??
        _getPeriodRange(selectedDate, currentViewMode).$2;

    final totals = await StorageService.loadPaymentTotalsByMethodBetween(
      start: start,
      endExclusive: endExclusive,
    );

    final cashTotal = totals[AppPayments.methods[0]] ?? 0.0;
    final checkTotal = totals[AppPayments.methods[1]] ?? 0.0;
    final transferTotal = totals[AppPayments.methods[2]] ?? 0.0;

    final previousRange = _getPeriodRange(
      DateTime(selectedDate.year - 1, selectedDate.month, selectedDate.day),
      currentViewMode,
    );
    final previousTotal = await StorageService.loadPaymentTotalAmountBetween(
      start: previousRange.$1,
      endExclusive: previousRange.$2,
    );

    if (!mounted) return;
    setState(() {
      totalCash = cashTotal;
      totalChecks = checkTotal;
      totalTransfers = transferTotal;
      totalSum = cashTotal + checkTotal + transferTotal;
      previousYearTotal = previousTotal;
    });
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    final start =
        _currentStart ?? _getPeriodRange(selectedDate, currentViewMode).$1;
    final endExclusive =
        _currentEndExclusive ??
        _getPeriodRange(selectedDate, currentViewMode).$2;

    setState(() {
      _isLoading = true;
    });

    final page = await StorageService.loadPaymentsPage(
      start: start,
      endExclusive: endExclusive,
      limit: _pageSize,
      offset: _currentOffset,
    );

    if (!mounted) return;
    setState(() {
      _currentOffset += page.length;
      payments.addAll(page);
      filteredPayments = List.from(payments);
      _hasMore = page.length == _pageSize;
      _isLoading = false;
    });
    calculateSelectedTotals();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  (DateTime, DateTime) _getPeriodRange(DateTime date, ViewMode viewMode) {
    switch (viewMode) {
      case ViewMode.daily:
        final start = DateTime(date.year, date.month, date.day);
        return (start, start.add(const Duration(days: 1)));
      case ViewMode.weekly:
        final start = _getWeekStart(date);
        return (start, start.add(const Duration(days: 7)));
      case ViewMode.monthly:
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 1);
        return (start, end);
    }
  }

  // Obtenir le début de la semaine (dimanche soir 20h)
  DateTime _getWeekStart(DateTime date) {
    // Semaine du dimanche 00:00 au dimanche suivant 00:00 (service terminé samedi soir)
    final daysSinceSunday = date.weekday % 7; // Sunday -> 0, Monday -> 1, ...
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.subtract(Duration(days: daysSinceSunday));
  }

  void _deletePayment(Payment payment) async {
    // Afficher une boîte de dialogue de confirmation
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final textStyles = context.appTextStyles;
        final layout = context.appLayout;
        final colors = context.appColors;
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Confirmer la suppression',
            style: textStyles.large.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir supprimer cette commande ?',
                style: textStyles.subtitle,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(layout.borderRadius),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date : ${DateFormat('dd/MM/yyyy à HH:mm').format(payment.date)}',
                      style: textStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Montant : ${formatPrice(payment.amount)}',
                      style: textStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mode : ${payment.paymentMethod}',
                      style: textStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette action est irréversible.',
                style: textStyles.body.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.errorRed,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler', style: textStyles.subtitle),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Supprimer', style: textStyles.subtitle),
            ),
          ],
        );
      },
    );

    // Si l'utilisateur a confirmé la suppression
    if (confirmDelete == true) {
      if (payment.id == null) {
        if (!mounted) return;
        showAppSnackBar(
          context,
          'Suppression impossible: identifiant manquant.',
          type: AppSnackBarType.error,
        );
        return;
      }

      await StorageService.deletePayment(payment.id!);

      // Supprimer le paiement de la liste
      setState(() {
        payments.remove(payment);
        filteredPayments.remove(payment);
        calculateSelectedTotals();
      });

      await _loadTotalsForCurrentPeriod();

      // Afficher un message de confirmation
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Commande supprimée avec succès',
        type: AppSnackBarType.success,
      );
    }
  }

  Future<void> _changePaymentMethod(Payment payment) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) =>
          PaymentMethodDialog(currentSelection: payment.paymentMethod),
    );

    if (!mounted || result == null) return;
    final String newMethod = result['method'];
    if (newMethod == payment.paymentMethod) return;

    if (payment.id == null) {
      showAppSnackBar(
        context,
        'Modification impossible: identifiant manquant.',
        type: AppSnackBarType.error,
      );
      return;
    }

    await StorageService.updatePaymentMethod(
      payment: payment,
      newMethod: newMethod,
    );

    if (!mounted) return;
    setState(() {
      payment.paymentMethod = newMethod;
    });
    calculateSelectedTotals();
    await _loadTotalsForCurrentPeriod();

    if (!mounted) return;
    showAppSnackBar(
      context,
      'Mode de règlement mis à jour',
      type: AppSnackBarType.success,
    );
  }

  void calculateSelectedTotals() {
    totalSelectedChecks = 0.0;
    totalSelectedCash = 0.0;
    totalSelectedTransfers = 0.0;
    totalSelectedSum = 0.0;

    for (var payment in filteredPayments) {
      if (payment.isSelected) {
        if (payment.paymentMethod == "Chèque") {
          totalSelectedChecks += payment.amount;
        } else if (payment.paymentMethod == "Espèces") {
          totalSelectedCash += payment.amount;
        } else if (payment.paymentMethod == "Virement") {
          totalSelectedTransfers += payment.amount;
        }
      }
    }
    totalSelectedSum =
        totalSelectedCash + totalSelectedChecks + totalSelectedTransfers;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2099),
    );
    if (!mounted) return;
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _reloadForCurrentPeriod();
    }
  }

  void _togglePaymentSelection(Payment payment) {
    setState(() {
      payment.isSelected = !payment.isSelected;
      calculateSelectedTotals(); // Recalculer les totaux après chaque changement
    });
  }

  Widget _buildDateShortcut(String label, DateTime date) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;
    bool isSelected =
        selectedDate.year == date.year &&
        selectedDate.month == date.month &&
        selectedDate.day == date.day;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? colors.primaryBlue : colorScheme.surface,
        foregroundColor: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurface,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size(104, 42),
      ),
      onPressed: () {
        setState(() {
          selectedDate = date;
        });
        _reloadForCurrentPeriod();
      },
      child: Text(label, style: textStyles.subtitle),
    );
  }

  void _goToPreviousPeriod() {
    setState(() {
      switch (currentViewMode) {
        case ViewMode.daily:
          selectedDate = selectedDate.subtract(const Duration(days: 1));
          break;
        case ViewMode.weekly:
          selectedDate = selectedDate.subtract(const Duration(days: 7));
          break;
        case ViewMode.monthly:
          selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
          break;
      }
    });
    _reloadForCurrentPeriod();
  }

  void _goToNextPeriod() {
    setState(() {
      switch (currentViewMode) {
        case ViewMode.daily:
          selectedDate = selectedDate.add(const Duration(days: 1));
          break;
        case ViewMode.weekly:
          selectedDate = selectedDate.add(const Duration(days: 7));
          break;
        case ViewMode.monthly:
          selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
          break;
      }
    });
    _reloadForCurrentPeriod();
  }

  String _getPeriodTitle() {
    switch (currentViewMode) {
      case ViewMode.daily:
        return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(selectedDate);
      case ViewMode.weekly:
        final weekStart = _getWeekStart(selectedDate);
        final weekEnd = weekStart.add(
          const Duration(days: 6, hours: 23, minutes: 59),
        );
        return 'Semaine du ${DateFormat('dd/MM', 'fr_FR').format(weekStart)} au ${DateFormat('dd/MM/yyyy', 'fr_FR').format(weekEnd)}';
      case ViewMode.monthly:
        return DateFormat('MMMM yyyy', 'fr_FR').format(selectedDate);
    }
  }

  String _getComparisonText() {
    switch (currentViewMode) {
      case ViewMode.daily:
        return "CA N-1 (${selectedDate.year - 1}): ${formatPrice(previousYearTotal)}";
      case ViewMode.weekly:
        return "CA semaine N-1 (${selectedDate.year - 1}): ${formatPrice(previousYearTotal)}";
      case ViewMode.monthly:
        return "CA ${DateFormat('MMMM', 'fr_FR').format(DateTime(selectedDate.year - 1, selectedDate.month))}: ${formatPrice(previousYearTotal)}";
    }
  }

  void _showPaymentDetails(Payment payment) {
    String formattedDate = DateFormat(
      'dd/MM/yyyy à HH:mm',
    ).format(payment.date);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textStyles = context.appTextStyles;
        final colors = context.appColors;
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Détail de la commande',
            style: textStyles.title.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500, // Largeur fixe plus petite
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date : $formattedDate',
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
                if (payment.items.isEmpty)
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
                        // Trier les articles par catégorie
                        var sortedItems = List.from(payment.items);
                        sortedItems.sort((a, b) {
                          // Ordre de priorité des catégories
                          const categoryOrder = [
                            'Tomate',
                            'Crème',
                            'Spécialités',
                            'Softs',
                            'Vins',
                            'Desserts',
                            'Glaces',
                          ];

                          int aIndex = categoryOrder.indexOf(a.type);
                          int bIndex = categoryOrder.indexOf(b.type);

                          // Si une catégorie n'est pas trouvée, la mettre à la fin
                          if (aIndex == -1) aIndex = categoryOrder.length;
                          if (bIndex == -1) bIndex = categoryOrder.length;

                          // Si même catégorie, trier par nom
                          if (aIndex == bIndex) {
                            return a.name.compareTo(b.name);
                          }

                          return aIndex.compareTo(bIndex);
                        });

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
                                        width: 60,
                                        child: Text(
                                          formatPrice(item.price),
                                          style: textStyles.body,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      SizedBox(
                                        width: 70,
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
                  'Mode de règlement : ${payment.paymentMethod}',
                  style: textStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Montant total : ${formatPrice(payment.amount)}',
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.paymentHistoryTitle)),
      body: Column(
        children: [
          Container(
            color: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Première ligne : Sélecteur de mode d'affichage
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SegmentedButton<ViewMode>(
                      segments: const [
                        ButtonSegment<ViewMode>(
                          value: ViewMode.daily,
                          label: Text('Journalier'),
                          icon: Icon(Icons.today),
                        ),
                        ButtonSegment<ViewMode>(
                          value: ViewMode.weekly,
                          label: Text('Hebdomadaire'),
                          icon: Icon(Icons.view_week),
                        ),
                        ButtonSegment<ViewMode>(
                          value: ViewMode.monthly,
                          label: Text('Mensuel'),
                          icon: Icon(Icons.calendar_month),
                        ),
                      ],
                      selected: {currentViewMode},
                      onSelectionChanged: (Set<ViewMode> newSelection) {
                        setState(() {
                          currentViewMode = newSelection.first;
                        });
                        _reloadForCurrentPeriod();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Deuxième ligne : Navigation et sélection de date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentViewMode == ViewMode.daily
                          ? "Sélectionner la date:"
                          : currentViewMode == ViewMode.weekly
                          ? "Sélectionner la semaine:"
                          : "Sélectionner le mois:",
                      style: textStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Boutons de raccourcis centrés (seulement pour le mode journalier)
                    if (currentViewMode == ViewMode.daily)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDateShortcut('Aujourd\'hui', DateTime.now()),
                          const SizedBox(width: 72),
                          _buildDateShortcut(
                            'Hier',
                            DateTime.now().subtract(const Duration(days: 1)),
                          ),
                          const SizedBox(width: 72),
                          _buildDateShortcut(
                            'Avant-hier',
                            DateTime.now().subtract(const Duration(days: 2)),
                          ),
                        ],
                      )
                    else
                      const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton période précédente
                        IconButton(
                          onPressed: _goToPreviousPeriod,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: currentViewMode == ViewMode.daily
                              ? 'Jour précédent'
                              : currentViewMode == ViewMode.weekly
                              ? 'Semaine précédente'
                              : 'Mois précédent',
                        ),
                        // Affichage de la période actuelle
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.surface,
                            foregroundColor: colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            fixedSize: const Size(280, 42),
                          ),
                          onPressed: currentViewMode == ViewMode.daily
                              ? () => _selectDate(context)
                              : null,
                          child: Text(
                            _getPeriodTitle(),
                            style: textStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Bouton période suivante
                        IconButton(
                          onPressed: _goToNextPeriod,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: currentViewMode == ViewMode.daily
                              ? 'Jour suivant'
                              : currentViewMode == ViewMode.weekly
                              ? 'Semaine suivante'
                              : 'Mois suivant',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredPayments.isNotEmpty
                  ? filteredPayments.length + (_hasMore ? 1 : 0)
                  : 1,
              itemBuilder: (context, index) {
                if (filteredPayments.isEmpty) {
                  if (_isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Aucun encaissement pour cette periode.',
                        style: textStyles.body,
                      ),
                    ),
                  );
                }

                if (index >= filteredPayments.length) {
                  return _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox(height: 16);
                }

                var payment = filteredPayments[index];
                // ignore: unused_local_variable
                String formattedDate = DateFormat(
                  'dd/MM/yyyy à H:mm',
                ).format(payment.date);

                // Utiliser l'index pour alterner la couleur de fond
                final bgColor = index % 2 == 0
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surface; // Couleurs alternées
                final muted = colorScheme.onSurface.withValues(alpha: 0.5);

                return ListTile(
                  tileColor: bgColor, // Appliquer la couleur de fond
                  leading: Checkbox(
                    value: payment.isSelected,
                    onChanged: (bool? value) {
                      _togglePaymentSelection(payment);
                    },
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Montant: ${formatPrice(payment.amount)}",
                          style: TextStyle(
                            color: payment.isSelected ? muted : null,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(payment.date),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: payment.isSelected
                              ? muted
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mode: ${payment.paymentMethod}",
                        style: TextStyle(
                          color: payment.isSelected ? muted : null,
                        ),
                      ),
                      if (payment.items.isNotEmpty)
                        Text(
                          "Articles: ${payment.items.map((pizza) => '${pizza.quantity} x ${pizza.name}').join(', ')}",
                          style: TextStyle(
                            fontSize: 12,
                            color: payment.isSelected
                                ? muted
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: colors.warningOrange),
                        onPressed: () => _changePaymentMethod(payment),
                        tooltip: 'Modifier le mode de règlement',
                      ),
                      // Icône pour voir le détail de la commande
                      IconButton(
                        icon: Icon(
                          Icons.visibility,
                          color: colorScheme.primary,
                        ),
                        onPressed: () => _showPaymentDetails(payment),
                        tooltip: 'Voir le détail de la commande',
                      ),
                      // Icône pour supprimer l'encaissement
                      IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () => _deletePayment(payment),
                        tooltip: 'Supprimer cet encaissement',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      "Chèques: ${formatPrice(totalSelectedChecks)} / ${formatPrice(totalChecks)}",
                      style: textStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Espèces: ${formatPrice(totalSelectedCash)} / ${formatPrice(totalCash)}",
                      style: textStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Virements: ${formatPrice(totalSelectedTransfers)} / ${formatPrice(totalTransfers)}",
                      style: textStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.point_of_sale,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "À pointer: ${formatPrice(totalSelectedSum)} / ${formatPrice(totalSum)}",
                        style: textStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        color: colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getComparisonText(),
                        style: textStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      if (totalSum > 0 && previousYearTotal > 0)
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Text(
                              "(${totalSum > previousYearTotal ? '+' : ''}${((totalSum - previousYearTotal) / previousYearTotal * 100).toStringAsFixed(1)}%)",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: totalSum >= previousYearTotal
                                    ? colors.successGreenDark
                                    : colorScheme.error,
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
        ],
      ),
    );
  }
}
