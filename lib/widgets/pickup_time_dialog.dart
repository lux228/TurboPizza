import 'package:flutter/material.dart';

class PickupTimeDialog extends StatefulWidget {
  const PickupTimeDialog({super.key});

  @override
  _PickupTimeDialogState createState() => _PickupTimeDialogState();
}

class _PickupTimeDialogState extends State<PickupTimeDialog> {
  String? selectedTime;

  @override
  Widget build(BuildContext context) {
    // Générer les créneaux de 30 minutes sur les dizaines (19h00, 19h10, 19h30, etc.)
    List<String> timeSlots = [];
    DateTime now = DateTime.now();
    int currentHour = now.hour;
    
    // Commencer à partir de l'heure actuelle ou de l'heure suivante si on est déjà passé
    int startHour = currentHour;
    if (now.minute > 50) {
      startHour = currentHour + 1;
    }
    
    // Générer des créneaux pour les 6 prochaines heures
    for (int hour = startHour; hour < startHour + 6; hour++) {
      if (hour >= 24) break; // Ne pas dépasser minuit
      
      // Ajouter les créneaux : XX:00, XX:10, XX:20, XX:30, XX:40, XX:50
      for (int minute in [0, 10, 20, 30, 40, 50]) {
        String timeSlot = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        
        // Ne pas ajouter des créneaux dans le passé
        DateTime slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);
        if (slotDateTime.isAfter(now.add(const Duration(minutes: 10)))) {
          timeSlots.add(timeSlot);
        }
      }
    }

    return AlertDialog(
      title: const Text(
        'Heure de récupération prévue',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            String timeSlot = timeSlots[index];
            bool isSelected = selectedTime == timeSlot;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTime = timeSlot;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[100] : Colors.grey[100],
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    timeSlot,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue[800] : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: selectedTime != null
              ? () => Navigator.of(context).pop(selectedTime)
              : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
