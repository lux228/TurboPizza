import 'package:intl/intl.dart';

String formatPrice(double price) {
  // Utilise le format monétaire FR officiel, ex: 12,50 €
  final NumberFormat formatter = NumberFormat.simpleCurrency(
    locale: 'fr_FR',
    name: 'EUR',
  );
  return formatter.format(price);
}
