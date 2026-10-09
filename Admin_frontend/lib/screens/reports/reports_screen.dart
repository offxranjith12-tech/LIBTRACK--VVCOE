import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../../core/constants/app_colors.dart';
import '../../core/auth/permissions.dart';
import '../../models/transaction.dart';
import '../../providers/service_providers.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/alerts_action_button.dart';
import '../../widgets/section_header.dart';

/// Real (non-mock) snapshot of the catalogue for this screen's charts —
/// fetched once, separately from the paginated Book List search, so "Books
/// by Category" and "Most Borrowed Books" reflect the actual database
/// (including anything from a bulk import) instead of the old hardcoded
/// mock list.
final reportsBooksProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(bookRemoteServiceProvider);
  final result = await service.search(page: 0, size: 500);
  return result.books;
});

/// Reports screen — shows the report visualizations only (no "books
/// available / issued / fine collected" counters, per the library's request;
/// those numbers already live on the Dashboard). Download pulls the real
/// report generated server-side from live transaction data, as CSV or PDF.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _downloading = false;

  Future<void> _downloadCsv() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref.read(reportRemoteServiceProvider).downloadTransactionsReport();
      if (!mounted) return;
      // Shared straight from memory (no temp-directory write) — this is what
      // avoids the path_provider "MissingPluginException" some devices hit,
      // since share_plus handles the native file staging itself.
      final file = XFile.fromData(Uint8List.fromList(bytes), name: 'libtrack-transactions-report.csv', mimeType: 'text/csv');
      await Share.shareXFiles([file], text: 'LibTrack transactions report (CSV)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download report: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  /// Builds a real PDF client-side from the same live CSV data the server
  /// generates — gives admins a print-friendly format without needing a
  /// separate PDF library on the backend.
  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref.read(reportRemoteServiceProvider).downloadTransactionsReport();
      final csvText = String.fromCharCodes(bytes);
      final lines = csvText.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
      final rows = lines.map((l) => l.split(',')).toList();

      final doc = pw.Document();
      const rowsPerPage = 32;
      final header = rows.isNotEmpty ? rows.first : <String>[];
      final body = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

      for (var i = 0; i < body.length || i == 0; i += rowsPerPage) {
        final chunk = body.skip(i).take(rowsPerPage).toList();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LibTrack — Transactions Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: header,
                  data: chunk,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            ),
          ),
        );
      }

      final pdfBytes = await doc.save();
      if (!mounted) return;
      final file = XFile.fromData(pdfBytes, name: 'libtrack-transactions-report.pdf', mimeType: 'application/pdf');
      await Share.shareXFiles([file], text: 'LibTrack transactions report (PDF)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showFormatPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Download Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: AppColors.primary),
              title: const Text('CSV (Excel-compatible)'),
              subtitle: const Text('Opens directly in Excel, Sheets, or Numbers', style: TextStyle(fontSize: 11.5)),
              onTap: () {
                Navigator.pop(context);
                _downloadCsv();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
              title: const Text('PDF'),
              subtitle: const Text('Print-friendly, formatted for sharing', style: TextStyle(fontSize: 11.5)),
              onTap: () {
                Navigator.pop(context);
                _downloadPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(reportsBooksProvider);
    final canDownload = Permissions.canViewReports(ref.watch(currentRoleProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          const AlertsActionButton(),
          const SizedBox(width: 4),
          if (canDownload)
            IconButton(
              tooltip: 'Download report',
              icon: _downloading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_download_outlined),
              onPressed: _downloading ? null : _showFormatPicker,
            ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('Could not load report data.\n$err', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                OutlinedButton.icon(onPressed: () => ref.invalidate(reportsBooksProvider), icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ],
            ),
          ),
        ),
        data: (books) => _ReportsBody(books: books, downloading: _downloading, onDownload: _showFormatPicker),
      ),
    );
  }
}

class _ReportsBody extends ConsumerWidget {
  final List<dynamic> books;
  final bool downloading;
  final VoidCallback onDownload;
  const _ReportsBody({required this.books, required this.downloading, required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byCategory = <String, int>{};
    final byDepartment = <String, int>{};
    for (final b in books) {
      byCategory[b.category as String] = (byCategory[b.category as String] ?? 0) + (b.totalCopies as int);
      byDepartment[b.department as String] = (byDepartment[b.department as String] ?? 0) + (b.totalCopies as int);
    }
    final mostBorrowed = [...books]..sort((a, b) => (b.issuedCopies as int).compareTo(a.issuedCopies as int));
    final topBorrowed = mostBorrowed.take(5).toList();

    final transactionsAsync = ref.watch(remoteTransactionsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Pie chart best suits a proportion breakdown — how the catalogue
        // splits across categories.
        const SectionHeader(title: 'Books by Category'),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: byCategory.isEmpty
              ? Center(child: Text('No data', style: TextStyle(color: AppColors.textSecondary)))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 36,
                    sections: [
                      for (final entry in byCategory.entries)
                        PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: entry.key,
                          color: AppColors.chartPalette[byCategory.keys.toList().indexOf(entry.key) % AppColors.chartPalette.length],
                          radius: 60,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
        ),

        // Bar chart best suits comparing discrete categories (departments)
        // side by side.
        const SectionHeader(title: 'Books by Department'),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: byDepartment.isEmpty
              ? Center(child: Text('No data', style: TextStyle(color: AppColors.textSecondary)))
              : _DepartmentBarChart(byDepartment: byDepartment),
        ),

        // Bar chart also suits ranking the top borrowed titles.
        const SectionHeader(title: 'Most Borrowed Books'),
        if (topBorrowed.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Text('No books yet', style: TextStyle(color: AppColors.textSecondary)),
          )
        else ...[
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: _MostBorrowedBarChart(books: topBorrowed),
          ),
          const SizedBox(height: 10),
          ...topBorrowed.asMap().entries.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value.title as String, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('${e.value.issuedCopies} issues', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            );
          }),
        ],

        // Line chart best suits a trend over time — daily borrow/return
        // activity across the last 7 days.
        const SectionHeader(title: 'Borrow / Return Trend (Last 7 Days)'),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: transactionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Could not load trend', style: TextStyle(color: AppColors.textSecondary))),
            data: (txns) => _BorrowReturnLineChart(transactions: txns),
          ),
        ),

        // Table: recent borrow/return activity.
        const SectionHeader(title: 'Recent Activity'),
        transactionsAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Text('Could not load recent activity.\n$e', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          data: (txns) => _RecentActivityTable(transactions: txns),
        ),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Download the full transactions report — CSV or PDF — generated live from the database.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
              TextButton(
                onPressed: downloading ? null : onDownload,
                child: const Text('Download'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Books by department, as a bar chart — better suited than a pie chart for
/// comparing discrete category counts side by side.
class _DepartmentBarChart extends StatelessWidget {
  final Map<String, int> byDepartment;
  const _DepartmentBarChart({required this.byDepartment});

  @override
  Widget build(BuildContext context) {
    final entries = byDepartment.entries.toList();
    final maxY = (entries.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b)).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 10 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(entries[i].key, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  color: AppColors.chartPalette[i % AppColors.chartPalette.length],
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Top borrowed titles, as a horizontal-friendly bar chart.
class _MostBorrowedBarChart extends StatelessWidget {
  final List<dynamic> books;
  const _MostBorrowedBarChart({required this.books});

  @override
  Widget build(BuildContext context) {
    final maxY = (books.map((b) => b.issuedCopies as int).fold<int>(0, (a, b) => a > b ? a : b)).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 10 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= books.length) return const SizedBox.shrink();
                return Text('${i + 1}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < books.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (books[i].issuedCopies as int).toDouble(),
                  color: AppColors.primary,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Daily borrow/return counts over the last 7 days, as a line chart — the
/// right chart type for showing a trend over time.
class _BorrowReturnLineChart extends StatelessWidget {
  final List<LibraryTransaction> transactions;
  const _BorrowReturnLineChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));

    final borrowCounts = <int>[];
    final returnCounts = <int>[];
    for (final day in days) {
      borrowCounts.add(transactions.where((t) => _isSameDay(t.issueDate, day)).length);
      returnCounts.add(transactions.where((t) => t.returnDate != null && _isSameDay(t.returnDate!, day)).length);
    }
    final maxY = [...borrowCounts, ...returnCounts].fold<int>(0, (a, b) => a > b ? a : b).toDouble();

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 5 : maxY * 1.3,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(DateFormat('E').format(days[i]), style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < borrowCounts.length; i++) FlSpot(i.toDouble(), borrowCounts[i].toDouble())],
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: [for (var i = 0; i < returnCounts.length; i++) FlSpot(i.toDouble(), returnCounts[i].toDouble())],
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(AppColors.primary, 'Borrowed'),
            const SizedBox(width: 16),
            _legendDot(AppColors.success, 'Returned'),
          ],
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Table format for recent borrow/return activity, most recent first.
class _RecentActivityTable extends StatelessWidget {
  final List<LibraryTransaction> transactions;
  const _RecentActivityTable({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final sorted = [...transactions]..sort((a, b) => (b.returnDate ?? b.issueDate).compareTo(a.returnDate ?? a.issueDate));
    final recent = sorted.take(10).toList();

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Text('No activity yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 52,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Borrower', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          ],
          rows: [
            for (final t in recent)
              DataRow(cells: [
                DataCell(_activityBadge(t.returnDate != null)),
                DataCell(SizedBox(width: 140, child: Text(t.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)))),
                DataCell(SizedBox(width: 110, child: Text(t.borrowerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)))),
                DataCell(Text(DateFormat('MMM d').format(t.returnDate ?? t.issueDate), style: const TextStyle(fontSize: 12.5))),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _activityBadge(bool isReturn) {
    final color = isReturn ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(isReturn ? 'Return' : 'Borrow', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
