import 'package:flutter/material.dart';
import '../utils/format_utils.dart';

class CalculatorDialog extends StatefulWidget {
  final double currentOrderTotal;
  
  const CalculatorDialog({super.key, required this.currentOrderTotal});

  @override
  _CalculatorDialogState createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _previousNumber = '';
  String _operation = '';
  bool _waitingForOperand = false;

  void _inputNumber(String number) {
    setState(() {
      if (_waitingForOperand) {
        _display = number;
        _waitingForOperand = false;
      } else {
        _display = _display == '0' ? number : _display + number;
      }
    });
  }

  void _inputOperation(String operation) {
    setState(() {
      if (_previousNumber.isEmpty) {
        _previousNumber = _display;
      } else if (!_waitingForOperand) {
        _calculate();
      }
      
      _operation = operation;
      _waitingForOperand = true;
    });
  }

  void _calculate() {
    if (_previousNumber.isEmpty || _operation.isEmpty) return;

    double prev = double.tryParse(_previousNumber) ?? 0;
    double current = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operation) {
      case '+':
        result = prev + current;
        break;
      case '-':
        result = prev - current;
        break;
      case '×':
        result = prev * current;
        break;
      case '÷':
        result = current != 0 ? prev / current : 0;
        break;
    }

    setState(() {
      _display = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
      _previousNumber = '';
      _operation = '';
      _waitingForOperand = true;
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _previousNumber = '';
      _operation = '';
      _waitingForOperand = false;
    });
  }

  Widget _buildButton(String text, {Color? color, Color? textColor, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: textColor ?? Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (text == 'C') {
              _clear();
            } else if (text == '=') {
              _calculate();
            } else if (['+', '-', '×', '÷'].contains(text)) {
              _inputOperation(text);
            } else {
              _inputNumber(text);
            }
          },
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calculatrice'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Écran d'affichage
            Container(
              width: double.infinity,
              height: 80,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _display,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Affichage du montant de la commande en cours
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Commande en cours :',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    formatPrice(widget.currentOrderTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // Grille de boutons
            Column(
              children: [
                // Ligne 1: C (vide) (vide) ÷
                Row(children: [
                  _buildButton('C', color: Colors.red[400], textColor: Colors.white),
                  const Expanded(child: SizedBox()), // Espace vide
                  const Expanded(child: SizedBox()), // Espace vide
                  _buildButton('÷', color: Colors.orange[300]),
                ]),
                // Ligne 2: 7 8 9 ×
                Row(children: [
                  _buildButton('7'),
                  _buildButton('8'),
                  _buildButton('9'),
                  _buildButton('×', color: Colors.orange[300]),
                ]),
                // Ligne 3: 4 5 6 -
                Row(children: [
                  _buildButton('4'),
                  _buildButton('5'),
                  _buildButton('6'),
                  _buildButton('-', color: Colors.orange[300]),
                ]),
                // Ligne 4: 1 2 3 +
                Row(children: [
                  _buildButton('1'),
                  _buildButton('2'),
                  _buildButton('3'),
                  _buildButton('+', color: Colors.orange[300]),
                ]),
                // Ligne 5: 0 (double largeur) . =
                Row(children: [
                  _buildButton('0', flex: 2),
                  _buildButton('.'),
                  _buildButton('=', color: Colors.blue[400], textColor: Colors.white),
                ]),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
