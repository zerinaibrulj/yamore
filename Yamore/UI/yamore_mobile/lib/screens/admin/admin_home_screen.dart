import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/statistics.dart';

class AdminHomeScreen extends StatefulWidget {
  final AuthService authService;

  const AdminHomeScreen({super.key, required this.authService});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  StatisticsDtoModel? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final currentYear = DateTime.now().year;
      final data = await _api.getAdminStatistics(year: currentYear);
      setState(() {
        _stats = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = '${e.statusCode}: ${e.body}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadStats, child: const Text('Retry')),
          ],
        ),
      );
    }
    final stats = _stats!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              FilledButton.icon(
                onPressed: () => _exportReport(stats),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export report'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildKpiRow(context, stats),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildRevenueChartCard(context, stats)),
                const SizedBox(width: 16),
                Expanded(child: _buildCityChartCard(context, stats)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _buildPopularYachtsCard(context, stats),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, StatisticsDtoModel stats) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        _buildKpiCard(
          icon: Icons.directions_boat,
          label: 'Active yachts',
          value: stats.yachtsCount.toString(),
          color: AppTheme.primaryBlue,
          textTheme: textTheme,
        ),
        const SizedBox(width: 12),
        _buildKpiCard(
          icon: Icons.people_outline,
          label: 'Active users',
          value: stats.activeUsersCount.toString(),
          color: Colors.deepPurple,
          textTheme: textTheme,
        ),
        const SizedBox(width: 12),
        _buildKpiCard(
          icon: Icons.shopping_bag_outlined,
          label: 'Bookings',
          value: stats.totalBookings.toString(),
          color: Colors.teal,
          textTheme: textTheme,
        ),
        const SizedBox(width: 12),
        _buildKpiCard(
          icon: Icons.euro_symbol,
          label: 'Revenue',
          value: '€${stats.totalRevenue.toStringAsFixed(0)}',
          color: Colors.orange,
          textTheme: textTheme,
        ),
        const SizedBox(width: 12),
        _buildKpiCard(
          icon: Icons.flag_outlined,
          label: 'Reported reviews',
          value: stats.reportedReviewsCount.toString(),
          color: Colors.redAccent,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required TextTheme textTheme,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChartCard(
      BuildContext context, StatisticsDtoModel stats) {
    final data = stats.revenueByMonth;
    if (data.isEmpty) {
      return _buildEmptyCard('Revenue by month', 'No data yet.');
    }

    final spots = <FlSpot>[];
    final labels = <int, String>{};
    for (var i = 0; i < data.length; i++) {
      final m = data[i];
      spots.add(FlSpot(i.toDouble(), m.revenue));
      labels[i] = '${m.month}/${m.year % 100}';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue by month',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (!labels.containsKey(index)) return const SizedBox.shrink();
                          return Text(
                            labels[index]!,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChartCard(BuildContext context, StatisticsDtoModel stats) {
    final data = stats.reservationsByCity;
    if (data.isEmpty) {
      return _buildEmptyCard('Reservations by city', 'No data yet.');
    }
    final top = data.take(8).toList();
    final maxCount = top.map((e) => e.reservationCount).fold<int>(0, (a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservations by city',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (var i = 0; i < top.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: top[i].reservationCount.toDouble(),
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                  maxY: (maxCount.toDouble() * 1.2).clamp(1, double.infinity),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= top.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              top[index].cityName,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularYachtsCard(
      BuildContext context, StatisticsDtoModel stats) {
    final data = stats.mostPopularYachts;
    if (data.isEmpty) {
      return _buildEmptyCard('Most popular yachts', 'No data yet.');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most popular yachts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final y = data[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          y.yachtName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Bookings: ${y.bookingCount}'),
                      const SizedBox(width: 12),
                      Text('€${y.totalRevenue.toStringAsFixed(0)}'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String title, String message) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport(StatisticsDtoModel stats) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();

        doc.addPage(
          pw.MultiPage(
            margin: const pw.EdgeInsets.all(24),
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Yamore – Admin report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Year ${DateTime.now().year}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Overview',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Bullet(
                  text:
                      'Active yachts: ${stats.yachtsCount}, active users: ${stats.activeUsersCount}.'),
              pw.Bullet(
                  text:
                      'Total bookings: ${stats.totalBookings}, total revenue: €${stats.totalRevenue.toStringAsFixed(0)}.'),
              pw.Bullet(
                  text:
                      'Reported reviews: ${stats.reportedReviewsCount}.'),
              pw.SizedBox(height: 16),
              pw.Text(
                'Revenue by month',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (stats.revenueByMonth.isEmpty)
                pw.Text('No data yet.')
              else
                pw.Table.fromTextArray(
                  headers: const ['Month', 'Revenue', 'Bookings'],
                  data: stats.revenueByMonth
                      .map((m) => [
                            '${m.month}/${m.year}',
                            '€${m.revenue.toStringAsFixed(0)}',
                            m.bookingCount.toString(),
                          ])
                      .toList(),
                ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Reservations by city',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (stats.reservationsByCity.isEmpty)
                pw.Text('No data yet.')
              else
                pw.Table.fromTextArray(
                  headers: const ['City', 'Reservations', 'Revenue'],
                  data: stats.reservationsByCity
                      .map((c) => [
                            c.cityName,
                            c.reservationCount.toString(),
                            '€${c.revenue.toStringAsFixed(0)}',
                          ])
                      .toList(),
                ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Most popular yachts',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (stats.mostPopularYachts.isEmpty)
                pw.Text('No data yet.')
              else
                pw.Table.fromTextArray(
                  headers: const ['Yacht', 'Bookings', 'Revenue'],
                  data: stats.mostPopularYachts
                      .map((y) => [
                            y.yachtName,
                            y.bookingCount.toString(),
                            '€${y.totalRevenue.toStringAsFixed(0)}',
                          ])
                      .toList(),
                ),
            ],
          ),
        );

        return doc.save();
      },
    );
  }
}

