import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:feira_facil/features/lists/data/fair_lists_repository.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:go_router/go_router.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';
import 'package:feira_facil/core/widgets/responsive_wrapper.dart';
import 'package:feira_facil/core/widgets/shared_widgets.dart';
import 'package:feira_facil/core/widgets/web_sidebar.dart';

String _fmtBRL(double? value) {
  if (value == null) return '—';
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

// ─── Provider ──────────────────────────────────────────────────────────────

class SavingsSummary {
  final List<FairList> lists;
  final double totalSaved;
  final double totalSpent;
  final int purchasesWithData;

  SavingsSummary({
    required this.lists,
    required this.totalSaved,
    required this.totalSpent,
    required this.purchasesWithData,
  });

  double get avgSavingsPerPurchase =>
      purchasesWithData == 0 ? 0 : totalSaved / purchasesWithData;
  double get avgSavingsPct =>
      (totalSpent + totalSaved) == 0
          ? 0
          : (totalSaved / (totalSpent + totalSaved)) * 100;
}

final savingsSummaryProvider =
    StreamProvider.autoDispose.family<SavingsSummary, String>((ref, groupId) {
  final repository = ref.watch(fairListsRepositoryProvider);
  return repository.listsStream(groupId).map((allLists) {
    final lists = allLists.where((l) => l.isSuggested).toList();
    double totalSaved = 0;
    double totalSpent = 0;
    int withData = 0;

    for (final list in lists) {
      if (list.totalCost != null && list.worstCaseCost != null) {
        final saved = list.worstCaseCost! - list.totalCost!;
        if (saved > 0) {
          totalSaved += saved;
          totalSpent += list.totalCost!;
          withData++;
        }
      }
    }

    return SavingsSummary(
      lists: lists,
      totalSaved: totalSaved,
      totalSpent: totalSpent,
      purchasesWithData: withData,
    );
  });
});

// ─── Screen ────────────────────────────────────────────────────────────────

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(currentGroupIdProvider);
    final summaryAsync = groupId != null
        ? ref.watch(savingsSummaryProvider(groupId))
        : const AsyncValue<SavingsSummary>.loading();

    return summaryAsync.when(
      data: (summary) => ResponsiveWrapper(
        mobile: Scaffold(
          backgroundColor: context.colorBackground,
          body: _buildMobileBody(context, summary),
        ),
        web: Scaffold(
          backgroundColor: context.colorBackground,
          body: _buildWebBody(context, summary),
        ),
      ),
      loading: () => Scaffold(
        backgroundColor: context.colorBackground,
        body: Center(
          child: CircularProgressIndicator(color: context.colorGreen),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.colorBackground,
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }

  // ── Mobile Layout Body ──────────────────────────────────────────────────────
  Widget _buildMobileBody(BuildContext context, SavingsSummary summary) {
    return CustomScrollView(
      slivers: [
        // ── Hero Header ──
        SliverToBoxAdapter(
          child: _buildHeader(context, summary),
        ),

        // ── Summary Cards ──
        SliverToBoxAdapter(
          child: _buildSummaryCards(context, summary),
        ),

        // ── Section title ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 16, color: context.colorTextSecondary),
                const SizedBox(width: 8),
                Text(
                  'HISTÓRICO DE COMPRAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: context.colorTextSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.lists.length} compra${summary.lists.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 12, color: context.colorTextTertiary),
                ),
              ],
            ),
          ),
        ),

        // ── List ──
        summary.lists.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyState(context))
            : SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) =>
                        _PurchaseCard(list: summary.lists[i]),
                    childCount: summary.lists.length,
                  ),
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  // ── Web Layout Body ────────────────────────────────────────────────────────
  Widget _buildWebBody(BuildContext context, SavingsSummary summary) {
    final hasSavings = summary.totalSaved > 0;
    final formattedSaved = summary.totalSaved.toStringAsFixed(2).replaceAll('.', ',');

    return Row(
      children: [
        const WebSidebar(active: NavSection.savings),
        Expanded(
          child: Column(
            children: [
              const WebTopBar(
                title: 'Minha Economia',
                subtitle: 'Monitore as métricas financeiras e acompanhe o quanto sua família economizou.',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Graphic Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: context.isDark ? context.colorGreenDark : context.colorGreen,
                              borderRadius: BorderRadius.circular(AppColors.radiusXl),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppColors.radiusXl),
                                    child: const Opacity(
                                      opacity: 0.04,
                                      child: CustomPaint(painter: DotPainter(spacing: 24)),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasSavings ? 'Economia Total Acumulada' : 'Acompanhe seus dados financeiros',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      hasSavings ? 'R\$ $formattedSaved' : 'R\$ 0,00',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (hasSavings) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.trending_up, color: Colors.white, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${summary.avgSavingsPct.toStringAsFixed(1)}% de economia média em relação ao pior caso',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // KPIs Row
                          Row(
                            children: [
                              Expanded(
                                child: WebMetricCard(
                                  icon: Icons.shopping_bag_outlined,
                                  label: 'Compras Concluídas',
                                  value: '${summary.lists.length}',
                                  subtitle: '${summary.purchasesWithData} com dados de preços',
                                  subtitleColor: context.colorOrange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: WebMetricCard(
                                  icon: Icons.savings_outlined,
                                  label: 'Economia Média por Compra',
                                  value: summary.purchasesWithData > 0
                                      ? _fmtBRL(summary.avgSavingsPerPurchase)
                                      : '—',
                                  subtitle: 'Cálculo com base no pior caso',
                                  subtitleColor: context.colorGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Transaction History List Table
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.colorCard,
                              borderRadius: BorderRadius.circular(AppColors.radiusXl),
                              border: Border.all(color: context.colorBorder),
                              boxShadow: context.shadow2,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Histórico de Lançamentos',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: context.colorTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Table Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'COMPRA',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: context.colorTextTertiary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'DATA',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: context.colorTextTertiary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'VALOR PAGO / PIOR CASO',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: context.colorTextTertiary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: Text(
                                          'ECONOMIA',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: context.colorTextTertiary,
                                            letterSpacing: 0.8,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          'AÇÃO',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: context.colorTextTertiary,
                                            letterSpacing: 0.8,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(color: context.colorBorder, height: 1),

                                if (summary.lists.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: Center(
                                      child: Text(
                                        'Nenhum lançamento no histórico.',
                                        style: TextStyle(color: context.colorTextTertiary),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: summary.lists.map((list) {
                                      return _WebSavingsRow(list: list);
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, SavingsSummary summary) {
    final topPadding = MediaQuery.of(context).padding.top;
    final hasSavings = summary.totalSaved > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 40),
      decoration: BoxDecoration(
        color: context.isDark ? context.colorGreenDark : context.colorGreen,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Minha Economia',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Big savings number
          Text(
            hasSavings ? 'Você economizou' : 'Acompanhe sua economia',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSavings ? _fmtBRL(summary.totalSaved) : '—',
            style: GoogleFonts.fraunces(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          if (hasSavings) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${summary.avgSavingsPct.toStringAsFixed(1)}% abaixo do pior cenário',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, SavingsSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.shopping_bag_outlined,
              iconColor: context.colorOrange,
              label: 'Compras\nRealizadas',
              value: '${summary.lists.length}',
              sub: '${summary.purchasesWithData} com dados',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryCard(
              icon: Icons.savings_outlined,
              iconColor: context.colorGreen,
              label: 'Economia\nMédia',
              value: summary.purchasesWithData > 0
                  ? _fmtBRL(summary.avgSavingsPerPurchase)
                  : '—',
              sub: 'por compra',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colorGreenLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.savings_outlined,
                size: 40, color: context.colorGreen),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma compra registrada',
            style: GoogleFonts.fraunces(
                fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Gere uma Compra Sugerida na tela de Comparação para começar a acompanhar sua economia.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: context.colorTextSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadow2,
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: context.colorTextTertiary,
                  fontWeight: FontWeight.bold,
                  height: 1.3)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colorTextPrimary)),
          Text(sub,
              style: TextStyle(
                  fontSize: 10, color: context.colorTextSecondary)),
        ],
      ),
    );
  }
}

// ─── Purchase History Card ─────────────────────────────────────────────────

class _PurchaseCard extends ConsumerWidget {
  final FairList list;

  const _PurchaseCard({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = list.totalCost != null && list.worstCaseCost != null;
    final savings = hasData ? (list.worstCaseCost! - list.totalCost!) : null;
    final hasSavings = savings != null && savings > 0;
    final pct = (hasData && (list.worstCaseCost ?? 0) > 0)
        ? ((savings ?? 0) / list.worstCaseCost!) * 100
        : 0.0;

    final d = list.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return GestureDetector(
      onTap: () => context.pushNamed(
        RouteNames.listDetails,
        pathParameters: {'id': list.id},
        extra: list,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.colorCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.shadow2,
          border: Border.all(color: context.colorBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasSavings
                          ? context.colorGreenLight
                          : context.colorBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasSavings
                          ? Icons.savings_outlined
                          : Icons.shopping_cart_outlined,
                      color: hasSavings ? context.colorGreen : context.colorTextTertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.colorTextPrimary),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                              fontSize: 12, color: context.colorTextTertiary),
                        ),
                      ],
                    ),
                  ),

                  // Savings badge
                  if (hasSavings)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colorGreenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '− ${_fmtBRL(savings)}',
                            style: TextStyle(
                                color: context.colorGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}% off',
                            style: TextStyle(
                                color: context.colorGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else if (!hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colorBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sem dados',
                        style: TextStyle(
                            color: context.colorTextTertiary, fontSize: 11),
                      ),
                    ),
                ],
              ),

              if (hasData) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Cost breakdown row
                Row(
                  children: [
                    Expanded(
                      child: _CostPill(
                        label: 'Você pagou',
                        value: _fmtBRL(list.totalCost),
                        color: context.colorGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CostPill(
                        label: 'Pior cenário',
                        value: _fmtBRL(list.worstCaseCost),
                        color: context.colorTextTertiary,
                        muted: true,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CostPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool muted;

  const _CostPill({
    required this.label,
    required this.value,
    required this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: muted ? context.colorBackground : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: muted ? context.colorTextTertiary : color,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: muted ? context.colorTextSecondary : color)),
        ],
      ),
    );
  }
}

// ─── _WebSavingsRow ──────────────────────────────────────────────────────────
class _WebSavingsRow extends StatelessWidget {
  final FairList list;

  const _WebSavingsRow({required this.list});

  @override
  Widget build(BuildContext context) {
    final hasData = list.totalCost != null && list.worstCaseCost != null;
    final savings = hasData ? (list.worstCaseCost! - list.totalCost!) : null;
    final hasSavings = savings != null && savings > 0;
    final pct = (hasData && (list.worstCaseCost ?? 0) > 0)
        ? ((savings ?? 0) / list.worstCaseCost!) * 100
        : 0.0;

    final d = list.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            // List Info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasSavings
                          ? context.colorGreen.withValues(alpha: 0.1)
                          : context.colorBackground,
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    ),
                    child: Center(
                      child: Icon(
                        hasSavings ? Icons.savings_outlined : Icons.shopping_cart_outlined,
                        color: hasSavings ? context.colorGreen : context.colorTextTertiary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.colorTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                dateStr,
                style: TextStyle(
                  color: context.colorTextTertiary,
                  fontSize: 13,
                ),
              ),
            ),
            // Valor Pago vs Pior Caso
            Expanded(
              flex: 2,
              child: hasData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pago: ${_fmtBRL(list.totalCost)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.colorGreen,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Pior Caso: ${_fmtBRL(list.worstCaseCost)}',
                          style: TextStyle(
                            color: context.colorTextTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Sem dados',
                      style: TextStyle(color: context.colorTextTertiary, fontSize: 13),
                    ),
            ),
            // Savings Badge
            SizedBox(
              width: 140,
              child: Center(
                child: hasSavings
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colorGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        ),
                        child: Text(
                          '− ${_fmtBRL(savings)} (${pct.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            color: context.colorGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : hasData
                        ? Text(
                            '—',
                            style: TextStyle(color: context.colorTextTertiary, fontSize: 12),
                          )
                        : Text(
                            'Sem dados',
                            style: TextStyle(color: context.colorTextTertiary, fontSize: 11),
                          ),
              ),
            ),
            // Actions
            SizedBox(
              width: 100,
              child: Center(
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_rounded, color: context.colorGreen, size: 18),
                  tooltip: 'Ver Detalhes',
                  onPressed: () => context.pushNamed(
                    RouteNames.listDetails,
                    pathParameters: {'id': list.id},
                    extra: list,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
