import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/encaissement.dart';
import '../utils/format_utils.dart';
import '../utils/storage_service.dart';

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
    StorageService.loadEncaissements().then((loadedEncaissements) {
      setState(() {
        encaissements = loadedEncaissements;
        filterEncaissements();
      });
    });
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size(80, 32),
      ),
      onPressed: () {
        setState(() {
          selectedDate = date;
          filterEncaissements();
        });
      },
      child: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const List<String> dayNames = [
      '', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return dayNames[date.weekday];
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
                                        Text(article.type, style: TextStyle(fontSize: 14, color: borderColor.withOpacity(0.8))),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sélectionner la date:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton date précédente
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = selectedDate.subtract(Duration(days: 1));
                              filterEncaissements();
                            });
                          },
                          icon: Icon(Icons.chevron_left),
                          tooltip: 'Jour précédent',
                        ),
                        // Affichage de la date actuelle avec jour de la semaine
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => _selectDate(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getDayName(selectedDate),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(selectedDate),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        // Bouton date suivante
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = selectedDate.add(Duration(days: 1));
                              filterEncaissements();
                            });
                          },
                          icon: Icon(Icons.chevron_right),
                          tooltip: 'Jour suivant',
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Boutons de raccourcis
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDateShortcut('Aujourd\'hui', DateTime.now()),
                    _buildDateShortcut('Hier', DateTime.now().subtract(Duration(days: 1))),
                    _buildDateShortcut('Avant-hier', DateTime.now().subtract(Duration(days: 2))),
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
                    ])
              ]))
        ]));
  }
}
