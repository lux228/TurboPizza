import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_pizza/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService', () {
    test('defaults to system when no preference stored', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ThemeService();
      await pumpUntilLoaded(service);
      expect(service.themeMode, ThemeMode.system);
    });

    test('loads persisted theme mode', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final service = ThemeService();
      await pumpUntilLoaded(service);
      expect(service.themeMode, ThemeMode.dark);
    });

    test('setThemeMode persists and notifies', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ThemeService();
      await pumpUntilLoaded(service);

      var notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.setThemeMode(ThemeMode.light);
      expect(service.themeMode, ThemeMode.light);
      expect(notifyCount, greaterThan(0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });
  });
}

Future<void> pumpUntilLoaded(ThemeService service) async {
  var guard = 0;
  while (!service.isLoaded && guard < 50) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    guard += 1;
  }
}
