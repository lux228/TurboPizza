import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/order_service.dart';
import '../services/backup_service.dart';
import '../services/theme_service.dart';
import '../utils/snack_bar_utils.dart';
import '../widgets/migration_diagnostic_widget.dart';
import '../widgets/duplicate_diagnostic_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  Future<Directory> _defaultDir() async {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
    return getApplicationSupportDirectory();
  }

  Future<void> _exportDb() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final dir = await _defaultDir();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final dest = p.join(dir.path, 'turbopizza-backup-$ts.db');
      await BackupService.instance.exportDatabase(dest);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Base exportée vers $dest',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Export échoué: $e',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importDb() async {
    if (_busy) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() => _busy = true);
    try {
      final path = result.files.single.path!;
      await BackupService.instance.importDatabase(path);
      if (!mounted) return;
      // Reload orders from new database
      await context.read<OrderService>().loadOrders();
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Import réussi et données rechargées.',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Import échoué: $e',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_busy) return;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (range == null) return;

    setState(() => _busy = true);
    try {
      final dir = await _defaultDir();
      final startLabel = DateFormat('yyyyMMdd').format(range.start);
      final endLabel = DateFormat('yyyyMMdd').format(range.end);
      final dest = p.join(dir.path, 'turbopizza-encaissements-$startLabel-$endLabel.csv');

      await BackupService.instance.exportPaymentsCsv(
        start: range.start,
        endExclusive: range.end.add(const Duration(days: 1)),
        destinationPath: dest,
      );

      if (!mounted) return;
      showAppSnackBar(
        context,
        'CSV exporté vers $dest',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Export CSV échoué: $e',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarde & export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ThemeModeTile(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('Exporter la base SQLite'),
              onPressed: _busy ? null : _exportDb,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Importer une base SQLite (.db)'),
              onPressed: _busy ? null : _importDb,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.description),
              label: const Text('Exporter les encaissements en CSV'),
              onPressed: _busy ? null : _exportCsv,
            ),
            const SizedBox(height: 24),
            const MigrationDiagnosticWidget(),
            const SizedBox(height: 24),
            const DuplicateDiagnosticWidget(),
            const SizedBox(height: 24),
            const Text(
              'Exports enregistrés dans votre dossier Téléchargements (sinon dossier support de l\'app).',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return Card(
      child: ListTile(
        title: const Text('Thème'),
        subtitle: const Text('Choisir clair, sombre ou système'),
        trailing: DropdownButton<ThemeMode>(
          value: themeService.themeMode,
          onChanged: (mode) {
            if (mode != null) {
              themeService.setThemeMode(mode);
            }
          },
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('Système'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Clair'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Sombre'),
            ),
          ],
        ),
      ),
    );
  }
}
