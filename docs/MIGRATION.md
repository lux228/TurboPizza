# Guide de Migration - TurboPizza

## Vue d'ensemble

TurboPizza a migré de **SharedPreferences** vers **SQLite** pour le stockage des données. Cette migration est automatique et transparente pour l'utilisateur.

## 🔄 Processus de migration automatique

### Au démarrage de l'application

1. L'application vérifie si la migration a déjà été effectuée
2. Si oui, la migration est ignorée (utiliser le mode forcé si nécessaire)
3. Si non, elle charge les données depuis SharedPreferences :
   - Produits (pizzas, boissons, etc.)
   - Historique des paiements
   - Commandes en attente
4. **Fusion intelligente** des données sans créer de doublons :
   - **Produits** : UPSERT basé sur le nom (nouveau produit créé ou prix/type mis à jour)
   - **Paiements** : Évite les doublons exacts (même date, montant et mode de paiement)
   - **Commandes en attente** : UPSERT basé sur l'ID de commande
5. Un marqueur est enregistré pour éviter les migrations répétées
6. Les statistiques de migration sont sauvegardées (nombre réel d'éléments migrés)

### Logs de migration

La migration affiche des logs détaillés dans la console :

```
[Migration] Début de la migration intelligente depuis SharedPreferences...
[Migration] Trouvé: 15 produits, 42 paiements, 3 commandes
[Migration] Produit "Margherita" mis à jour
[Migration] Paiement doublé ignoré: 2026-01-15 14:30:00.000 - 25.0€
[Migration] Commande "order_456" déjà existante, ignorée
[Migration] ✅ Terminée: 12 produits, 38 paiements, 2 commandes migrées
```

### Fusion intelligente vs duplication

La migration **ne duplique jamais** les données :
- Si un produit existe déjà avec le même nom, seul le prix/type est mis à jour
- Si un paiement existe avec même date/montant/mode, il est ignoré
- Si une commande existe avec le même ID, elle est ignorée

## 🛠️ Outils de diagnostic

### MigrationUtility

Classe utilitaire pour gérer la migration manuellement :

```dart
// Vérifier s'il y a des données legacy
final hasLegacy = await MigrationUtility.hasLegacyData();

// Obtenir un diagnostic complet
final diagnostic = await MigrationUtility.diagnose();
print(diagnostic.summary);

// Forcer une migration (si nécessaire)
final stats = await MigrationUtility.forceMigration();

// Nettoyer les données legacy après migration
await MigrationUtility.clearLegacyData();

// Exporter les données legacy en JSON (backup)
final json = await MigrationUtility.exportLegacyDataAsJson();
```

### Widget de diagnostic (optionnel)

Un widget visuel peut être ajouté dans les paramètres pour afficher l'état de la migration :

```dart
import 'package:turbo_pizza/widgets/migration_diagnostic_widget.dart';

// Dans votre page de paramètres
MigrationDiagnosticWidget(),
```

Le widget affiche :
- ✅ État de la migration (complétée ou non)
- 📊 Nombre de données legacy vs actuelles
- 🔧 Actions disponibles (forcer migration, nettoyer legacy)

## 🔐 Sécurité et backups

### Backup automatique lors de l'import

Lors de l'import d'une base de données, un backup automatique est créé :

```dart
// Import avec backup automatique (par défaut)
final backupPath = await BackupService.instance.importDatabase('chemin/vers/db');
print('Backup créé: $backupPath');

// Import sans backup (déconseillé)
await BackupService.instance.importDatabase('chemin/vers/db', createBackup: false);

// Restaurer depuis un backup
await BackupService.instance.restoreFromBackup(backupPath);
```

Les backups sont nommés avec un timestamp :
```
turbopizza.db.backup_2026-02-12T23-07-06.601777
```

## 📝 Statistiques de migration

Les statistiques sont enregistrées dans la base de données :

```dart
final migrationService = MigrationService(DatabaseService.instance.database);
final stats = await migrationService.getMigrationStats();

if (stats != null) {
  print('Migration effectuée le ${stats.migrationDate}');
  print('${stats.productsCount} produits migrés');
  print('${stats.paymentsCount} paiements migrés');
  print('${stats.pendingOrdersCount} commandes migrées');
}
```

## 🚨 Résolution de problèmes

### La migration ne s'effectue pas

1. Vérifier qu'il y a bien des données dans SharedPreferences :
   ```dart
   final hasLegacy = await MigrationUtility.hasLegacyData();
   ```

2. Consulter le diagnostic :
   ```dart
   final diagnostic = await MigrationUtility.diagnose();
   print(diagnostic.summary);
   ```

3. Forcer une migration si nécessaire :
   ```dart
   await MigrationUtility.forceMigration();
   ```
   **Note** : La migration forcée est sûre, elle fusionne intelligemment les données sans créer de doublons.

### Données manquantes après migration

1. Vérifier les statistiques de migration
2. Comparer les compteurs legacy vs actuels
3. Si des données existent dans les deux sources :
   - Produits : Les produits dans SQLite ont priorité, seuls les nouveaux sont ajoutés
   - Paiements : Seuls les paiements non-dupliqués sont migrés
   - Commandes : Seules les nouvelles commandes sont ajoutées
4. Forcer une re-migration pour synchroniser les nouvelles données legacy

### Données dupliquées détectées

Si vous voyez des logs comme :
```
[Migration] Paiement doublé ignoré: 2026-01-15 14:30:00.000 - 25.0€
```

C'est **normal** ! La migration détecte et évite automatiquement les doublons.

### Migration déjà effectuée mais nouvelles données dans SharedPreferences

Utilisez le mode forcé pour re-migrer :
```dart
await MigrationUtility.forceMigration();
```

Ceci :
- Efface le marqueur de migration
- Re-lance la migration
- Fusionne uniquement les nouvelles données
- Ne crée pas de doublons

### Réinitialiser complètement

Pour repartir de zéro :

```dart
// 1. Supprimer la base SQLite
await DatabaseService.instance.close();
final dbFile = File(DatabaseService.instance.databasePath);
await dbFile.delete();

// 2. Réinitialiser
await DatabaseService.instance.init();

// 3. La migration se fera automatiquement au prochain démarrage
```

## 📊 Structure des données migrées

### Avant (SharedPreferences)
```json
{
  "pizzas": ["json1", "json2", ...],
  "payments": ["json1", "json2", ...],
  "pending_orders": ["json1", "json2", ...]
}
```

### Après (SQLite)
```sql
-- Tables normalisées avec relations
products (id, name, price, type, active)
payments (id, date, amount, payment_method)
payment_items (id, payment_id, name, type, unit_price, quantity)
pending_orders (id, created_at, planned_pickup, amount)
pending_order_items (id, order_id, name, type, unit_price, quantity)
meta (key, value) -- pour les métadonnées de migration
```

## ✅ Checklist de migration

- [x] Migration automatique au démarrage
- [x] **Fusion intelligente sans doublons**
- [x] Détection et évitement des paiements dupliqués
- [x] UPSERT pour produits et commandes
- [x] Logs de diagnostic détaillés
- [x] Statistiques de migration sauvegardées (nombre réel d'éléments migrés)
- [x] Utilitaires de diagnostic manuel
- [x] Widget visuel optionnel
- [x] Backup automatique avant import
- [x] Export des données legacy en JSON
- [x] Nettoyage sécurisé des données legacy
- [x] Tests automatisés de fusion et détection de doublons

## 🔗 Fichiers concernés

- [lib/services/migration_service.dart](../services/migration_service.dart) - Logique de migration
- [lib/services/database_service.dart](../services/database_service.dart) - Gestion de la base
- [lib/utils/migration_utility.dart](../utils/migration_utility.dart) - Outils de diagnostic
- [lib/widgets/migration_diagnostic_widget.dart](../widgets/migration_diagnostic_widget.dart) - Widget visuel (optionnel)

## 💡 Recommandations

1. **Ne pas supprimer** les données legacy immédiatement après migration
2. **Tester** l'application avec les données migrées pendant quelques jours
3. **Créer un backup** avant de nettoyer les données legacy
4. **Utiliser le widget de diagnostic** en développement pour surveiller la migration
5. **Consulter les logs** en cas de problème
