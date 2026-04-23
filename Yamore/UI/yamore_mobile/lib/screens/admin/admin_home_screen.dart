import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/statistics.dart';
import '../../utils/euro_format.dart';
import '../../models/reservation.dart';

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
        _error = '${e.statusCode}: ${e.displayMessage}';
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: _exportReservationsBookingsReport,
                    icon: const Icon(Icons.event_note_outlined, size: 18),
                    label: const Text('Reservations & Bookings'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _exportAdminOverviewReport(stats),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Admin report'),
                  ),
                ],
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
          value: formatEuroDashboard(stats.totalRevenue),
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
                  color: color.withValues(alpha: 0.1),
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
    double maxRevenue = 0;
    for (var i = 0; i < data.length; i++) {
      final m = data[i];
      if (m.revenue > maxRevenue) maxRevenue = m.revenue;
      spots.add(FlSpot(i.toDouble(), m.revenue));
      labels[i] = '${m.month}/${m.year % 100}';
    }
    final maxY = (maxRevenue * 1.15).clamp(1.0, double.infinity);

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
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
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
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (!labels.containsKey(index)) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels[index]!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              formatEuroCompactAxis(value),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
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

  Widget _buildCityChartCard(BuildContext context, StatisticsDtoModel stats) {
    final data = stats.reservationsByCity;
    if (data.isEmpty) {
      return _buildEmptyCard('Reservations by city', 'No data yet.');
    }
    final top = data.take(8).toList();
    final maxCount = top.map((e) => e.reservationCount).fold<int>(0, (a, b) => a > b ? a : b);
    // Keep axis tick values “round” so we don't show awkward decimals
    // (e.g. 3.6) on the Y axis.
    final maxY = (maxCount.toDouble() + 1).clamp(1.0, double.infinity);

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
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                      ),
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
                separatorBuilder: (_, int index) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final y = data[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          y.yachtName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Fixed-width columns so the “Bookings:” values align nicely.
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Bookings: ${y.bookingCount}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: Text(
                          formatEuroDashboard(y.totalRevenue),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
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

  Future<void> _exportAdminOverviewReport(StatisticsDtoModel stats) async {
    await _openPdfExportDialog(
      dialogTitle: 'Admin report',
      pdfFileName: 'yamore_admin_report.pdf',
      build: (format) => _buildAdminReportPdf(stats, format),
    );
  }

  Future<Map<int, String>> _loadAllYachtNamesForReport() async {
    final yachtNames = <int, String>{};
    for (var page = 0; ; page++) {
      const pageSize = 200;
      final p = await _api.getYachtOverviewForAdmin(page: page, pageSize: pageSize);
      for (final y in p.resultList) {
        yachtNames[y.yachtId] = y.name;
      }
      if (p.resultList.isEmpty || p.resultList.length < pageSize) break;
      if (p.count != null && yachtNames.length >= p.count!) break;
    }
    return yachtNames;
  }

  Future<Map<int, String>> _loadAllUserNamesForReport() async {
    final userNames = <int, String>{};
    for (var page = 0; ; page++) {
      const pageSize = 200;
      final p = await _api.getUsers(page: page, pageSize: pageSize);
      for (final u in p.resultList) {
        userNames[u.userId] =
            u.displayName.isNotEmpty ? u.displayName : u.username;
      }
      if (p.resultList.length < pageSize) break;
      if (p.count != null && userNames.length >= p.count!) break;
    }
    return userNames;
  }

  /// Loads paged data for the reservations PDF (current calendar year, by created date
  /// when set—otherwise by trip start year—to align with the statistics API’s year filter).
  Future<_ReservationsReportData> _loadReservationsReportData() async {
    final year = DateTime.now().year;
    final all = <Reservation>[];
    for (var page = 0; ; page++) {
      const pageSize = 200;
      final p = await _api.getReservations(page: page, pageSize: pageSize);
      all.addAll(p.resultList);
      if (p.resultList.length < pageSize) break;
      if (p.count != null && all.length >= p.count!) break;
    }
    final inYear = all.where((r) {
      if (r.createdAt != null) return r.createdAt!.year == year;
      return r.startDate.year == year;
    }).toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? a.startDate;
        final bc = b.createdAt ?? b.startDate;
        return bc.compareTo(ac);
      });

    final maps = await Future.wait([
      _loadAllYachtNamesForReport(),
      _loadAllUserNamesForReport(),
    ]);

    return _ReservationsReportData(
      year: year,
      reservations: inYear,
      yachtNames: maps[0],
      userNames: maps[1],
    );
  }

  Future<void> _exportReservationsBookingsReport() async {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Preparing report…',
                      style: Theme.of(ctx).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    try {
      final data = await _loadReservationsReportData();
      if (!context.mounted) return;
      if (navigator.canPop()) {
        navigator.pop();
      }
      await _openPdfExportDialog(
        dialogTitle: 'Reservations & Bookings',
        pdfFileName: 'yamore_reservations_bookings_report.pdf',
        build: (format) => _buildReservationsBookingsPdf(data, format),
      );
    } catch (e) {
      if (!context.mounted) return;
      if (navigator.canPop()) {
        navigator.pop();
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not build report: $e')),
      );
    }
  }

  Future<void> _openPdfExportDialog({
    required String dialogTitle,
    required String pdfFileName,
    required Future<Uint8List> Function(PdfPageFormat format) build,
  }) async {
    if (!context.mounted) return;
    final size = MediaQuery.sizeOf(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: math.min(720, size.height * 0.92),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          dialogTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) => build(format),
                    pdfFileName: pdfFileName,
                    allowPrinting: true,
                    allowSharing: true,
                    canChangePageFormat: true,
                    canChangeOrientation: true,
                    initialPageFormat: PdfPageFormat.a4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPdfDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _pdfShortLabel(String? text, {int maxLen = 28}) {
    if (text == null || text.isEmpty) return '—';
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen - 1)}…';
  }

  /// Builds PDF bytes for the admin report; [format] drives page size in the preview/print flow.
  Future<Uint8List> _buildAdminReportPdf(StatisticsDtoModel stats, PdfPageFormat format) async {
    final doc = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
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
            text: 'Active yachts: ${stats.yachtsCount}, active users: ${stats.activeUsersCount}.',
          ),
          pw.Bullet(
            text:
                'Total bookings: ${stats.totalBookings}, total revenue: ${formatEuroDashboard(stats.totalRevenue)}.',
          ),
          pw.Bullet(
            text: 'Reported reviews: ${stats.reportedReviewsCount}.',
          ),
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
              headers: const ['ID', 'Month', 'Revenue', 'Bookings'],
              data: stats.revenueByMonth
                  .asMap()
                  .entries
                  .map(
                    (e) => [
                      (e.key + 1).toString(),
                      '${e.value.month}/${e.value.year}',
                      formatEuroDashboard(e.value.revenue),
                      e.value.bookingCount.toString(),
                    ],
                  )
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
              headers: const ['ID', 'City', 'Reservations', 'Revenue'],
              data: stats.reservationsByCity
                  .asMap()
                  .entries
                  .map(
                    (e) => [
                      (e.key + 1).toString(),
                      e.value.cityName,
                      e.value.reservationCount.toString(),
                      formatEuroDashboard(e.value.revenue),
                    ],
                  )
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
              headers: const ['ID', 'Yacht', 'Bookings', 'Revenue'],
              data: stats.mostPopularYachts
                  .asMap()
                  .entries
                  .map(
                    (e) => [
                      (e.key + 1).toString(),
                      e.value.yachtName,
                      e.value.bookingCount.toString(),
                      formatEuroDashboard(e.value.totalRevenue),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );

    return doc.save();
  }

  /// Bookings and reservations for the year; same typography and section layout as [_buildAdminReportPdf].
  Future<Uint8List> _buildReservationsBookingsPdf(
    _ReservationsReportData data,
    PdfPageFormat format,
  ) async {
    const cancelledStatus = 'Cancelled';
    final list = data.reservations;
    final byStatus = <String, int>{};
    for (final r in list) {
      final s = (r.status ?? '—').trim();
      final key = s.isEmpty ? '—' : s;
      byStatus[key] = (byStatus[key] ?? 0) + 1;
    }
    final totalDays =
        list.fold<int>(0, (a, r) => a + r.durationDays.clamp(0, 10000));
    final completedRevenue = list
        .where((r) => r.status != cancelledStatus)
        .fold<double>(0, (a, r) => a + (r.totalPrice ?? 0));

    final statusRows = byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final tableRows = <List<String>>[];
    for (var i = 0; i < list.length; i++) {
      final r = list[i];
      tableRows.add([
        (i + 1).toString(),
        r.createdAt != null
            ? _formatPdfDate(r.createdAt!.toLocal())
            : '—',
        _formatPdfDate(r.startDate.toLocal()),
        _formatPdfDate(r.endDate.toLocal()),
        _pdfShortLabel(
          data.userNames[r.userId] ?? 'User #${r.userId}',
        ),
        _pdfShortLabel(
          data.yachtNames[r.yachtId] ?? 'Yacht #${r.yachtId}',
        ),
        (r.status ?? '—'),
        r.totalPrice != null
            ? formatEuroDashboard(r.totalPrice!)
            : '—',
      ]);
    }

    final doc = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Yamore – Reservations & Bookings',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Year ${data.year}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Bullet(
            text: 'Reservations in period: ${list.length}.',
          ),
          if (list.isNotEmpty)
            pw.Bullet(
              text: 'Total charter days (start to end, all rows): $totalDays.',
            ),
          pw.Bullet(
            text:
                'Revenue (excluding cancelled): ${formatEuroDashboard(completedRevenue)}.',
          ),
          if (byStatus.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'By status',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table.fromTextArray(
              headers: const ['ID', 'Status', 'Count'],
              data: [
                for (var i = 0; i < statusRows.length; i++)
                  [
                    (i + 1).toString(),
                    statusRows[i].key,
                    statusRows[i].value.toString(),
                  ],
              ],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            'Detailed listing',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (list.isEmpty)
            pw.Text('No reservations in this year.')
          else
            pw.Table.fromTextArray(
              headers: const [
                'ID',
                'Booked',
                'From',
                'To',
                'Client',
                'Yacht',
                'Status',
                'Total',
              ],
              data: tableRows,
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }
}

class _ReservationsReportData {
  const _ReservationsReportData({
    required this.year,
    required this.reservations,
    required this.yachtNames,
    required this.userNames,
  });
  final int year;
  final List<Reservation> reservations;
  final Map<int, String> yachtNames;
  final Map<int, String> userNames;
}
