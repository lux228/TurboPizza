import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../repositories/payment_repository.dart';
import '../utils/snack_bar_utils.dart';

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
  List<Map<String, dynamic>>? _topByQuantity;
  List<Map<String, dynamic>>? _topByRevenue;
  Map<String, double>? _totalsByMethod;
  Map<String, Map<String, num>>? _totalsByType;
  double? _totalRevenue;

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
    if (_selectedPeriod == 'custom' && _customStart != null && _customEnd != null) {
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

      final results = await Future.wait([
        _paymentRepo.fetchDailyRevenue(start: start, endExclusive: end),
        _paymentRepo.fetchTopProductsByQuantity(start: start, endExclusive: end, limit: 5),
        _paymentRepo.fetchTopProductsByRevenue(start: start, endExclusive: end, limit: 5),
        _paymentRepo.fetchTotalsByMethodBetween(start: start, endExclusive: end),
        _paymentRepo.fetchTotalsByType(start: start, endExclusive: end),
        _paymentRepo.fetchTotalAmountBetween(start: start, endExclusive: end),
      ]);

      setState(() {
        _dailyRevenue = results[0] as List<Map<String, dynamic>>;
        _topByQuantity = results[1] as List<Map<String, dynamic>>;
        _topByRevenue = results[2] as List<Map<String, dynamic>>;
        _totalsByMethod = results[3] as Map<String, double>;
        _totalsByType = results[4] as Map<String, Map<String, num>>;
        _totalRevenue = results[5] as double;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showAppSnackBar(
          context,
          'Erreur lors du chargement : $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques de vente'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStatisticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Row(
        children: [
          const Text('Période : ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _buildPeriodChip('7 jours', '7days'),
                _buildPeriodChip('30 jours', '30days'),
                _buildPeriodChip('90 jours', '90days'),
                _buildPeriodChip('1 an', '1year'),
                _buildPeriodChip('Personnalisé', 'custom'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
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
        _customEnd = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day + 1);
      });
      await _loadStatistics();
    }
  }

  Widget _buildStatisticsContent() {
    if (_dailyRevenue == null || _dailyRevenue!.isEmpty) {
      return const Center(
        child: Text('Aucune donnée pour cette période'),
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
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Chiffre d\'affaires total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(_totalRevenue ?? 0),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
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

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution du chiffre d\'affaires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _dailyRevenue!.length > 10
                            ? (_dailyRevenue!.length / 5).ceilToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _dailyRevenue!.length) {
                            final date = DateTime.parse(_dailyRevenue![index]['date'] as String);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailyRevenue!.asMap().entries.map((entry) {
                        final total = (entry.value['total'] as num).toDouble();
                        return FlSpot(entry.key.toDouble(), total);
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
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
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 des produits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildTopByQuantity() {
    if (_topByQuantity == null || _topByQuantity!.isEmpty) {
      return const Text('Aucune donnée');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Par quantité', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name)),
                Text(
                  '×$quantity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
      return const Text('Aucune donnée');
    }

    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Par chiffre d\'affaires', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name)),
                Text(
                  formatter.format(revenue),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    final total = _totalsByMethod!.values.fold(0.0, (sum, val) => sum + val);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par méthode de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._totalsByMethod!.entries.map((entry) {
              final method = entry.key;
              final amount = entry.value;
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
                      style: const TextStyle(color: Colors.grey),
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

    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    final totalRevenue = _totalsByType!.values.fold(0.0, (sum, val) => sum + (val['revenue'] as num).toDouble());

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par type de pizza',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._totalsByType!.entries.map((entry) {
              final type = entry.key;
              final quantity = (entry.value['quantity'] as num).toInt();
              final revenue = (entry.value['revenue'] as num).toDouble();
              final percent = totalRevenue > 0 ? (revenue / totalRevenue * 100) : 0.0;
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
                      style: const TextStyle(color: Colors.grey),
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
