// ignore_for_file: library_private_types_in_public_api
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
    DateTime now = DateTime.now();
    
    // Générer les créneaux de maintenant jusqu'à 22h
    Map<String, List<String>> timeSlotsByHour = _generateTimeSlots(now);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heure de récupération',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Heure de récupération de la commande',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Créneaux horaires
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: timeSlotsByHour.entries.map((entry) {
                      String hour = entry.key;
                      List<String> slots = entry.value;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 16),
                            child: Text(
                              hour,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: slots.map((timeSlot) {
                              bool isSelected = selectedTime == timeSlot;
                              String minutePart = timeSlot.split(':')[1];
                              
                              return Material(
                                elevation: isSelected ? 3 : 1,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    setState(() {
                                      selectedTime = timeSlot;
                                    });
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      color: isSelected ? Colors.blue[50] : Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        ':$minutePart',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? Colors.blue[800] : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Confirmation
            if (selectedTime != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Récupération prévue à $selectedTime',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: selectedTime != null
                        ? () => Navigator.of(context).pop(selectedTime)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTime != null ? Colors.blue : Colors.grey[300],
                      foregroundColor: selectedTime != null ? Colors.white : Colors.grey[600],
                      elevation: selectedTime != null ? 2 : 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      selectedTime != null ? 'Confirmer' : 'Choisir une heure',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Génère les créneaux de la prochaine dizaine jusqu'à 22h
  Map<String, List<String>> _generateTimeSlots(DateTime now) {
    Map<String, List<String>> slots = {};
    
    // Calculer le point de départ : prochaine dizaine
    int startHour = now.hour;
    int startMinute = ((now.minute ~/ 10) + 1) * 10;
    
    // Si on dépasse 50 minutes, passer à l'heure suivante
    if (startMinute >= 60) {
      startHour = (startHour + 1) % 24;
      startMinute = 0;
    }
    
    // Générer jusqu'à 22h (ou jusqu'à la fin de la journée si après 22h)
    int endHour = 22;
    if (startHour > 22) {
      return slots; // Pas de créneaux disponibles après 22h
    }
    
    for (int hour = startHour; hour <= endHour; hour++) {
      List<String> slotsForHour = [];
      for (int minute in [0, 10, 20, 30, 40, 50]) {
        DateTime slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);
        
        // Pour la première heure, ne prendre que les créneaux >= startMinute
        if (hour == startHour && minute < startMinute) continue;
        
        // Vérifier que le créneau est dans le futur (au moins 5 min d'avance)
        if (slotDateTime.isAfter(now.add(const Duration(minutes: 5)))) {
          slotsForHour.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
        }
      }
      if (slotsForHour.isNotEmpty) {
        slots['${hour.toString().padLeft(2, '0')}h'] = slotsForHour;
      }
    }
    
    return slots;
  }
}