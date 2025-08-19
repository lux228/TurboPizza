import '../models/pizza.dart';

/// Service de cache pour optimiser les performances
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache pour le tri des articles par catégorie
  final Map<String, List<Pizza>> _sortedArticlesCache = {};
  
  // Ordre de priorité des catégories pour le tri
  static const List<String> _categoryOrder = [
    'Tomate',
    'Crème', 
    'Spécialités',
    'Softs',
    'Vins',
    'Desserts',
    'Glaces'
  ];

  /// Génère une clé de cache basée sur la liste d'articles
  String _generateCacheKey(List<Pizza> articles) {
    return articles
        .map((a) => '${a.name}_${a.type}_${a.quantity}')
        .join('|');
  }

  /// Retourne les articles triés par catégorie (avec cache)
  List<Pizza> getSortedArticles(List<Pizza> articles) {
    final cacheKey = _generateCacheKey(articles);
    
    // Vérifier si le résultat est déjà en cache
    if (_sortedArticlesCache.containsKey(cacheKey)) {
      return _sortedArticlesCache[cacheKey]!;
    }

    // Trier les articles par catégorie
    final sortedArticles = List<Pizza>.from(articles);
    sortedArticles.sort((a, b) {
      int aIndex = _categoryOrder.indexOf(a.type);
      int bIndex = _categoryOrder.indexOf(b.type);
      
      // Si une catégorie n'est pas trouvée, la mettre à la fin
      if (aIndex == -1) aIndex = _categoryOrder.length;
      if (bIndex == -1) bIndex = _categoryOrder.length;
      
      // Si même catégorie, trier par nom
      if (aIndex == bIndex) {
        return a.name.compareTo(b.name);
      }
      
      return aIndex.compareTo(bIndex);
    });

    // Mettre en cache et retourner
    _sortedArticlesCache[cacheKey] = sortedArticles;
    
    // Nettoyer le cache si nécessaire
    _cleanupCacheIfNeeded();
    
    return sortedArticles;
  }

  /// Vide le cache (à appeler quand nécessaire pour libérer la mémoire)
  void clearCache() {
    _sortedArticlesCache.clear();
  }

  /// Retourne le nombre d'entrées en cache
  int get cacheSize => _sortedArticlesCache.length;

  /// Vide le cache si il devient trop volumineux (>50 entrées)
  void _cleanupCacheIfNeeded() {
    if (_sortedArticlesCache.length > 50) {
      // Garder seulement les 25 entrées les plus récentes
      final keys = _sortedArticlesCache.keys.toList();
      final keysToRemove = keys.take(keys.length - 25);
      for (final key in keysToRemove) {
        _sortedArticlesCache.remove(key);
      }
    }
  }
}
