import 'dart:io';
import '../services/database_service.dart';

/// Service for managing database backups and exports.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Exports the database to the specified path.
  Future<void> exportDatabase(String destinationPath) {
    return DatabaseService.instance.exportDatabase(destinationPath);
  }

  /// Imports a database from the specified path.
  /// 
  /// An automatic backup of the current database is created before import.
  /// Returns the path to the backup file created.
  Future<String> importDatabase(String sourcePath, {bool createBackup = true}) {
    return DatabaseService.instance.importDatabase(sourcePath, createBackup: createBackup);
  }

  /// Restores the database from a backup file.
  Future<void> restoreFromBackup(String backupPath) {
    return DatabaseService.instance.restoreFromBackup(backupPath);
  }

  /// Exports payments within a date range to a CSV file.
  Future<File> exportPaymentsCsv({
    required DateTime start,
    required DateTime endExclusive,
    required String destinationPath,
  }) async {
    await DatabaseService.instance.init();
    final payments = await DatabaseService.instance.fetchPaymentsBetween(
      start: start,
      endExclusive: endExclusive,
    );

    final buffer = StringBuffer();
    buffer.writeln('date;amount;payment_method;items');
    for (final p in payments) {
      final itemsText = p.items
          .map((i) => '${i.quantity}x ${i.name} (${i.type}) @${i.price}')
          .join(' | ');
      final dateIso = p.date.toIso8601String();
      buffer.writeln('$dateIso;${p.amount.toStringAsFixed(2)};${p.paymentMethod};$itemsText');
    }

    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(buffer.toString());
    return file;
  }
}
