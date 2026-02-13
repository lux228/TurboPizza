// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PickupTimeDialog extends StatefulWidget {
  final String? initialTime;
  
  const PickupTimeDialog({super.key, this.initialTime});

  @override
  _PickupTimeDialogState createState() => _PickupTimeDialogState();
}

class _PickupTimeDialogState extends State<PickupTimeDialog> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int selectedHour;
  late int selectedMinute;
  String? selectedTime;

  @override
  void initState() {
    super.initState();
    
    if (widget.initialTime != null) {
      // Utiliser l'horaire initial fourni
      final parts = widget.initialTime!.split(':');
      if (parts.length == 2) {
        selectedHour = int.tryParse(parts[0]) ?? DateTime.now().hour;
        selectedMinute = int.tryParse(parts[1]) ?? 0;
        // S'assurer que les minutes sont un multiple de 5
        selectedMinute = (selectedMinute ~/ 5) * 5;
      } else {
        _initializeWithCurrentTime();
      }
    } else {
      _initializeWithCurrentTime();
    }
    
    // Initialiser les contrôleurs de défilement
    _hourController = FixedExtentScrollController(initialItem: selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: selectedMinute ~/ 5);
    
    _updateSelectedTime();
  }
  
  void _initializeWithCurrentTime() {
    // Initialiser avec l'heure actuelle + 5 minutes minimum
    DateTime now = DateTime.now();
    DateTime futureTime = now.add(const Duration(minutes: 5));
    selectedHour = futureTime.hour;
    selectedMinute = futureTime.minute;
    // Arrondir les minutes au multiple de 5 suivant
    selectedMinute = ((selectedMinute / 5).ceil() * 5) % 60;
    if (selectedMinute == 0) {
      selectedMinute = 0;
      selectedHour = (selectedHour + 1) % 24;
    }
    // S'assurer qu'on ne dépasse pas minuit
    if (selectedHour >= 24) {
      selectedHour = 23;
      selectedMinute = 55;
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _updateSelectedTime() {
    selectedTime = '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
  }

  void _validateTimeSelection() {
    DateTime now = DateTime.now();
    // Si on sélectionne l'heure actuelle, s'assurer que les minutes sont dans le futur
    if (selectedHour == now.hour) {
      int minMinute = ((now.minute + 5) / 5).ceil() * 5;
      if (minMinute >= 60) {
        // Si on dépasse 60 minutes, passer à l'heure suivante
        selectedHour = (selectedHour + 1) % 24;
        selectedMinute = 0;
        // Mettre à jour les contrôleurs
        _hourController.animateToItem(selectedHour, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        _minuteController.animateToItem(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else if (selectedMinute < minMinute) {
        selectedMinute = minMinute;
        _minuteController.animateToItem(selectedMinute ~/ 5, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;
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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heure de récupération',
                        style: textStyles.title.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Heure de récupération de la commande',
                        style: textStyles.caption.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Cadran tactile centré
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceContainerHighest,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Titre du cadran
                    Text(
                      'Sélectionner l\'heure',
                      style: textStyles.title.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    // Cadrans tactiles côte à côte
                    Expanded(
                      child: Row(
                        children: [
                          // Cadran des heures
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Heures',
                                  style: textStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    controller: _hourController,
                                    itemExtent: 60,
                                    physics: const FixedExtentScrollPhysics(),
                                    overAndUnderCenterOpacity: 0.3,
                                    magnification: 1.2,
                                    useMagnifier: true,
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedHour = index;
                                        _validateTimeSelection();
                                        _updateSelectedTime();
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      builder: (context, index) {
                                        if (index < 0 || index >= 24) return null;
                                        
                                        DateTime now = DateTime.now();
                                        bool isDisabled = _isHourDisabled(index, now);
                                        bool isSelected = selectedHour == index;
                                        
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                              ? colorScheme.primary.withValues(alpha: 0.12)
                                              : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            border: isSelected 
                                              ? Border.all(color: colorScheme.primary, width: 2)
                                              : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index.toString().padLeft(2, '0')}h',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: isSelected 
                                                  ? FontWeight.bold 
                                                  : FontWeight.w500,
                                                color: isDisabled 
                                                  ? colorScheme.onSurface.withValues(alpha: 0.3)
                                                  : isSelected 
                                                    ? colorScheme.primary 
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Séparateur
                          Container(
                            width: 2,
                            height: 200,
                            color: colorScheme.outline,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          
                          // Cadran des minutes
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Minutes',
                                  style: textStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    controller: _minuteController,
                                    itemExtent: 60,
                                    physics: const FixedExtentScrollPhysics(),
                                    overAndUnderCenterOpacity: 0.3,
                                    magnification: 1.2,
                                    useMagnifier: true,
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedMinute = index * 5;
                                        _updateSelectedTime();
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      builder: (context, index) {
                                        if (index < 0 || index >= 12) return null;
                                        
                                        int minute = index * 5;
                                        DateTime now = DateTime.now();
                                        bool isDisabled = _isMinuteDisabled(minute, now);
                                        bool isSelected = selectedMinute == minute;
                                        
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                              ? colorScheme.primary.withValues(alpha: 0.12)
                                              : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            border: isSelected 
                                              ? Border.all(color: colorScheme.primary, width: 2)
                                              : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              minute.toString().padLeft(2, '0'),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: isSelected 
                                                  ? FontWeight.bold 
                                                  : FontWeight.w500,
                                                color: isDisabled 
                                                  ? colorScheme.onSurface.withValues(alpha: 0.3)
                                                  : isSelected 
                                                    ? colorScheme.primary 
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Annuler', style: textStyles.body),
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
                      backgroundColor: selectedTime != null
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      foregroundColor: selectedTime != null
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                      elevation: selectedTime != null ? 2 : 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      selectedTime != null ? 'Confirmer' : 'Choisir une heure',
                      style: textStyles.body.copyWith(fontWeight: FontWeight.w600),
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
  
  bool _isHourDisabled(int hour, DateTime now) {
    // Désactiver les heures passées 
    if (hour < now.hour) return true;
    // Les heures sont disponibles jusqu'à 23h (ne pas dépasser la journée)
    return false;
  }
  
  bool _isMinuteDisabled(int minute, DateTime now) {
    // Si on est à l'heure actuelle, désactiver les minutes passées + 5 minutes de marge
    if (selectedHour == now.hour && minute <= (now.minute + 5)) return true;
    return false;
  }
}