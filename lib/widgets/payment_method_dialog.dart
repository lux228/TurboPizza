// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../constants/app_payments.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class PaymentMethodDialog extends StatefulWidget {
  final String currentSelection;

  const PaymentMethodDialog({super.key, required this.currentSelection});

  @override
  _PaymentMethodDialogState createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  ElevatedButton _createLargeButton(
    String text,
    VoidCallback onPressed,
    AppThemeColors colors, {
    required bool isSelected,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 50), // Agrandit le bouton
        textStyle: const TextStyle(fontSize: 18), // Agrandit le texte
        backgroundColor: isSelected ? colors.successGreen : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      child: Text(text),
    );
  }

  void _handlePaymentMethodSelection(String method) {
    Navigator.of(context).pop({'method': method});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: const Text(AppStrings.choosePaymentMethodTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < AppPayments.methods.length; i++) ...[
            _createLargeButton(
              AppPayments.methods[i],
              () => _handlePaymentMethodSelection(AppPayments.methods[i]),
              colors,
              isSelected: AppPayments.methods[i] == widget.currentSelection,
            ),
            if (i < AppPayments.methods.length - 1) const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
