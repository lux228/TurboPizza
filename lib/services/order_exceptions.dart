class InvalidPickupTimeException implements Exception {
  final String pickupTime;

  const InvalidPickupTimeException(this.pickupTime);

  @override
  String toString() =>
      'InvalidPickupTimeException: pickupTime "$pickupTime" must match HH:mm (00:00-23:59)';
}

class EmptyOrderItemsException implements Exception {
  const EmptyOrderItemsException();

  @override
  String toString() =>
      'EmptyOrderItemsException: order must contain at least one item';
}

class InvalidOrderAmountException implements Exception {
  final double amount;

  const InvalidOrderAmountException(this.amount);

  @override
  String toString() =>
      'InvalidOrderAmountException: amount "$amount" must be > 0';
}
