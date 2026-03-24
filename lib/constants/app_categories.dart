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
    'pizza',
    'specialites',
    'desserts',
    'boissons',
  ];

  static const Map<String, String> topCategoryLabels = {
    'pizza': 'Pizza',
    'specialites': 'Spécialités',
    'desserts': 'Desserts',
    'boissons': 'Boissons',
  };

  static const Map<String, List<String>> topCategoryTypeMap = {
    'pizza': ['Tomate', 'Crème'],
    'specialites': ['Spécialités'],
    'desserts': ['Desserts', 'Glaces'],
    'boissons': ['Softs', 'Vins'],
  };
}
