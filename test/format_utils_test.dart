import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_pizza/utils/format_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formatPrice uses fr_FR currency format', () {
    final s = formatPrice(12.5);
    // Exemple attendu: "12,50 €" (avec espace insécable fine)
    expect(s.contains('€'), true);
    expect(s.contains(','), true);
  });
}
