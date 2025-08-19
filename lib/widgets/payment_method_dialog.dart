// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';

class PaymentMethodDialog extends StatefulWidget {
  final String currentSelection;

  const PaymentMethodDialog({super.key, required this.currentSelection});

  @override
  _PaymentMethodDialogState createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  ElevatedButton _createLargeButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 50), // Agrandit le bouton
        textStyle: const TextStyle(fontSize: 18), // Agrandit le texte
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
          _createLargeButton(
              "Espèces", () => _handlePaymentMethodSelection("Espèces")),
          const SizedBox(height: 20), // Ajoute un espace entre les boutons
          _createLargeButton(
              "Chèque", () => _handlePaymentMethodSelection("Chèque")),
        ],
      ),
    );
  }
}
