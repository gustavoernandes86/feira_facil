import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/items/domain/price.dart';
import 'package:feira_facil/features/markets/domain/market.dart';
import 'package:feira_facil/features/markets/presentation/market_prices_controller.dart';
import 'package:feira_facil/features/markets/presentation/widgets/add_price_modal.dart';

class MarketDetailScreen extends ConsumerWidget {
  final Market market;
  const MarketDetailScreen({super.key, required this.market});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(marketPricesStreamProvider(market.id));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(market.name, style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildMarketInfo(),
          Expanded(
            child: pricesAsync.when(
              data: (prices) {
                if (prices.isEmpty) return _buildEmptyState(context);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: prices.length,
                  itemBuilder: (context, index) => _PriceListItem(price: prices[index], marketId: market.id),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddPriceModal(marketId: market.id),
        ),
        label: const Text('Registrar Preço', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_chart_rounded),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMarketInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textBody,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [AppColors.shadow2],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                market.address.isNotEmpty ? market.address : 'Endereço não informado',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'CATÁLOGO DE PREÇOS',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estes valores serão usados para sugerir onde comprar cada item da sua lista.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏷️', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 24),
          Text(
            'Catálogo Vazio',
            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Comece a registrar os preços deste mercado para economizar nas suas compras.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceListItem extends ConsumerWidget {
  final Price price;
  final String marketId;
  const _PriceListItem({required this.price, required this.marketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pegamos o preço base (primeira faixa)
    final basePrice = price.tiers.isNotEmpty ? price.tiers.first.pricePerUnit : 0.0;
    final hasTiers = price.tiers.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppColors.shadow1],
        border: Border.all(color: AppColors.cream2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.shopping_bag_outlined, color: AppColors.textBody)),
        ),
        title: Text(price.itemId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'R\$ ${basePrice.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (hasTiers)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${price.tiers.length - 1} faixas de atacado',
                  style: const TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Preço?'),
        content: Text('Deseja remover o preço de "${price.itemId}" do catálogo deste mercado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(marketPricesControllerProvider(marketId).notifier).deletePrice(price.id);
              Navigator.pop(ctx);
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
