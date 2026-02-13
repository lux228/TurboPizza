import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_pizza/pages/settings_page.dart';
import 'package:turbo_pizza/services/theme_service.dart';
import 'package:turbo_pizza/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Settings theme dropdown updates ThemeService', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final themeService = ThemeService();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeService,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const Scaffold(body: ThemeModeTile()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(themeService.themeMode, ThemeMode.system);

    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sombre').last);
    await tester.pumpAndSettle();

    expect(themeService.themeMode, ThemeMode.dark);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
