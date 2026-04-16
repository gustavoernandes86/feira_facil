import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/widgets/premium_header.dart';
import '../data/market_repository.dart';
import '../domain/market.dart';
import 'market_detail_screen.dart';

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final marketsAsync = ref.watch(groupMarketsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Mercados',
            subtitle: 'Gerencie os locais de compra do seu grupo.',
          ),

          _buildSearchSection(),

          Expanded(
            child: marketsAsync.when(
              data: (markets) {
                final filteredMarkets = markets
                    .where(
                      (m) => m.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                if (markets.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filteredMarkets.length,
                  itemBuilder: (context, index) {
                    return _MarketListItem(market: filteredMarkets[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMarketModal(context, ref),
        label: const Text(
          'Novo Mercado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.storefront),
        backgroundColor: AppColors.textBody,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cream2),
          boxShadow: [AppColors.shadow1],
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: const InputDecoration(
            hintText: 'Pesquisar mercados...',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textTertiary,
              size: 20,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏪', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 24),
        Text(
          'Nenhum mercado cadastrado',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cadastre seus mercados favoritos para comparar preços.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showAddMarketModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final neighborhoodController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cadastrar Mercado',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Mercado',
                prefixIcon: Icon(Icons.storefront),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: neighborhoodController,
              decoration: const InputDecoration(
                labelText: 'Bairro',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final groupId = ref.read(currentGroupIdProvider);
                if (groupId == null) return;

                final newMarket = Market(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  address: neighborhoodController.text.trim().isEmpty
                      ? ''
                      : neighborhoodController.text.trim(),
                  groupId: groupId,
                  createdBy: '',
                  createdAt: DateTime.now(),
                );

                await ref
                    .read(marketRepositoryProvider)
                    .createMarket(newMarket);
                Navigator.pop(ctx);
              },
              child: const Text('CADASTRAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketListItem extends ConsumerWidget {
  final Market market;
  const _MarketListItem({required this.market});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppColors.shadow1],
        border: Border.all(color: AppColors.cream2),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketDetailScreen(market: market),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.storefront, color: AppColors.orange, size: 28),
            ),
          ),
          title: Text(
            market.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: market.address.isNotEmpty
              ? Text(
                  market.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Excluir Mercado?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold),
        ),
        content: const Text('Isso removerá o mercado da lista do grupo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(marketRepositoryProvider).deleteMarket(market.id);
              Navigator.pop(ctx);
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
