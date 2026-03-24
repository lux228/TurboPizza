import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_strings.dart';
import '../utils/duplicate_diagnostic.dart';
import '../theme/app_theme.dart';

class DuplicateDiagnosticWidget extends StatefulWidget {
  const DuplicateDiagnosticWidget({super.key});

  @override
  State<DuplicateDiagnosticWidget> createState() =>
      _DuplicateDiagnosticWidgetState();
}

class _DuplicateDiagnosticWidgetState extends State<DuplicateDiagnosticWidget> {
  late Future<DuplicateDiagnostics> _future;

  @override
  void initState() {
    super.initState();
    _future = DuplicateDiagnosticService.load();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.copy_all_outlined),
        title: const Text(AppStrings.diagnosticDuplicatesTitle),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<DuplicateDiagnostics>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(
                    '${AppStrings.errorPrefix} ${snapshot.error}',
                    style: textStyles.body,
                  );
                }
                final data = snapshot.data;
                if (data == null) {
                  return Text(
                    AppStrings.noInfoAvailableMessage,
                    style: textStyles.body,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLine(
                      AppStrings.duplicateSkippedLabel,
                      data.migrationSkippedCount,
                      data.migrationSkippedAt,
                    ),
                    const SizedBox(height: 12),
                    _buildLine(
                      AppStrings.duplicateRemovedLabel,
                      data.dbDedupedCount,
                      data.dbDedupedAt,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(String label, int? count, DateTime? date) {
    final textStyles = context.appTextStyles;
    final countText = (count == null) ? '0' : count.toString();
    final dateText = (date == null)
        ? AppStrings.notAvailableLabel
        : DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: textStyles.body)),
        const SizedBox(width: 12),
        Text('$countText  ·  $dateText', style: textStyles.caption),
      ],
    );
  }
}
