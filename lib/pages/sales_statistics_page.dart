import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../repositories/payment_repository.dart';
import '../utils/snack_bar_utils.dart';
import '../constants/app_payments.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

/// Page displaying sales statistics with charts and analytics.
class SalesStatisticsPage extends StatefulWidget {
  const SalesStatisticsPage({super.key});

  @override
  State<SalesStatisticsPage> createState() => _SalesStatisticsPageState();
}

class _SalesStatisticsPageState extends State<SalesStatisticsPage> {
  final _dbService = DatabaseService.instance;
  late PaymentRepository _paymentRepo;

  String _selectedPeriod = '30days';
  DateTime? _customStart;
  DateTime? _customEnd;

  List<Map<String, dynamic>>? _dailyRevenue;
  List<Map<String, dynamic>>? _dailyRevenuePrev;
  List<Map<String, dynamic>>? _topByQuantity;
  List<Map<String, dynamic>>? _topByRevenue;
  Map<String, double>? _totalsByMethod;
  Map<String, Map<String, num>>? _totalsByType;
  double? _totalRevenue;

  DateTime? _currentStart;
  DateTime? _currentEndExclusive;
  DateTime? _previousStart;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    final db = _dbService.database;
    _paymentRepo = PaymentRepository(db);
    await _loadStatistics();
  }

  /// Returns the start and end dates based on the selected period.
  (DateTime, DateTime) _getDateRange() {
    if (_selectedPeriod == 'custom' &&
        _customStart != null &&
        _customEnd != null) {
      return (_customStart!, _customEnd!);
    }

    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day + 1); // Start of tomorrow

    switch (_selectedPeriod) {
      case '7days':
        return (end.subtract(const Duration(days: 7)), end);
      case '30days':
        return (end.subtract(const Duration(days: 30)), end);
      case '90days':
        return (end.subtract(const Duration(days: 90)), end);
      case '1year':
        return (DateTime(now.year - 1, now.month, now.day), end);
      default:
        return (end.subtract(const Duration(days: 30)), end);
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final (start, end) = _getDateRange();
      final rangeDuration = end.difference(start);
      final previousStart = DateTime(start.year - 1, start.month, start.day);
      final previousEnd = previousStart.add(rangeDuration);

      final results = await Future.wait([
        _paymentRepo.fetchDailyRevenue(start: start, endExclusive: end),
        _paymentRepo.fetchDailyRevenue(
          start: previousStart,
          endExclusive: previousEnd,
        ),
        _paymentRepo.fetchTopProductsByQuantity(
          start: start,
          endExclusive: end,
          limit: 5,
        ),
        _paymentRepo.fetchTopProductsByRevenue(
          start: start,
          endExclusive: end,
          limit: 5,
        ),
        _paymentRepo.fetchTotalsByMethodBetween(
          start: start,
          endExclusive: end,
        ),
        _paymentRepo.fetchTotalsByType(start: start, endExclusive: end),
        _paymentRepo.fetchTotalAmountBetween(start: start, endExclusive: end),
      ]);

      setState(() {
        _dailyRevenue = results[0] as List<Map<String, dynamic>>;
        _dailyRevenuePrev = results[1] as List<Map<String, dynamic>>;
        _topByQuantity = results[2] as List<Map<String, dynamic>>;
        _topByRevenue = results[3] as List<Map<String, dynamic>>;
        _totalsByMethod = results[4] as Map<String, double>;
        _totalsByType = results[5] as Map<String, Map<String, num>>;
        _totalRevenue = results[6] as double;
        _currentStart = start;
        _currentEndExclusive = end;
        _previousStart = previousStart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showAppSnackBar(
          context,
          '${AppStrings.salesLoadErrorPrefix} $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.salesStatisticsTitle),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          _buildPeriodSelector(colorScheme, textStyles),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStatisticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(
    ColorScheme colorScheme,
    AppTextStyles textStyles,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text(
            AppStrings.periodLabel,
            style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _buildPeriodChip(AppStrings.period7DaysLabel, '7days'),
                _buildPeriodChip(AppStrings.period30DaysLabel, '30days'),
                _buildPeriodChip(AppStrings.period90DaysLabel, '90days'),
                _buildPeriodChip(AppStrings.period1YearLabel, '1year'),
                _buildPeriodChip(AppStrings.customPeriodLabel, 'custom'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    final colorScheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    return ChoiceChip(
      label: Text(label),
      labelStyle: textStyles.caption.copyWith(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.outline),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected) {
          if (value == 'custom') {
            await _selectCustomPeriod();
          } else {
            setState(() => _selectedPeriod = value);
            await _loadStatistics();
          }
        }
      },
    );
  }

  Future<void> _selectCustomPeriod() async {
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );

    if (dateRange != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customStart = dateRange.start;
        _customEnd = DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day + 1,
        );
      });
      await _loadStatistics();
    }
  }

  Widget _buildStatisticsContent() {
    if (_dailyRevenue == null || _dailyRevenue!.isEmpty) {
      final textStyles = context.appTextStyles;
      return Center(
        child: Text(AppStrings.noDataForPeriodMessage, style: textStyles.body),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalRevenueCard(),
          const SizedBox(height: 16),
          _buildDailyRevenueChart(),
          const SizedBox(height: 16),
          _buildTopProductsSection(),
          const SizedBox(height: 16),
          _buildPaymentMethodsSection(),
          const SizedBox(height: 16),
          _buildPizzaTypesSection(),
        ],
      ),
    );
  }

  Widget _buildTotalRevenueCard() {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final textStyles = context.appTextStyles;
    final colors = context.appColors;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              AppStrings.totalRevenueLabel,
              style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(_totalRevenue ?? 0),
              style: textStyles.header.copyWith(color: colors.successGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRevenueChart() {
    if (_dailyRevenue == null || _dailyRevenue!.isEmpty) {
      return const SizedBox.shrink();
    }

    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;
    final currentColor = context.appColors.warningOrange;
    final previousColor = colorScheme.onSurface.withValues(alpha: 0.6);

    final start = _currentStart;
    final endExclusive = _currentEndExclusive;
    final prevStart = _previousStart;
    if (start == null || endExclusive == null || prevStart == null) {
      return const SizedBox.shrink();
    }

    final days = _buildDayList(start, endExclusive);
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentTotals = _buildDailyTotalsMap(_dailyRevenue!);
    final previousTotals = _dailyRevenuePrev == null
        ? <String, double>{}
        : _buildDailyTotalsMap(_dailyRevenuePrev!);
    final prevDays = _buildDayList(
      prevStart,
      prevStart.add(endExclusive.difference(start)),
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.revenueTrendLabel,
              style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegendDot(currentColor),
                const SizedBox(width: 6),
                Text(AppStrings.currentYearLabel, style: textStyles.caption),
                const SizedBox(width: 16),
                _buildLegendDot(previousColor),
                const SizedBox(width: 6),
                Text(AppStrings.previousYearLabel, style: textStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}€',
                            style: textStyles.caption.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: days.length > 10
                            ? (days.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            final date = days[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: textStyles.caption.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: days.asMap().entries.map((entry) {
                        final key = _dateKey(entry.value);
                        final total = currentTotals[key] ?? 0.0;
                        return FlSpot(entry.key.toDouble(), total);
                      }).toList(),
                      isCurved: true,
                      color: currentColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: currentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    LineChartBarData(
                      spots: prevDays.asMap().entries.map((entry) {
                        final key = _dateKey(entry.value);
                        final total = previousTotals[key] ?? 0.0;
                        return FlSpot(entry.key.toDouble(), total);
                      }).toList(),
                      isCurved: true,
                      color: previousColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [6, 4],
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection() {
    final textStyles = context.appTextStyles;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.topProductsLabel,
              style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopByQuantity()),
                const SizedBox(width: 16),
                Expanded(child: _buildTopByRevenue()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _buildDayList(DateTime start, DateTime endExclusive) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    final days = endDate.difference(startDate).inDays;
    if (days <= 0) return [];
    return List.generate(days, (index) => startDate.add(Duration(days: index)));
  }

  Map<String, double> _buildDailyTotalsMap(List<Map<String, dynamic>> source) {
    final map = <String, double>{};
    for (final row in source) {
      final rawDate = row['date'] as String;
      final date = DateTime.parse(rawDate);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      map[_dateKey(date)] = total;
    }
    return map;
  }

  String _dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTopByQuantity() {
    if (_topByQuantity == null || _topByQuantity!.isEmpty) {
      return Text(AppStrings.noDataMessage, style: context.appTextStyles.body);
    }

    final textStyles = context.appTextStyles;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.byQuantityLabel,
          style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._topByQuantity!.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final product = entry.value;
          final name = product['name'] as String;
          final quantity = (product['total_quantity'] as num).toInt();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '$index.',
                  style: textStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.warningOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name)),
                Text(
                  '×$quantity',
                  style: textStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopByRevenue() {
    if (_topByRevenue == null || _topByRevenue!.isEmpty) {
      return Text(AppStrings.noDataMessage, style: context.appTextStyles.body);
    }

    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );
    final textStyles = context.appTextStyles;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.byRevenueLabel,
          style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._topByRevenue!.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final product = entry.value;
          final name = product['name'] as String;
          final revenue = (product['total_revenue'] as num).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '$index.',
                  style: textStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.warningOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name)),
                Text(
                  formatter.format(revenue),
                  style: textStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    if (_totalsByMethod == null || _totalsByMethod!.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final totals = _totalsByMethod ?? <String, double>{};
    final total = totals.values.fold(0.0, (sum, val) => sum + val);
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.paymentMethodDistributionLabel,
              style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...AppPayments.methods.map((method) {
              final amount = totals[method] ?? 0.0;
              final percent = total > 0 ? (amount / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(method)),
                    Text(formatter.format(amount)),
                    const SizedBox(width: 8),
                    Text(
                      '(${percent.toStringAsFixed(1)}%)',
                      style: textStyles.caption.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPizzaTypesSection() {
    if (_totalsByType == null || _totalsByType!.isEmpty) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final totalRevenue = _totalsByType!.values.fold(
      0.0,
      (sum, val) => sum + (val['revenue'] as num).toDouble(),
    );
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.pizzaTypeDistributionLabel,
              style: textStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._totalsByType!.entries.map((entry) {
              final type = entry.key;
              final quantity = (entry.value['quantity'] as num).toInt();
              final revenue = (entry.value['revenue'] as num).toDouble();
              final percent = totalRevenue > 0
                  ? (revenue / totalRevenue * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(type)),
                    Text('×$quantity'),
                    const SizedBox(width: 16),
                    Text(formatter.format(revenue)),
                    const SizedBox(width: 8),
                    Text(
                      '(${percent.toStringAsFixed(1)}%)',
                      style: textStyles.caption.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
