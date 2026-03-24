// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class PickupTimeDialog extends StatefulWidget {
  final String? initialTime;

  const PickupTimeDialog({super.key, this.initialTime});

  @override
  _PickupTimeDialogState createState() => _PickupTimeDialogState();
}

class _PickupTimeDialogState extends State<PickupTimeDialog> {
  late int selectedHour;
  late int selectedMinute;
  late final DateTime _referenceNow;
  String? selectedTime;
  static const List<int> _minuteOptions = [0, 10, 20, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    _referenceNow = DateTime.now();
    _initializeSelection();
  }

  void _initializeSelection() {
    final slotsByHour = _buildAvailableSlotsByHour();
    final firstSlot = _firstAvailableSlot(slotsByHour);

    if (firstSlot == null) {
      selectedHour = 0;
      selectedMinute = 0;
      selectedTime = null;
      return;
    }

    final initialSlot = _parseInitialSlot();
    if (initialSlot != null &&
        _isSlotAvailable(initialSlot.hour, initialSlot.minute, slotsByHour)) {
      selectedHour = initialSlot.hour;
      selectedMinute = initialSlot.minute;
    } else {
      selectedHour = firstSlot.hour;
      selectedMinute = firstSlot.minute;
    }

    _updateSelectedTime();
  }

  void _updateSelectedTime() {
    selectedTime =
        '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
  }

  _TimeSlot? _parseInitialSlot() {
    final value = widget.initialTime;
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23) return null;

    final roundedMinute = (minute ~/ 10) * 10;
    if (!_minuteOptions.contains(roundedMinute)) return null;
    return _TimeSlot(hour: hour, minute: roundedMinute);
  }

  Map<int, List<int>> _buildAvailableSlotsByHour() {
    final now = _referenceNow;
    final minimumTime = now.add(const Duration(minutes: 5));
    final slots = <int, List<int>>{};

    // Ajouter l'initialTime à la sélection s'il est fourni (pour les modifications)
    final initialSlot = _parseInitialSlot();

    // Afficher les heures de 0 à 23 (journée complète)
    for (int hour = 0; hour <= 23; hour++) {
      final minutes = <int>[];

      for (final minute in _minuteOptions) {
        final slot = DateTime(now.year, now.month, now.day, hour, minute);
        if (!slot.isBefore(minimumTime)) {
          minutes.add(minute);
        }
      }

      // Inclure l'initialTime même s'il est en dehors des créneaux normaux
      if (initialSlot != null &&
          initialSlot.hour == hour &&
          !minutes.contains(initialSlot.minute)) {
        minutes.add(initialSlot.minute);
        minutes.sort();
      }

      if (minutes.isNotEmpty) {
        slots[hour] = minutes;
      }
    }

    return slots;
  }

  _TimeSlot? _firstAvailableSlot(Map<int, List<int>> slotsByHour) {
    for (final entry in slotsByHour.entries) {
      if (entry.value.isNotEmpty) {
        return _TimeSlot(hour: entry.key, minute: entry.value.first);
      }
    }
    return null;
  }

  bool _isSlotAvailable(int hour, int minute, Map<int, List<int>> slotsByHour) {
    final minutes = slotsByHour[hour];
    if (minutes == null) return false;
    return minutes.contains(minute);
  }

  void _selectSlot(int hour, int minute) {
    setState(() {
      selectedHour = hour;
      selectedMinute = minute;
      _updateSelectedTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;
    final slotsByHour = _buildAvailableSlotsByHour();
    final hasAvailableSlot = slotsByHour.isNotEmpty;

    if (hasAvailableSlot &&
        !_isSlotAvailable(selectedHour, selectedMinute, slotsByHour)) {
      final firstSlot = _firstAvailableSlot(slotsByHour);
      if (firstSlot != null) {
        selectedHour = firstSlot.hour;
        selectedMinute = firstSlot.minute;
        _updateSelectedTime();
      }
    }

    if (!hasAvailableSlot) {
      selectedTime = null;
    }

    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 720 ? size.width * 0.96 : 700.0;
    final dialogHeight = size.height < 860 ? size.height * 0.92 : 780.0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tableau horaire heure x minutes
            Expanded(
              child: hasAvailableSlot
                  ? SingleChildScrollView(
                      child: Column(
                        children: slotsByHour.entries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _buildHourRow(
                                  hour: entry.key,
                                  availableMinutes: entry.value,
                                  textStyles: textStyles,
                                  colorScheme: colorScheme,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : Center(
                      child: Text(
                        AppStrings.noSlotsAvailableTodayMessage,
                        style: textStyles.body.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
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
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(AppStrings.cancelLabel, style: textStyles.body),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: hasAvailableSlot && selectedTime != null
                        ? () => Navigator.of(context).pop(selectedTime)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAvailableSlot && selectedTime != null
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      foregroundColor: hasAvailableSlot && selectedTime != null
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                      elevation: hasAvailableSlot && selectedTime != null
                          ? 2
                          : 0,
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      hasAvailableSlot && selectedTime != null
                          ? AppStrings.confirmLabel
                          : AppStrings.noSlotLabel,
                      style: textStyles.body.copyWith(
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

  Widget _buildHourRow({
    required int hour,
    required List<int> availableMinutes,
    required AppTextStyles textStyles,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            '${hour.toString().padLeft(2, '0')}h',
            style: textStyles.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ..._minuteOptions.map((minute) {
          final isVisible = availableMinutes.contains(minute);
          final isSelected = selectedHour == hour && selectedMinute == minute;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: isVisible
                  ? SizedBox(
                      height: 68,
                      child: Material(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.16)
                            : colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _selectSlot(hour, minute),
                          child: Center(
                            child: Text(
                              minute.toString().padLeft(2, '0'),
                              style: textStyles.body.copyWith(
                                fontSize: 20,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }),
      ],
    );
  }
}

class _TimeSlot {
  final int hour;
  final int minute;

  const _TimeSlot({required this.hour, required this.minute});
}
