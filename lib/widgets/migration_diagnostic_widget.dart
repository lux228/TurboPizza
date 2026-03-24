import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../utils/migration_utility.dart';
import '../utils/snack_bar_utils.dart';
import '../theme/app_theme.dart';

/// Debug widget to display migration diagnostic information.
///
/// This widget can be added to the settings page or debug menu
/// to help users and developers understand the migration status.
class MigrationDiagnosticWidget extends StatefulWidget {
  const MigrationDiagnosticWidget({super.key});

  @override
  State<MigrationDiagnosticWidget> createState() =>
      _MigrationDiagnosticWidgetState();
}

class _MigrationDiagnosticWidgetState extends State<MigrationDiagnosticWidget> {
  MigrationDiagnostic? _diagnostic;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiagnostic();
  }

  Future<void> _loadDiagnostic() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final diagnostic = await MigrationUtility.diagnose();
      setState(() {
        _diagnostic = diagnostic;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline),
        title: const Text(AppStrings.migrationStatusTitle),
        subtitle: _diagnostic != null
            ? Text(
                _diagnostic!.isMigrationCompleted
                    ? AppStrings.migrationCompletedEmojiLabel
                    : AppStrings.migrationPendingEmojiLabel,
                style: textStyles.caption,
              )
            : null,
        children: [
          Padding(padding: const EdgeInsets.all(16.0), child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Text(
            '${AppStrings.errorPrefix} $_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadDiagnostic,
            child: const Text(AppStrings.retryLabel),
          ),
        ],
      );
    }

    if (_diagnostic == null) {
      return const Text(AppStrings.noInfoAvailableMessage);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusSection(),
        const SizedBox(height: 16),
        _buildDataSection(AppStrings.legacyDataSectionTitle, [
          '${AppStrings.productsPrefix} ${_diagnostic!.legacyDataCounts.products}',
          '${AppStrings.paymentsPrefix} ${_diagnostic!.legacyDataCounts.payments}',
          '${AppStrings.ordersPrefix} ${_diagnostic!.legacyDataCounts.pendingOrders}',
        ]),
        const SizedBox(height: 16),
        _buildDataSection(AppStrings.currentDataSectionTitle, [
          '${AppStrings.productsPrefix} ${_diagnostic!.currentDataCounts.products}',
          '${AppStrings.paymentsPrefix} ${_diagnostic!.currentDataCounts.payments}',
          '${AppStrings.ordersPrefix} ${_diagnostic!.currentDataCounts.pendingOrders}',
        ]),
        const SizedBox(height: 16),
        _buildActions(),
      ],
    );
  }

  Widget _buildStatusSection() {
    final stats = _diagnostic!.migrationStats;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _diagnostic!.isMigrationCompleted
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _diagnostic!.isMigrationCompleted
                    ? Icons.check_circle
                    : Icons.warning,
                color: _diagnostic!.isMigrationCompleted
                    ? colors.successGreen
                    : colors.warningOrange,
              ),
              const SizedBox(width: 8),
              Text(
                _diagnostic!.isMigrationCompleted
                    ? AppStrings.migrationCompletedLabel
                    : AppStrings.migrationNotCompletedLabel,
                style: textStyles.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (stats != null) ...[
            const SizedBox(height: 8),
            Text(
              '${AppStrings.datePrefix} ${stats.migrationDate.toLocal()}',
              style: textStyles.caption,
            ),
            Text(
              '${stats.productsCount} ${AppStrings.productsWord}, '
              '${stats.paymentsCount} ${AppStrings.paymentsWord}, '
              '${stats.pendingOrdersCount} ${AppStrings.migratedCountsSuffix}',
              style: textStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSection(String title, List<String> items) {
    final textStyles = context.appTextStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Text('• $item', style: textStyles.body),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_diagnostic!.hasLegacyData && !_diagnostic!.isMigrationCompleted)
          ElevatedButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text(AppStrings.forceMigrationLabel),
            onPressed: _forceMigration,
          ),
        const SizedBox(height: 8),
        if (_diagnostic!.hasLegacyData && _diagnostic!.isMigrationCompleted)
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text(AppStrings.cleanLegacyDataLabel),
            onPressed: _clearLegacyData,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text(AppStrings.refreshLabel),
          onPressed: _loadDiagnostic,
        ),
      ],
    );
  }

  Future<void> _forceMigration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.forceMigrationLabel),
        content: const Text(AppStrings.forceMigrationContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.migrateLabel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final stats = await MigrationUtility.forceMigration();
      if (mounted) {
        showAppSnackBar(
          context,
          stats != null
              ? '${AppStrings.forceMigrationSuccessPrefix} ${stats.productsCount} ${AppStrings.productsWord}, '
                    '${stats.paymentsCount} ${AppStrings.paymentsWord}'
              : AppStrings.forceMigrationSkippedMessage,
          type: AppSnackBarType.success,
        );
        await _loadDiagnostic();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          '${AppStrings.errorPrefix} $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  Future<void> _clearLegacyData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cleanLegacyDataLabel),
        content: const Text(AppStrings.cleanLegacyDataContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppStrings.deleteLabel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await MigrationUtility.clearLegacyData();
      if (mounted) {
        showAppSnackBar(
          context,
          AppStrings.legacyDataDeletedMessage,
          type: AppSnackBarType.success,
        );
        await _loadDiagnostic();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          '${AppStrings.errorPrefix} $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }
}
