import 'dart:convert';
import '../services/database_service.dart';

class DuplicateDiagnostics {
  final int? migrationSkippedCount;
  final DateTime? migrationSkippedAt;
  final int? dbDedupedCount;
  final DateTime? dbDedupedAt;

  const DuplicateDiagnostics({
    required this.migrationSkippedCount,
    required this.migrationSkippedAt,
    required this.dbDedupedCount,
    required this.dbDedupedAt,
  });
}

class DuplicateDiagnosticService {
  static const _migrationDuplicatesKey = 'migration_payment_duplicates';
  static const _dbDuplicatesKey = 'db_payment_duplicates_removed';

  static Future<DuplicateDiagnostics> load() async {
    await DatabaseService.instance.init();
    final db = DatabaseService.instance.database;

    final migrationRows = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: [_migrationDuplicatesKey],
      limit: 1,
    );

    final dbRows = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: [_dbDuplicatesKey],
      limit: 1,
    );

    int? migrationCount;
    DateTime? migrationDate;
    if (migrationRows.isNotEmpty) {
      final raw = migrationRows.first['value'] as String;
      final data = json.decode(raw) as Map<String, dynamic>;
      migrationCount = data['count'] as int?;
      final dateRaw = data['date'] as String?;
      if (dateRaw != null) {
        migrationDate = DateTime.tryParse(dateRaw);
      }
    }

    int? dbCount;
    DateTime? dbDate;
    if (dbRows.isNotEmpty) {
      final raw = dbRows.first['value'] as String;
      final data = json.decode(raw) as Map<String, dynamic>;
      dbCount = data['count'] as int?;
      final dateRaw = data['date'] as String?;
      if (dateRaw != null) {
        dbDate = DateTime.tryParse(dateRaw);
      }
    }

    return DuplicateDiagnostics(
      migrationSkippedCount: migrationCount,
      migrationSkippedAt: migrationDate,
      dbDedupedCount: dbCount,
      dbDedupedAt: dbDate,
    );
  }
}
