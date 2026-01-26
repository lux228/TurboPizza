import 'dart:io';
import '../services/database_service.dart';
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  Future<void> exportDatabase(String destinationPath) {
    return DatabaseService.instance.exportDatabase(destinationPath);
  }

  Future<void> importDatabase(String sourcePath) {
    return DatabaseService.instance.importDatabase(sourcePath);
  }

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
