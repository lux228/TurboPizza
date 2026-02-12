import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/database_service.dart';
import '../services/migration_service.dart';

/// Utility for diagnosing and managing data migration.
class MigrationUtility {
  /// Checks if legacy data exists in SharedPreferences.
  static Future<bool> hasLegacyData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final hasPizzas = prefs.containsKey(AppConstants.spKeyPizzas);
    final hasPayments = prefs.containsKey(AppConstants.spKeyPayments);
    final hasPendingOrders = prefs.containsKey(AppConstants.spKeyPendingOrders);
    
    return hasPizzas || hasPayments || hasPendingOrders;
  }

  /// Returns diagnostic information about the migration status.
  static Future<MigrationDiagnostic> diagnose() async {
    await DatabaseService.instance.init();
    final prefs = await SharedPreferences.getInstance();
    
    final migrationService = MigrationService(DatabaseService.instance.database);
    final isCompleted = await migrationService.isMigrationCompleted();
    final stats = await migrationService.getMigrationStats();
    
    final legacyPizzasCount = prefs.getStringList(AppConstants.spKeyPizzas)?.length ?? 0;
    final legacyPaymentsCount = prefs.getStringList(AppConstants.spKeyPayments)?.length ?? 0;
    final legacyPendingCount = prefs.getStringList(AppConstants.spKeyPendingOrders)?.length ?? 0;
    
    final dbProducts = await DatabaseService.instance.products.fetchProducts(includeInactive: true);
    final dbPayments = await DatabaseService.instance.payments.fetchPayments();
    final dbPendingOrders = await DatabaseService.instance.pendingOrders.fetchPendingOrders();
    
    return MigrationDiagnostic(
      isMigrationCompleted: isCompleted,
      migrationStats: stats,
      hasLegacyData: await hasLegacyData(),
      legacyDataCounts: LegacyDataCounts(
        products: legacyPizzasCount,
        payments: legacyPaymentsCount,
        pendingOrders: legacyPendingCount,
      ),
      currentDataCounts: CurrentDataCounts(
        products: dbProducts.length,
        payments: dbPayments.length,
        pendingOrders: dbPendingOrders.length,
      ),
    );
  }

  /// Forces a migration from SharedPreferences to SQLite.
  /// 
  /// This intelligently merges legacy data with existing SQLite data:
  /// - Products are updated/inserted based on name
  /// - Duplicate payments are detected and skipped
  /// - Pending orders are merged by ID
  /// 
  /// Safe to call multiple times - won't create duplicates.
  static Future<MigrationStats?> forceMigration() async {
    await DatabaseService.instance.init(skipMigration: true);
    final migrationService = MigrationService(DatabaseService.instance.database);
    
    // Clear the migration marker to allow re-migration
    await DatabaseService.instance.database.delete(
      'meta',
      where: 'key = ?',
      whereArgs: ['migrated_from_prefs'],
    );
    
    return await migrationService.migrateFromPrefsIfNeeded();
  }

  /// Clears legacy data from SharedPreferences.
  /// 
  /// This should only be called AFTER successful migration.
  /// Use with caution - this action cannot be undone.
  static Future<void> clearLegacyData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.spKeyPizzas);
    await prefs.remove(AppConstants.spKeyPayments);
    await prefs.remove(AppConstants.spKeyPendingOrders);
  }

  /// Exports legacy data from SharedPreferences to a JSON string.
  /// 
  /// This can be used to backup legacy data before clearing it.
  static Future<String> exportLegacyDataAsJson() async {
    final prefs = await SharedPreferences.getInstance();
    
    final data = {
      'pizzas': prefs.getStringList(AppConstants.spKeyPizzas) ?? [],
      'payments': prefs.getStringList(AppConstants.spKeyPayments) ?? [],
      'pending_orders': prefs.getStringList(AppConstants.spKeyPendingOrders) ?? [],
      'export_date': DateTime.now().toIso8601String(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

/// Diagnostic information about migration status.
class MigrationDiagnostic {
  final bool isMigrationCompleted;
  final MigrationStats? migrationStats;
  final bool hasLegacyData;
  final LegacyDataCounts legacyDataCounts;
  final CurrentDataCounts currentDataCounts;

  MigrationDiagnostic({
    required this.isMigrationCompleted,
    required this.migrationStats,
    required this.hasLegacyData,
    required this.legacyDataCounts,
    required this.currentDataCounts,
  });

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('=== État de la migration ===');
    buffer.writeln('Migration complétée: ${isMigrationCompleted ? "✅ Oui" : "❌ Non"}');
    
    if (migrationStats != null) {
      buffer.writeln('\nStatistiques de migration:');
      buffer.writeln('  - ${migrationStats!.productsCount} produits');
      buffer.writeln('  - ${migrationStats!.paymentsCount} paiements');
      buffer.writeln('  - ${migrationStats!.pendingOrdersCount} commandes');
      buffer.writeln('  - Date: ${migrationStats!.migrationDate}');
    }
    
    buffer.writeln('\nDonnées dans SharedPreferences:');
    buffer.writeln('  - ${legacyDataCounts.products} produits');
    buffer.writeln('  - ${legacyDataCounts.payments} paiements');
    buffer.writeln('  - ${legacyDataCounts.pendingOrders} commandes');
    buffer.writeln('  - Présence: ${hasLegacyData ? "Oui" : "Non"}');
    
    buffer.writeln('\nDonnées dans SQLite:');
    buffer.writeln('  - ${currentDataCounts.products} produits');
    buffer.writeln('  - ${currentDataCounts.payments} paiements');
    buffer.writeln('  - ${currentDataCounts.pendingOrders} commandes');
    
    if (hasLegacyData && !isMigrationCompleted) {
      buffer.writeln('\n⚠️  ATTENTION: Des données legacy existent mais la migration n\'est pas marquée comme complétée.');
      buffer.writeln('   → Utilisez MigrationUtility.forceMigration() pour migrer.');
    } else if (!hasLegacyData && !isMigrationCompleted) {
      buffer.writeln('\nℹ️  Pas de données legacy trouvées. Migration non nécessaire.');
    } else if (hasLegacyData && isMigrationCompleted) {
      buffer.writeln('\n✅ Migration complétée. Les données legacy peuvent être supprimées.');
      buffer.writeln('   → Utilisez MigrationUtility.clearLegacyData() pour nettoyer.');
    }
    
    return buffer.toString();
  }
}

class LegacyDataCounts {
  final int products;
  final int payments;
  final int pendingOrders;

  LegacyDataCounts({
    required this.products,
    required this.payments,
    required this.pendingOrders,
  });
}

class CurrentDataCounts {
  final int products;
  final int payments;
  final int pendingOrders;

  CurrentDataCounts({
    required this.products,
    required this.payments,
    required this.pendingOrders,
  });
}
