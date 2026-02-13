import 'package:flutter/material.dart';
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
  State<MigrationDiagnosticWidget> createState() => _MigrationDiagnosticWidgetState();
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
        title: const Text('État de la migration'),
        subtitle: _diagnostic != null
            ? Text(_diagnostic!.isMigrationCompleted
                ? '✅ Migration complétée'
                : '⚠️ Migration en attente',
                style: textStyles.caption)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(),
          ),
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
            'Erreur: $_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadDiagnostic,
            child: const Text('Réessayer'),
          ),
        ],
      );
    }

    if (_diagnostic == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusSection(),
        const SizedBox(height: 16),
        _buildDataSection('Données legacy (SharedPreferences)', [
          'Produits: ${_diagnostic!.legacyDataCounts.products}',
          'Paiements: ${_diagnostic!.legacyDataCounts.payments}',
          'Commandes: ${_diagnostic!.legacyDataCounts.pendingOrders}',
        ]),
        const SizedBox(height: 16),
        _buildDataSection('Données actuelles (SQLite)', [
          'Produits: ${_diagnostic!.currentDataCounts.products}',
          'Paiements: ${_diagnostic!.currentDataCounts.payments}',
          'Commandes: ${_diagnostic!.currentDataCounts.pendingOrders}',
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
                    ? 'Migration complétée'
                    : 'Migration non effectuée',
                style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (stats != null) ...[
            const SizedBox(height: 8),
            Text('Date: ${stats.migrationDate.toLocal()}',
                style: textStyles.caption),
            Text('${stats.productsCount} produits, ${stats.paymentsCount} paiements, '
                '${stats.pendingOrdersCount} commandes migrées',
                style: textStyles.caption),
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
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text('• $item', style: textStyles.body),
            )),
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
            label: const Text('Forcer la migration'),
            onPressed: _forceMigration,
          ),
        const SizedBox(height: 8),
        if (_diagnostic!.hasLegacyData && _diagnostic!.isMigrationCompleted)
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Nettoyer les données legacy'),
            onPressed: _clearLegacyData,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          onPressed: _loadDiagnostic,
        ),
      ],
    );
  }

  Future<void> _forceMigration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forcer la migration'),
        content: const Text(
            'Cette action va migrer les données de SharedPreferences vers SQLite. '
            'Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrer'),
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
              ? 'Migration réussie: ${stats.productsCount} produits, '
                  '${stats.paymentsCount} paiements'
              : 'Migration ignorée (déjà effectuée)',
          type: AppSnackBarType.success,
        );
        await _loadDiagnostic();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Erreur: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  Future<void> _clearLegacyData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer les données legacy'),
        content: const Text(
            'Cette action va supprimer définitivement les données stockées dans '
            'SharedPreferences. Assurez-vous que la migration est complète.\n\n'
            'Cette action est irréversible !'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
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
          'Données legacy supprimées',
          type: AppSnackBarType.success,
        );
        await _loadDiagnostic();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Erreur: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }
}
