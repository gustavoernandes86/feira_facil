import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/core/router/app_router.dart';
import 'package:feira_facil/features/lists/data/fair_lists_repository.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: summaryAsync.when(
        data: (summary) => _buildBody(context, summary),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.green)),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SavingsSummary summary) {

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
                const Icon(Icons.history_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'HISTÓRICO DE COMPRAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.lists.length} compra${summary.lists.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
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

  Widget _buildHeader(
      BuildContext context, SavingsSummary summary) {
    final topPadding = MediaQuery.of(context).padding.top;
    final hasSavings = summary.totalSaved > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
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
                    color: Colors.white.withOpacity(0.15),
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
                color: Colors.white.withOpacity(0.18),
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
              iconColor: AppColors.orange,
              label: 'Compras\nRealizadas',
              value: '${summary.lists.length}',
              sub: '${summary.purchasesWithData} com dados',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryCard(
              icon: Icons.savings_outlined,
              iconColor: AppColors.green,
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
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_outlined,
                size: 40, color: AppColors.green),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma compra registrada',
            style: GoogleFonts.fraunces(
                fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gere uma Compra Sugerida na tela de Comparação para começar a acompanhar sua economia.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppColors.shadow2],
        border: Border.all(color: AppColors.cream2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.bold,
                  height: 1.3)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBody)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [AppColors.shadow2],
          border: Border.all(color: AppColors.cream2),
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
                          ? AppColors.greenLight
                          : AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasSavings
                          ? Icons.savings_outlined
                          : Icons.shopping_cart_outlined,
                      color: hasSavings ? AppColors.green : AppColors.textTertiary,
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textBody),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary),
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
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '− ${_fmtBRL(savings)}',
                            style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}% off',
                            style: const TextStyle(
                                color: AppColors.green,
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
                        color: AppColors.cream2.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Sem dados',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 11),
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
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CostPill(
                        label: 'Pior cenário',
                        value: _fmtBRL(list.worstCaseCost),
                        color: AppColors.textTertiary,
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
        color: muted ? AppColors.cream : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: muted ? AppColors.textTertiary : color,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: muted ? AppColors.textSecondary : color)),
        ],
      ),
    );
  }
}
