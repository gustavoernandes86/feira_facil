import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/widgets/premium_header.dart';
import '../../../core/services/places_service.dart';
import '../data/markets_repository.dart';
import '../domain/market.dart';
import 'package:go_router/go_router.dart';
import 'market_detail_screen.dart';
import 'markets_controller.dart';
import '../../lists/data/fair_lists_repository.dart';
import '../../lists/presentation/widgets/comparison_setup_modal.dart';
import '../../../core/router/app_router.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  String _searchQuery = '';

  Future<void> _showComparisonSetup() async {
    final result = await showModalBottomSheet<ComparisonSetup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ComparisonSetupModal(),
    );
    
    if (result == null || !mounted) return;
    
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;
    
    final repo = ref.read(fairListsRepositoryProvider);
    final itemsSnapshot = await repo.listItemsStream(groupId, result.selectedList.id).first;
    
    if (!mounted) return;
    
    context.pushNamed(
      RouteNames.listCompare,
      extra: {
        'fairList': result.selectedList,
        'items': itemsSnapshot,
        'marketIds': result.selectedMarkets.map((m) => m.id).toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    final marketsAsync = groupId != null
        ? ref.watch(marketsStreamProvider(groupId))
        : const AsyncValue<List<Market>>.loading();

    return Scaffold(
      backgroundColor: context.colorBackground,
      body: Column(
        children: [
          PremiumHeader(
            title: 'Mercados',
            subtitle: 'Gerencie os locais de compra do seu grupo.',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                tooltip: 'Comparar Preços',
                onPressed: () => _showComparisonSetup(),
              ),
            ],
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
        backgroundColor: context.isDark ? context.colorGreenDark : context.colorTextBody,
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
          color: context.colorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorBorder),
          boxShadow: context.shadow1,
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Pesquisar mercados...',
            hintStyle: TextStyle(color: context.colorTextTertiary, fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              color: context.colorTextTertiary,
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
        Text(
          'Cadastre seus mercados favoritos para comparar preços.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colorTextSecondary),
        ),
      ],
    );
  }

  void _showAddMarketModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    double? selectedLat;
    double? selectedLng;
    String? selectedPlaceId;
    String? selectedAddress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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

              // Nome do mercado
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome do Mercado',
                  prefixIcon: Icon(Icons.storefront),
                ),
              ),
              const SizedBox(height: 16),

              // Localização via Google Places (New API)
              Text(
                'LOCALIZAÇÃO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.colorTextTertiary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Autocomplete<PlacePrediction>(
                displayStringForOption: (p) => p.description,
                optionsBuilder: (textValue) async {
                  if (textValue.text.length < 3) return [];
                  return PlacesService.autocomplete(textValue.text);
                },
                onSelected: (PlacePrediction prediction) async {
                  addressController.text = prediction.description;
                  final details = await PlacesService.getDetails(prediction.placeId);
                  if (details != null) {
                    setModalState(() {
                      selectedLat = details.latitude;
                      selectedLng = details.longitude;
                      selectedPlaceId = prediction.placeId;
                      selectedAddress = details.formattedAddress;
                      addressController.text = details.formattedAddress;
                    });
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Buscar endereço ou bairro...',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: context.colorBorder),
                          itemBuilder: (context, index) {
                            final pred = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(pred),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_pin, color: context.colorOrange, size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pred.mainText,
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          if (pred.secondaryText.isNotEmpty)
                                            Text(
                                              pred.secondaryText,
                                              style: TextStyle(fontSize: 12, color: context.colorTextTertiary),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Confirmação de endereço selecionado
              if (selectedLat != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: context.colorGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Localização confirmada',
                        style: TextStyle(
                          color: context.colorGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final groupId = ref.read(currentGroupIdProvider);
                  if (groupId == null) return;

                  final newMarket = Market(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    address: selectedAddress ?? addressController.text.trim(),
                    placeId: selectedPlaceId,
                    latitude: selectedLat,
                    longitude: selectedLng,
                    groupId: groupId,
                    createdBy: '',
                    createdAt: DateTime.now(),
                  );

                  // Usa o MarketsController que salva na subcollection correta
                  await ref.read(marketsRepositoryProvider).createMarket(
                    groupId: groupId,
                    name: newMarket.name,
                    address: newMarket.address,
                    userId: '',
                    observations: null,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('CADASTRAR'),
              ),
            ],
          ),
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
        color: context.colorCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.shadow1,
        border: Border.all(color: context.colorBorder),
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
              color: context.colorBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.storefront, color: context.colorOrange, size: 28),
            ),
          ),
          title: Text(
            market.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: market.address.isNotEmpty
              ? Text(
                  market.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorTextTertiary,
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
              final groupId = ref.read(currentGroupIdProvider);
              if (groupId == null) return;
              await ref.read(marketsRepositoryProvider).deleteMarket(groupId, market.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
