// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/payment.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';
import '../constants/app_constants.dart';

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

  double totalChecks = 0.0;
  double totalCash = 0.0;
  double totalSum = 0.0;

  double totalSelectedChecks = 0.0;
  double totalSelectedCash = 0.0;
  double totalSelectedSum = 0.0;

  double previousYearTotal = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialiser les données de localisation pour le français
    initializeDateFormatting(AppConstants.frenchLocale, null).then((_) {
      StorageService.loadPayments().then((loadedPayments) {
        setState(() {
          payments = loadedPayments;
          filterPayments();
        });
      });
    });
  }

  void filterPayments() {
    setState(() {
      switch (currentViewMode) {
        case ViewMode.daily:
          filteredPayments = payments
              .where((payment) =>
                  payment.date.year == selectedDate.year &&
                  payment.date.month == selectedDate.month &&
                  payment.date.day == selectedDate.day)
              .toList();
          break;
        case ViewMode.weekly:
          final weekStart = _getWeekStart(selectedDate);
            final weekEnd = weekStart.add(const Duration(days: 7));
            filteredPayments = payments
              .where((payment) =>
                !payment.date.isBefore(weekStart) &&
                payment.date.isBefore(weekEnd))
              .toList();
          break;
        case ViewMode.monthly:
          filteredPayments = payments
              .where((payment) =>
                  payment.date.year == selectedDate.year &&
                  payment.date.month == selectedDate.month)
              .toList();
          break;
      }
    });

  // Réinitialiser les totaux
  totalChecks = 0.0;
  totalCash = 0.0;

    // Calculer les totaux
    for (var payment in filteredPayments) {
      if (payment.paymentMethod == AppConstants.paymentMethods[1]) {
        // "Chèque"
        totalChecks += payment.amount;
      } else if (payment.paymentMethod == AppConstants.paymentMethods[0]) {
        // "Espèces"
        totalCash += payment.amount;
      }
    }
    totalSum = totalCash + totalChecks;

  // Calculer le total de l'année précédente pour la même période
  calculatePreviousYearTotal();
  }

  // Obtenir le début de la semaine (dimanche soir 20h)
  DateTime _getWeekStart(DateTime date) {
    // Semaine du dimanche 00:00 au dimanche suivant 00:00 (service terminé samedi soir)
    final daysSinceSunday = date.weekday % 7; // Sunday -> 0, Monday -> 1, ...
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.subtract(Duration(days: daysSinceSunday));
  }

  void calculatePreviousYearTotal() {
    previousYearTotal = 0.0;

    switch (currentViewMode) {
      case ViewMode.daily:
        DateTime anneePrecedente = DateTime(
            selectedDate.year - 1, selectedDate.month, selectedDate.day);
        for (var payment in payments) {
          if (payment.date.year == anneePrecedente.year &&
              payment.date.month == anneePrecedente.month &&
              payment.date.day == anneePrecedente.day) {
            previousYearTotal += payment.amount;
          }
        }
        break;
      case ViewMode.weekly:
        final weekStartPreviousYear = _getWeekStart(DateTime(
            selectedDate.year - 1, selectedDate.month, selectedDate.day));
        final weekEndPreviousYear =
            weekStartPreviousYear.add(const Duration(days: 7));
        for (var payment in payments) {
          if (!payment.date.isBefore(weekStartPreviousYear) &&
              payment.date.isBefore(weekEndPreviousYear)) {
            previousYearTotal += payment.amount;
          }
        }
        break;
      case ViewMode.monthly:
        for (var payment in payments) {
          if (payment.date.year == selectedDate.year - 1 &&
              payment.date.month == selectedDate.month) {
            previousYearTotal += payment.amount;
          }
        }
        break;
    }
  }

  void _deletePayment(Payment payment) async {
    // Afficher une boîte de dialogue de confirmation
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression',
              style: TextStyle(
                  fontSize: AppConstants.largeFontSize,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Êtes-vous sûr de vouloir supprimer cette commande ?',
                  style: TextStyle(fontSize: AppConstants.subtitleFontSize)),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Date : ${DateFormat('dd/MM/yyyy à HH:mm').format(payment.date)}',
                        style: TextStyle(
                            fontSize: AppConstants.bodyFontSize,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('Montant : ${formatPrice(payment.amount)}',
                        style: TextStyle(
                            fontSize: AppConstants.bodyFontSize,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('Mode : ${payment.paymentMethod}',
                        style: TextStyle(
                            fontSize: AppConstants.bodyFontSize,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text('Cette action est irréversible.',
                  style: TextStyle(
                      fontSize: AppConstants.bodyFontSize,
                      fontStyle: FontStyle.italic,
                      color: Colors.red[600])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler',
                  style: TextStyle(fontSize: AppConstants.subtitleFontSize)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Supprimer',
                  style: TextStyle(fontSize: AppConstants.subtitleFontSize)),
            ),
          ],
        );
      },
    );

    // Si l'utilisateur a confirmé la suppression
    if (confirmDelete == true) {
      // Supprimer le paiement de la liste
      setState(() {
        payments.remove(payment);
      });

      // Enregistrer les modifications dans SharedPreferences
      StorageService.savePayments(payments);

      // Mettre à jour la liste filtrée après la suppression
      filterPayments();

  // Afficher un message de confirmation
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Commande supprimée avec succès'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  void calculateSelectedTotals() {
    totalSelectedChecks = 0.0;
    totalSelectedCash = 0.0;
    totalSelectedSum = 0.0;

    for (var payment in filteredPayments) {
      if (payment.isSelected) {
        if (payment.paymentMethod == "Chèque") {
          totalSelectedChecks += payment.amount;
        } else if (payment.paymentMethod == "Espèces") {
          totalSelectedCash += payment.amount;
        }
      }
    }
    totalSelectedSum = totalSelectedCash + totalSelectedChecks;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2099));
  if (!mounted) return;
  if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        filterPayments();
      });
    }
  }

  void _togglePaymentSelection(Payment payment) {
    setState(() {
      payment.isSelected = !payment.isSelected;
  calculateSelectedTotals(); // Recalculer les totaux après chaque changement
    });
  }

  Widget _buildDateShortcut(String label, DateTime date) {
    bool isSelected = selectedDate.year == date.year &&
        selectedDate.month == date.month &&
        selectedDate.day == date.day;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size(104, 42),
      ),
      onPressed: () {
        setState(() {
          selectedDate = date;
          filterPayments();
        });
      },
      child: Text(
        label,
        style: TextStyle(fontSize: AppConstants.subtitleFontSize),
      ),
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
      filterPayments();
    });
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
      filterPayments();
    });
  }

  String _getPeriodTitle() {
    switch (currentViewMode) {
      case ViewMode.daily:
        return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(selectedDate);
      case ViewMode.weekly:
        final weekStart = _getWeekStart(selectedDate);
        final weekEnd =
            weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
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
    String formattedDate =
        DateFormat('dd/MM/yyyy à HH:mm').format(payment.date);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détail de la commande',
              style: TextStyle(
                  fontSize: AppConstants.titleFontSize,
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500, // Largeur fixe plus petite
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date : $formattedDate',
                    style: TextStyle(
                        fontSize: AppConstants.subtitleFontSize,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 16),
                Text('Articles commandés :',
                    style: TextStyle(
                        fontSize: AppConstants.subtitleFontSize,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (payment.items.isEmpty)
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
                            style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600])),
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
                            'Glaces'
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
                                    width: 4),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                    ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.name,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500)),
                                            Text(item.type,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: borderColor.withValues(alpha: 0.8))),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(formatPrice(item.price),
                                            style: TextStyle(fontSize: 16),
                                            textAlign: TextAlign.right),
                                      ),
                                      SizedBox(width: 8),
                                      SizedBox(
                                        width: 70,
                                        child: Text(formatPrice(item.totalPrice),
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700]),
                                            textAlign: TextAlign.right),
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
                Text('Mode de règlement : ${payment.paymentMethod}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Montant total : ${formatPrice(payment.amount)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.paymentHistoryTitle),
        ),
        body: Column(children: [
          Container(
            color: Colors.blue[50],
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
                          filterPayments();
                        });
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
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    // Boutons de raccourcis centrés (seulement pour le mode journalier)
                    if (currentViewMode == ViewMode.daily)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDateShortcut('Aujourd\'hui', DateTime.now()),
                          const SizedBox(width: 72),
                          _buildDateShortcut(
                              'Hier', DateTime.now().subtract(const Duration(days: 1))),
                          const SizedBox(width: 72),
                          _buildDateShortcut('Avant-hier',
                              DateTime.now().subtract(const Duration(days: 2))),
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
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(200, 42),
                          ),
                          onPressed: currentViewMode == ViewMode.daily
                              ? () => _selectDate(context)
                              : null,
                          child: Text(
                            _getPeriodTitle(),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
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
                  itemCount: filteredPayments.length,
                  itemBuilder: (context, index) {
                    var payment = filteredPayments[index];
                    // ignore: unused_local_variable
                    String formattedDate =
                        DateFormat('dd/MM/yyyy à H:mm').format(payment.date);

                    // Utiliser l'index pour alterner la couleur de fond
                    Color bgColor = index % 2 == 0
                        ? Colors.grey[200]!
                        : Colors.white; // Couleurs alternées

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
                                  color:
                                      payment.isSelected ? Colors.grey : null,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(payment.date),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: payment.isSelected
                                    ? Colors.grey
                                    : Colors.blue[700],
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
                                color:
                                    payment.isSelected ? Colors.grey : null,
                              ),
                            ),
                            if (payment.items.isNotEmpty)
                              Text(
                                "Articles: ${payment.items.map((pizza) => '${pizza.quantity} x ${pizza.name}').join(', ')}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: payment.isSelected
                                      ? Colors.grey
                                      : Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icône pour voir le détail de la commande
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () => _showPaymentDetails(payment),
                              tooltip: 'Voir le détail de la commande',
                            ),
                            // Icône pour supprimer l'encaissement
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePayment(payment),
                              tooltip: 'Supprimer cet encaissement',
                            ),
                          ],
                        ));
                  })),
          Container(
              color: Colors.lightBlue[100], // Définit la couleur de fond pour les totaux
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "Total pointé Chèques: ${formatPrice(totalSelectedChecks)}",
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total pointé Espèces: ${formatPrice(totalSelectedCash)}",
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Total pointé: ${formatPrice(totalSelectedSum)}",
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Text(
                    "Total Chèques: ${formatPrice(totalChecks)}",
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Total Espèces: ${formatPrice(totalCash)}",
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Total: ${formatPrice(totalSum)}",
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ]),
                SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getComparisonText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
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
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ]))
        ]));
  }
}
