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

  void _deleteEncaissement(Encaissement encaissement) {
    // Supprimer l'encaissement de la liste
    setState(() {
      encaissements.remove(encaissement);
    });

    // Enregistrer les modifications dans SharedPreferences
    StorageService.saveEncaissements(encaissements);

    // Mettre à jour la liste filtrée après la suppression
    filterEncaissements();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Historique des Encaissements"),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sélectionner la date:",
                  style: TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text("${selectedDate.toLocal()}".split(' ')[0]),
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
                        title: Text(
                          "Montant: ${formatPrice(encaissement.montant)}",
                          style: TextStyle(
                            color: encaissement.isSelected ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          "Mode: ${encaissement.modeReglement}",
                          style: TextStyle(
                            color: encaissement.isSelected ? Colors.grey : null,
                          ),
                        ),
                        trailing:
                            PopupMenuButton<String>(itemBuilder: (context) {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ];
                        }, onSelected: (String value) {
                          if (value == 'delete') {
                            _deleteEncaissement(encaissement);
                          }
                        }));
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
