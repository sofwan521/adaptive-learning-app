import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/models/concept_status.dart';
import '../../progress/application/progress_dashboard.dart';

/// Dasbor progres siswa: ringkasan angka, grafik theta (fl_chart),
/// bar penguasaan per konsep, dan riwayat kuis yang bisa disegarkan.
///
/// Siswa baru tanpa data melihat ajakan mulai belajar.
class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(progressDashboardProvider);
    try {
      await ref.read(progressDashboardProvider.future);
    } catch (_) {
      // Galat ditampilkan oleh AsyncValue di bawah.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(progressDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progres')),
      body: dashboardAsync.when(
        data: (dashboard) {
          if (dashboard.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.show_chart_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada progres',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kerjakan kuis pertamamu untuk melihat grafik '
                    'perkembangan dan penguasaan konsepmu di sini.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    key: const Key('progress-start-learning'),
                    label: 'Mulai Belajar',
                    icon: Icons.play_arrow,
                    onPressed: () => context.go(AppRoutes.studentMap),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(dashboard: dashboard),
                const SizedBox(height: 16),
                _ThetaCard(dashboard: dashboard),
                const SizedBox(height: 16),
                _MasteryCard(dashboard: dashboard),
                const SizedBox(height: 16),
                _HistoryCard(dashboard: dashboard),
              ],
            ),
          );
        },
        loading: () => const LoadingView(message: 'Memuat progres…'),
        error: (error, _) => ErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat progres. Silakan coba lagi.',
          onRetry: () => ref.invalidate(progressDashboardProvider),
        ),
      ),
    );
  }
}

/// Tiga angka ringkasan: dikuasai, akurasi 7 hari, total soal.
class _SummaryRow extends StatelessWidget {
  final ProgressDashboard dashboard;

  const _SummaryRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value:
                    '${dashboard.masteredCount}/${dashboard.totalConcepts}',
                label: 'Dikuasai',
                icon: Icons.workspace_premium_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                value: dashboard.accuracy7d == null
                    ? '–'
                    : '${(dashboard.accuracy7d! * 100).round()}%',
                label: 'Akurasi 7 hari',
                icon: Icons.percent,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                value: '${dashboard.totalAnswered}',
                label: 'Total soal',
                icon: Icons.quiz_outlined,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Grafik garis perkembangan theta (fl_chart, responsif penuh).
class _ThetaCard extends StatelessWidget {
  final ProgressDashboard dashboard;

  const _ThetaCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final points = dashboard.thetaPoints;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perkembangan Theta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            dashboard.thetaSource == 'respons'
                ? 'Per jawaban (${points.length} terakhir)'
                : 'Per sesi (${points.length} terakhir)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data theta.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              width: double.infinity,
              child: LineChart(
                _chartData(context, colors, points),
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _chartData(
    BuildContext context,
    ColorScheme colors,
    List<ThetaPoint> points,
  ) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].theta),
    ];
    var minY = spots.first.y;
    var maxY = spots.first.y;
    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    if ((maxY - minY).abs() < 0.2) {
      minY -= 0.5;
      maxY += 0.5;
    } else {
      final pad = (maxY - minY) * 0.15;
      minY -= pad;
      maxY += pad;
    }
    final maxX = (spots.length - 1).toDouble();
    final interval = (maxX / 2).ceilToDouble().clamp(1.0, maxX);

    return LineChartData(
      minX: 0,
      maxX: maxX <= 0 ? 1 : maxX,
      minY: minY,
      maxY: maxY,
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: false,
      ),
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: ((maxY - minY) / 4).clamp(0.1, double.infinity),
            getTitlesWidget: (value, _) => Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: interval,
            getTitlesWidget: (value, _) {
              final index = value.round();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              final mid = (points.length - 1) ~/ 2;
              if (index != 0 && index != mid && index != points.length - 1) {
                return const SizedBox.shrink();
              }
              final time = points[index].time;
              return Text(
                '${time.day}/${time.month}',
                style: Theme.of(context).textTheme.labelSmall,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => [
            for (final spot in touchedSpots)
              LineTooltipItem(
                'θ = ${spot.y.toStringAsFixed(2)}',
                TextStyle(
                  color: colors.onInverseSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: spots.length <= 12,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: colors.primary.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

/// Bar horizontal theta per konsep dengan label terbaca.
class _MasteryCard extends StatelessWidget {
  final ProgressDashboard dashboard;

  const _MasteryCard({required this.dashboard});

  Color _barColor(ConceptStatus status) {
    switch (status) {
      case ConceptStatus.mastered:
        return const Color(0xFF0B5C36);
      case ConceptStatus.learning:
        return const Color(0xFF6B4E00);
      case ConceptStatus.open:
        return const Color(0xFF174A7C);
      case ConceptStatus.locked:
        return const Color(0xFF3D4A43);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Penguasaan per Konsep', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final bar in dashboard.bars) ...[
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bar.code.isEmpty ? bar.conceptId : bar.code,
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        bar.name,
                        style: textTheme.labelSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor:
                          ((bar.thetaC + 4) / 8).clamp(0.03, 1.0),
                      child: Container(color: _barColor(bar.status)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text(
                    bar.thetaC.toStringAsFixed(1),
                    style: textTheme.labelMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Daftar riwayat kuis: konsep, tanggal, dan hasil.
class _HistoryCard extends StatelessWidget {
  final ProgressDashboard dashboard;

  const _HistoryCard({required this.dashboard});

  String _dateText(DateTime? date) {
    if (date == null) return 'Tanggal tak diketahui';
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Riwayat Kuis', style: textTheme.titleLarge),
          ),
          if (dashboard.history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada sesi kuis.',
                style: textTheme.bodyMedium,
              ),
            )
          else
            for (final item in dashboard.history)
              ListTile(
                leading: Icon(
                  item.resultLabel == 'Selesai'
                      ? Icons.check_circle
                      : item.resultLabel == 'Berjalan'
                          ? Icons.pending
                          : Icons.cancel,
                  color: item.resultLabel == 'Selesai'
                      ? Colors.green.shade700
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(item.title),
                subtitle: Text(
                  '${_dateText(item.date)}'
                  '${item.scoreText == null ? '' : ' • ${item.scoreText}'}',
                ),
                trailing: item.theta == null
                    ? Text(
                        item.resultLabel,
                        style: textTheme.labelMedium,
                      )
                    : Text(
                        'θ ${item.theta!.toStringAsFixed(1)}',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
        ],
      ),
    );
  }
}
