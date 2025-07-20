import 'package:intl/intl.dart';

String formatPrice(double price) {
  final NumberFormat formatter = NumberFormat('0.00', 'fr_FR');
  return '${formatter.format(price)}€';
}
