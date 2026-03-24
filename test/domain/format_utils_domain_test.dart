import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_pizza/utils/format_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatPrice', () {
    test('should use euro symbol and comma decimal separator', () {
      final s = formatPrice(12.5);
      expect(s.contains('€'), isTrue);
      expect(s.contains(','), isTrue);
    });

    test('should round to two decimals', () {
      final s = formatPrice(12.345);
      expect(s.contains('12,35'), isTrue);
    });

    test('should format zero amount with two decimals', () {
      final s = formatPrice(0);
      expect(s.contains('0,00'), isTrue);
    });
  });
}
