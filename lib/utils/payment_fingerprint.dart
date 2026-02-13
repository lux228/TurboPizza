import '../models/payment.dart';
import '../models/pizza.dart';

String buildPaymentFingerprint(Payment payment) {
  final items = List<Pizza>.from(payment.items);
  items.sort((a, b) {
    final nameCmp = a.name.compareTo(b.name);
    if (nameCmp != 0) return nameCmp;
    final typeCmp = a.type.compareTo(b.type);
    if (typeCmp != 0) return typeCmp;
    final priceCmp = a.price.compareTo(b.price);
    if (priceCmp != 0) return priceCmp;
    return a.quantity.compareTo(b.quantity);
  });

  final itemsKey = items
      .map((item) =>
          '${item.name}|${item.type}|${item.price.toStringAsFixed(2)}|${item.quantity}')
      .join(',');

  final dateKey = payment.date.toIso8601String();
  final amountKey = payment.amount.toStringAsFixed(2);
  final methodKey = payment.paymentMethod;

  return '$dateKey|$amountKey|$methodKey|$itemsKey';
}
