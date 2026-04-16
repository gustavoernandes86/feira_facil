import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/price_history_provider.dart';
import '../../domain/feira_item.dart';

class ItemComparisonSheet extends ConsumerWidget {
  final FeiraItem item;

  const ItemComparisonSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      priceHistoryProvider((
        groupId: item.groupId ?? '',
        itemName: item.name,
        currentItemId: item.id,
      )),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBody,
                      ),
                    ),
                    if (item.brand.isNotEmpty)
                      Text(
                        item.brand,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                style: IconButton.styleFrom(backgroundColor: AppColors.cream),
              ),
            ],
          ),
          const SizedBox(height: 32),
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return _buildEmptyState();
              }

              final allPoints = [
                ...history,
                HistoricalPrice(
                  price: item.unitPrice,
                  marketName: item.marketName ?? 'Atual',
                  date: DateTime.now(),
                ),
              ]..sort((a, b) => a.date.compareTo(b.date));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VARIAÇÃO DE PREÇO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _PriceLineChart(points: allPoints),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'HISTÓRICO POR MERCADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...allPoints.reversed
                      .take(5)
                      .map((point) => _buildPriceRow(point)),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Text('Erro ao carregar histórico: $err'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            const Text(
              'Sem histórico para este item.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(HistoricalPrice point) {
    final isCurrent = point.date.isAfter(
      DateTime.now().subtract(const Duration(minutes: 10)),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.orange.withOpacity(0.05) : AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppColors.orange.withOpacity(0.1)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.marketName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? AppColors.orange : AppColors.textBody,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(point.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${point.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  final List<HistoricalPrice> points;

  const _PriceLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Center(
        child: Text(
          'Progresso insuficiente no gráfico',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      );
    }

    final minPrice = points.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = points.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice;
    final padding = range == 0 ? 1.0 : range * 0.3;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: (minPrice - padding).clamp(0.0, double.infinity),
        maxY: maxPrice + padding,
        lineBarsData: [
          LineChartBarData(
            spots: points.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.price);
            }).toList(),
            isCurved: true,
            color: AppColors.orange,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.orange.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final point = points[barSpot.x.toInt()];
                return LineTooltipItem(
                  '${point.marketName}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'R\$ ${point.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
