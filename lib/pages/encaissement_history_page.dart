import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/encaissement.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';

enum ViewMode { daily, weekly, monthly }

class EncaissementHistoryPage extends StatefulWidget {
  const EncaissementHistoryPage({super.key});

  @override
  _EncaissementHistoryPageState createState() =>
      _EncaissementHistoryPageState();
}

class _EncaissementHistoryPageState extends State<EncaissementHistoryPage> {
  DateTime selectedDate = DateTime.now();
  ViewMode currentViewMode = ViewMode.daily;
  List<Encaissement> encaissements = [];
  List<Encaissement> filteredEncaissements = [];

  double totalCheques = 0.0;
  double totalEspeces = 0.0;
  double totalGroupe = 0.0;

  double totalPointeCheques = 0.0;
  double totalPointeEspeces = 0.0;
  double totalPointeGroupe = 0.0;

  double totalAnneePrecedente = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialiser les données de localisation pour le français
    initializeDateFormatting('fr_FR', null).then((_) {
      StorageService.loadEncaissements().then((loadedEncaissements) {
        setState(() {
          encaissements = loadedEncaissements;
          filterEncaissements();
        });
      });
    });
  }

  void filterEncaissements() {
    setState(() {
      switch (currentViewMode) {
        case ViewMode.daily:
          filteredEncaissements = encaissements
              .where((encaissement) =>
                  encaissement.date.year == selectedDate.year &&
                  encaissement.date.month == selectedDate.month &&
                  encaissement.date.day == selectedDate.day)
              .toList();
          break;
        case ViewMode.weekly:
          final weekStart = _getWeekStart(selectedDate);
          final weekEnd = weekStart.add(const Duration(days: 7));
          filteredEncaissements = encaissements
              .where((encaissement) =>
                  encaissement.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  encaissement.date.isBefore(weekEnd))
              .toList();
          break;
        case ViewMode.monthly:
          filteredEncaissements = encaissements
              .where((encaissement) =>
                  encaissement.date.year == selectedDate.year &&
                  encaissement.date.month == selectedDate.month)
              .toList();
          break;
      }
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

    // Calculer le total de l'année précédente pour la même période
    calculateTotalAnneePrecedente();
  }

  // Obtenir le début de la semaine (dimanche soir 20h)
  DateTime _getWeekStart(DateTime date) {
    // Trouver le dimanche précédent à 20h
    int daysToSunday = (date.weekday == 7) ? 0 : date.weekday;
    DateTime sundayStart = DateTime(date.year, date.month, date.day, 20, 0, 0)
        .subtract(Duration(days: daysToSunday));
    
    // Si on est dimanche mais avant 20h, prendre le dimanche précédent
    if (date.weekday == 7 && date.hour < 20) {
      sundayStart = sundayStart.subtract(const Duration(days: 7));
    }
    
    return sundayStart;
  }

  void calculateTotalAnneePrecedente() {
    totalAnneePrecedente = 0.0;

    switch (currentViewMode) {
      case ViewMode.daily:
        DateTime anneePrecedente = DateTime(selectedDate.year - 1, selectedDate.month, selectedDate.day);
        for (var encaissement in encaissements) {
          if (encaissement.date.year == anneePrecedente.year &&
              encaissement.date.month == anneePrecedente.month &&
              encaissement.date.day == anneePrecedente.day) {
            totalAnneePrecedente += encaissement.montant;
          }
        }
        break;
      case ViewMode.weekly:
        final weekStartPreviousYear = _getWeekStart(DateTime(selectedDate.year - 1, selectedDate.month, selectedDate.day));
        final weekEndPreviousYear = weekStartPreviousYear.add(const Duration(days: 7));
        for (var encaissement in encaissements) {
          if (encaissement.date.isAfter(weekStartPreviousYear.subtract(const Duration(days: 1))) &&
              encaissement.date.isBefore(weekEndPreviousYear)) {
            totalAnneePrecedente += encaissement.montant;
          }
        }
        break;
      case ViewMode.monthly:
        for (var encaissement in encaissements) {
          if (encaissement.date.year == selectedDate.year - 1 &&
              encaissement.date.month == selectedDate.month) {
            totalAnneePrecedente += encaissement.montant;
          }
        }
        break;
    }
  }

  void _deleteEncaissement(Encaissement encaissement) async {
    // Afficher une boîte de dialogue de confirmation
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Êtes-vous sûr de vouloir supprimer cette commande ?', style: TextStyle(fontSize: 16)),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date : ${DateFormat('dd/MM/yyyy à HH:mm').format(encaissement.date)}', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('Montant : ${formatPrice(encaissement.montant)}', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('Mode : ${encaissement.modeReglement}', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text('Cette action est irréversible.', 
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.red[600])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Supprimer', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );

    // Si l'utilisateur a confirmé la suppression
    if (confirmDelete == true) {
      // Supprimer l'encaissement de la liste
      setState(() {
        encaissements.remove(encaissement);
      });

      // Enregistrer les modifications dans SharedPreferences
      StorageService.saveEncaissements(encaissements);

      // Mettre à jour la liste filtrée après la suppression
      filterEncaissements();

      // Afficher un message de confirmation
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
          filterEncaissements();
        });
      },
      child: Text(
        label,
        style: TextStyle(fontSize: 16),
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
      filterEncaissements();
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
      filterEncaissements();
    });
  }

  String _getPeriodTitle() {
    switch (currentViewMode) {
      case ViewMode.daily:
        return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(selectedDate);
      case ViewMode.weekly:
        final weekStart = _getWeekStart(selectedDate);
        final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
        return 'Semaine du ${DateFormat('dd/MM', 'fr_FR').format(weekStart)} au ${DateFormat('dd/MM/yyyy', 'fr_FR').format(weekEnd)}';
      case ViewMode.monthly:
        return DateFormat('MMMM yyyy', 'fr_FR').format(selectedDate);
    }
  }

  String _getComparisonText() {
    switch (currentViewMode) {
      case ViewMode.daily:
        return "CA N-1 (${selectedDate.year - 1}): ${formatPrice(totalAnneePrecedente)}";
      case ViewMode.weekly:
        return "CA semaine N-1 (${selectedDate.year - 1}): ${formatPrice(totalAnneePrecedente)}";
      case ViewMode.monthly:
        return "CA ${DateFormat('MMMM', 'fr_FR').format(DateTime(selectedDate.year - 1, selectedDate.month))}: ${formatPrice(totalAnneePrecedente)}";
    }
  }

  void _showCommandeDetails(Encaissement encaissement) {
    String formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(encaissement.date);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détail de la commande', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500, // Largeur fixe plus petite
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date : $formattedDate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 16),
                Text('Articles commandés :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (encaissement.articles.isEmpty)
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
                        // Trier les articles par catégorie
                        var sortedArticles = List.from(encaissement.articles);
                        sortedArticles.sort((a, b) {
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
                                    child: Text('${formatPrice(article.price)}', 
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  SizedBox(
                                    width: 70,
                                    child: Text('${formatPrice(article.totalPrice)}', 
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
                Text('Mode de règlement : ${encaissement.modeReglement}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Montant total : ${formatPrice(encaissement.montant)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          title: const Text("Historique des Encaissements"),
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
                          filterEncaissements();
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
                      currentViewMode == ViewMode.daily ? "Sélectionner la date:" :
                      currentViewMode == ViewMode.weekly ? "Sélectionner la semaine:" :
                      "Sélectionner le mois:",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    // Boutons de raccourcis centrés (seulement pour le mode journalier)
                    if (currentViewMode == ViewMode.daily)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDateShortcut('Aujourd\'hui', DateTime.now()),
                          const SizedBox(width: 72),
                          _buildDateShortcut('Hier', DateTime.now().subtract(const Duration(days: 1))),
                          const SizedBox(width: 72),
                          _buildDateShortcut('Avant-hier', DateTime.now().subtract(const Duration(days: 2))),
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
                          tooltip: currentViewMode == ViewMode.daily ? 'Jour précédent' :
                                  currentViewMode == ViewMode.weekly ? 'Semaine précédente' :
                                  'Mois précédent',
                        ),
                        // Affichage de la période actuelle
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(200, 42),
                          ),
                          onPressed: currentViewMode == ViewMode.daily ? () => _selectDate(context) : null,
                          child: Text(
                            _getPeriodTitle(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Bouton période suivante
                        IconButton(
                          onPressed: _goToNextPeriod,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: currentViewMode == ViewMode.daily ? 'Jour suivant' :
                                  currentViewMode == ViewMode.weekly ? 'Semaine suivante' :
                                  'Mois suivant',
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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Montant: ${formatPrice(encaissement.montant)}",
                                style: TextStyle(
                                  color: encaissement.isSelected ? Colors.grey : null,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(encaissement.date),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: encaissement.isSelected ? Colors.grey : Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mode: ${encaissement.modeReglement}",
                              style: TextStyle(
                                color: encaissement.isSelected ? Colors.grey : null,
                              ),
                            ),
                            if (encaissement.articles.isNotEmpty)
                              Text(
                                "Articles: ${encaissement.articles.map((pizza) => '${pizza.name} x${pizza.quantity}').join(', ')}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: encaissement.isSelected ? Colors.grey : Colors.grey[600],
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
                              onPressed: () => _showCommandeDetails(encaissement),
                              tooltip: 'Voir le détail de la commande',
                            ),
                            // Icône pour supprimer l'encaissement
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEncaissement(encaissement),
                              tooltip: 'Supprimer cet encaissement',
                            ),
                          ],
                        ));
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
                    ]),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      if (totalGroupe > 0 && totalAnneePrecedente > 0)
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Text(
                              "(${totalGroupe > totalAnneePrecedente ? '+' : ''}${((totalGroupe - totalAnneePrecedente) / totalAnneePrecedente * 100).toStringAsFixed(1)}%)",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: totalGroupe >= totalAnneePrecedente ? Colors.green[700] : Colors.red[700],
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
