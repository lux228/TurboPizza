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
import '../services/category_filter_service.dart';
import '../utils/snack_bar_utils.dart';
import '../constants/app_strings.dart';
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
        '${AppStrings.dbExportSuccessPrefix} $dest',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        '${AppStrings.exportFailedPrefix} $e',
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
        AppStrings.importSuccessMessage,
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        '${AppStrings.importFailedPrefix} $e',
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
      final dest = p.join(
        dir.path,
        'turbopizza-encaissements-$startLabel-$endLabel.csv',
      );

      await BackupService.instance.exportPaymentsCsv(
        start: range.start,
        endExclusive: range.end.add(const Duration(days: 1)),
        destinationPath: dest,
      );

      if (!mounted) return;
      showAppSnackBar(
        context,
        '${AppStrings.csvExportSuccessPrefix} $dest',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        '${AppStrings.exportFailedPrefix} $e',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ThemeModeTile(),
            const SizedBox(height: 12),
            const CategoryButtonsSettingsCard(),
            const SizedBox(height: 12),
            const OrderThresholdsSettingsCard(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text(AppStrings.exportDbButtonLabel),
              onPressed: _busy ? null : _exportDb,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text(AppStrings.importDbButtonLabel),
              onPressed: _busy ? null : _importDb,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.description),
              label: const Text(AppStrings.exportCsvButtonLabel),
              onPressed: _busy ? null : _exportCsv,
            ),
            const SizedBox(height: 24),
            const MigrationDiagnosticWidget(),
            const SizedBox(height: 24),
            const DuplicateDiagnosticWidget(),
            const SizedBox(height: 24),
            const Text(
              AppStrings.exportSavedLocationMessage,
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
        title: const Text(AppStrings.themeLabel),
        subtitle: const Text(AppStrings.themeDescription),
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
              child: Text(AppStrings.themeSystemLabel),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(AppStrings.themeLightLabel),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(AppStrings.themeDarkLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryButtonsSettingsCard extends StatelessWidget {
  const CategoryButtonsSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final filterService = context.watch<CategoryFilterService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(AppStrings.categoryButtonsSettingsTitle),
              subtitle: Text(
                filterService.showTopCategoryButtons
                    ? AppStrings.categoryButtonsVisibleDescription
                    : AppStrings.categoryButtonsHiddenDescription,
              ),
              trailing: Switch(
                value: filterService.showTopCategoryButtons,
                onChanged: (value) {
                  filterService.setShowTopCategoryButtons(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderThresholdsSettingsCard extends StatefulWidget {
  const OrderThresholdsSettingsCard({super.key});

  @override
  State<OrderThresholdsSettingsCard> createState() =>
      _OrderThresholdsSettingsCardState();
}

class _OrderThresholdsSettingsCardState extends State<OrderThresholdsSettingsCard> {
  late final TextEditingController _lateController;
  late final TextEditingController _slightlyLateController;
  late final TextEditingController _onTimeController;
  late final TextEditingController _comingSoonController;
  bool _initializedFromService = false;
  bool _isDirty = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _lateController = TextEditingController();
    _slightlyLateController = TextEditingController();
    _onTimeController = TextEditingController();
    _comingSoonController = TextEditingController();

    _lateController.addListener(_markDirty);
    _slightlyLateController.addListener(_markDirty);
    _onTimeController.addListener(_markDirty);
    _comingSoonController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _lateController.dispose();
    _slightlyLateController.dispose();
    _onTimeController.dispose();
    _comingSoonController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_isSyncing) return;
    if (_isDirty) return;
    setState(() => _isDirty = true);
  }

  void _syncFromService(OrderService service) {
    _isSyncing = true;
    _lateController.text = service.lateMinutes.toString();
    _slightlyLateController.text = service.slightlyLateMinutes.toString();
    _onTimeController.text = service.onTimeMinutes.toString();
    _comingSoonController.text = service.comingSoonMinutes.toString();
    _isSyncing = false;
    _initializedFromService = true;
    _isDirty = false;
  }

  Future<void> _saveThresholds() async {
    final late = int.tryParse(_lateController.text.trim());
    final slightlyLate = int.tryParse(_slightlyLateController.text.trim());
    final onTime = int.tryParse(_onTimeController.text.trim());
    final comingSoon = int.tryParse(_comingSoonController.text.trim());

    if (late == null ||
        slightlyLate == null ||
        onTime == null ||
        comingSoon == null) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        AppStrings.thresholdsInvalidNumberMessage,
        type: AppSnackBarType.warning,
      );
      return;
    }

    final orderService = context.read<OrderService>();
    final saved = await orderService.setStatusThresholds(
      lateMinutes: late,
      slightlyLateMinutes: slightlyLate,
      onTimeMinutes: onTime,
      comingSoonMinutes: comingSoon,
    );

    if (!mounted) return;
    if (!saved) {
      showAppSnackBar(
        context,
        AppStrings.thresholdsInvalidMessage,
        type: AppSnackBarType.warning,
      );
      return;
    }

    setState(() => _isDirty = false);
    showAppSnackBar(
      context,
      AppStrings.thresholdsSavedMessage,
      type: AppSnackBarType.success,
    );
  }

  Future<void> _resetThresholds() async {
    final orderService = context.read<OrderService>();
    await orderService.resetStatusThresholdsToDefaults();
    if (!mounted) return;

    setState(() {
      _syncFromService(orderService);
    });

    showAppSnackBar(
      context,
      AppStrings.thresholdsResetMessage,
      type: AppSnackBarType.success,
    );
  }

  Widget _buildThresholdField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'min',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();

    if (orderService.thresholdsLoaded && !_initializedFromService && !_isDirty) {
      _syncFromService(orderService);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(AppStrings.orderThresholdsSettingsTitle),
              subtitle: Text(AppStrings.orderThresholdsSettingsDescription),
            ),
            _buildThresholdField(
              label: AppStrings.thresholdLateLabel,
              controller: _lateController,
            ),
            const SizedBox(height: 8),
            _buildThresholdField(
              label: AppStrings.thresholdSlightlyLateLabel,
              controller: _slightlyLateController,
            ),
            const SizedBox(height: 8),
            _buildThresholdField(
              label: AppStrings.thresholdOnTimeLabel,
              controller: _onTimeController,
            ),
            const SizedBox(height: 8),
            _buildThresholdField(
              label: AppStrings.thresholdComingSoonLabel,
              controller: _comingSoonController,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveThresholds,
                      icon: const Icon(Icons.save),
                      label: const Text(AppStrings.saveThresholdsButtonLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetThresholds,
                      icon: const Icon(Icons.refresh),
                      label: const Text(AppStrings.resetThresholdsButtonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
