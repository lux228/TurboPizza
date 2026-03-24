import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_categories.dart';

class CategoryFilterService extends ChangeNotifier {
  static const String _showTopCategoryButtonsKey = 'show_top_category_buttons';

  final Set<String> _enabledTopCategories = AppCategories.topCategoryIds
      .toSet();
  bool _showTopCategoryButtons = true;
  bool _loaded = false;

  Set<String> get enabledTopCategories => _enabledTopCategories;
  bool get showTopCategoryButtons => _showTopCategoryButtons;
  bool get isLoaded => _loaded;

  CategoryFilterService() {
    _load();
  }

  Future<void> setShowTopCategoryButtons(bool value) async {
    if (_showTopCategoryButtons == value) return;
    _showTopCategoryButtons = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTopCategoryButtonsKey, value);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getBool(_showTopCategoryButtonsKey);
    _showTopCategoryButtons = raw ?? true;

    _loaded = true;
    notifyListeners();
  }
}
