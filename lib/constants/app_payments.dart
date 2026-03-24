class AppPayments {
  static const String cash = 'Espèces';
  static const String check = 'Chèque';
  static const String transfer = 'Virement';

  static const String defaultPaymentMethod = cash;
  static const List<String> methods = [cash, check, transfer];
}
