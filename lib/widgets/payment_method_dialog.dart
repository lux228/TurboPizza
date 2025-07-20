import 'package:flutter/material.dart';

class PaymentMethodDialog extends StatefulWidget {
  final String currentSelection;

  const PaymentMethodDialog({Key? key, required this.currentSelection})
      : super(key: key);

  @override
  _PaymentMethodDialogState createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  final _amountGivenController = TextEditingController();

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
    if (method == 'Espèces') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Espèces'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _createLargeButton('Appoint', () {
                  Navigator.of(context)
                      .pop(); // Ferme le dialogue intermédiaire
                  Navigator.of(context)
                      .pop({'method': method}); // Envoie "Espèces" sans montant
                }),
                const SizedBox(
                    height: 20), // Ajoute un espace entre les boutons
                _createLargeButton('Rendu monnaie', () {
                  Navigator.of(context)
                      .pop(); // Ferme le dialogue intermédiaire
                  _showEnterAmountDialog(); // Affiche le dialogue pour entrer le montant donné
                }),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.of(context).pop({'method': method});
    }
  }

  void _showEnterAmountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Montant donné par le client'),
          content: TextField(
            controller: _amountGivenController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Montant donné'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                final double amountGiven =
                    double.tryParse(_amountGivenController.text) ?? 0.0;
                Navigator.of(context)
                    .pop(); // Ferme le dialogue de montant donné
                Navigator.of(context).pop({
                  'method': 'Espèces',
                  'amountGiven': amountGiven
                }); // Envoie le montant donné
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
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
