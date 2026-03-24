class InvalidPickupTimeException implements Exception {
  final String pickupTime;

  const InvalidPickupTimeException(this.pickupTime);

  @override
  String toString() =>
      'InvalidPickupTimeException: pickupTime "$pickupTime" must match HH:mm (00:00-23:59)';
}
