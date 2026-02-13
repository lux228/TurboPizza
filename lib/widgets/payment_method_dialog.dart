// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class PaymentMethodDialog extends StatefulWidget {
  final String currentSelection;

  const PaymentMethodDialog({super.key, required this.currentSelection});

  @override
  _PaymentMethodDialogState createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  ElevatedButton _createLargeButton(
    String text,
    VoidCallback onPressed, {
    required bool isSelected,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 50), // Agrandit le bouton
        textStyle: const TextStyle(fontSize: 18), // Agrandit le texte
        backgroundColor: isSelected ? AppConstants.successGreen : null,
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
    return AlertDialog(
      title: const Text("Choisir le mode de règlement"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < AppConstants.paymentMethods.length; i++) ...[
            _createLargeButton(
              AppConstants.paymentMethods[i],
              () => _handlePaymentMethodSelection(AppConstants.paymentMethods[i]),
              isSelected: AppConstants.paymentMethods[i] == widget.currentSelection,
            ),
            if (i < AppConstants.paymentMethods.length - 1)
              const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
