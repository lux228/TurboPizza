class AppCategories {
  static const List<String> categoryOrder = [
    'Tomate',
    'Crème',
    'Spécialités',
    'Softs',
    'Vins',
    'Desserts',
    'Glaces',
  ];

  static const List<String> topCategoryIds = [
    'tomate',
    'creme',
    'specialites',
    'desserts',
    'boissons',
  ];

  static const Map<String, String> topCategoryLabels = {
    'tomate': 'Tomate',
    'creme': 'Crème',
    'specialites': 'Spécialités',
    'desserts': 'Desserts',
    'boissons': 'Boissons',
  };

  static const Map<String, List<String>> topCategoryTypeMap = {
    'tomate': ['Tomate'],
    'creme': ['Crème'],
    'specialites': ['Spécialités'],
    'desserts': ['Desserts', 'Glaces'],
    'boissons': ['Softs', 'Vins'],
  };
}
