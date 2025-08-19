import '../models/pizza.dart';
import '../constants/app_constants.dart';

/// Service de cache pour optimiser les performances
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache pour le tri des articles par catégorie
  final Map<String, List<Pizza>> _sortedItemsCache = {};
  
  // Utilise l'ordre de catégories centralisé dans AppConstants
  static const List<String> _categoryOrder = AppConstants.categoryOrder;

  /// Génère une clé de cache basée sur la liste d'articles
  String _generateCacheKey(List<Pizza> items) {
    return items
        .map((a) => '${a.name}_${a.type}_${a.quantity}')
        .join('|');
  }

  /// Retourne les articles triés par catégorie (avec cache)
  List<Pizza> getSortedItems(List<Pizza> items) {
    final cacheKey = _generateCacheKey(items);
    
    // Vérifier si le résultat est déjà en cache
    if (_sortedItemsCache.containsKey(cacheKey)) {
      return _sortedItemsCache[cacheKey]!;
    }

    // Trier les articles par catégorie
  final sortedItems = List<Pizza>.from(items);
  sortedItems.sort((a, b) {
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
  _sortedItemsCache[cacheKey] = sortedItems;
    
    // Nettoyer le cache si nécessaire
    _cleanupCacheIfNeeded();
    
  return sortedItems;
  }

  /// Vide le cache (à appeler quand nécessaire pour libérer la mémoire)
  void clearCache() {
    _sortedItemsCache.clear();
  }

  /// Retourne le nombre d'entrées en cache
  int get cacheSize => _sortedItemsCache.length;

  /// Vide le cache si il devient trop volumineux (>50 entrées)
  void _cleanupCacheIfNeeded() {
  if (_sortedItemsCache.length > 50) {
      // Garder seulement les 25 entrées les plus récentes
  final keys = _sortedItemsCache.keys.toList();
      final keysToRemove = keys.take(keys.length - 25);
      for (final key in keysToRemove) {
  _sortedItemsCache.remove(key);
      }
    }
  }
}
