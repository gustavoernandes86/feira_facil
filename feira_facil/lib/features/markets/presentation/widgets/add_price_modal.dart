import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/items/domain/price_tier.dart';
import 'package:feira_facil/features/items/presentation/providers/item_search_provider.dart';
import 'package:feira_facil/features/markets/presentation/market_prices_controller.dart';

class AddPriceModal extends ConsumerStatefulWidget {
  final String marketId;
  final String? initialItemName;
  
  const AddPriceModal({
    super.key, 
    required this.marketId,
    this.initialItemName,
  });

  @override
  ConsumerState<AddPriceModal> createState() => _AddPriceModalState();
}

class _AddPriceModalState extends ConsumerState<AddPriceModal> {
  late final TextEditingController _nameController;
  final _brandController = TextEditingController();
  final _tiers = <PriceTier>[const PriceTier(quantityMinimum: 1, pricePerUnit: 0.0)];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItemName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemNamesAsync = ref.watch(groupItemNamesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.add_chart_rounded, color: AppColors.orange, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Registrar Preço',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Autocomplete para Nome do Produto
            Text(
              'PRODUTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            itemNamesAsync.when(
              data: (names) => Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return const Iterable<String>.empty();
                  return names.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Arroz Tio João 5kg',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  );
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const TextField(decoration: InputDecoration(hintText: 'Nome do Produto')),
            ),
            
            const SizedBox(height: 16),
            Text(
              'MARCA (OPCIONAL)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                hintText: 'Ex: Tio João, Qualitá...',
                prefixIcon: Icon(Icons.branding_watermark_outlined, size: 20),
              ),
            ),

            const SizedBox(height: 24),

            // Price Tiers
            Text(
              'VALORES (UNIDADE OU ATACADO)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            ..._tiers.asMap().entries.map((entry) => _buildTierInput(entry.key, entry.value)),
            
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _tiers.add(PriceTier(quantityMinimum: _tiers.length + 1, pricePerUnit: 0.0))),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Preço Mix/Atacado'),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SALVAR NO CATÁLOGO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierInput(int index, PriceTier tier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(labelText: 'Qtd min.'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: tier.quantityMinimum.toString()),
              onChanged: (val) {
                final q = int.tryParse(val) ?? 1;
                setState(() {
                  _tiers[index] = tier.copyWith(quantityMinimum: q);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          const Text('un =', style: TextStyle(color: AppColors.textTertiary)),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Preço/un',
                prefixText: 'R\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                final p = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                setState(() {
                  _tiers[index] = tier.copyWith(pricePerUnit: p);
                });
              },
            ),
          ),
          if (index > 0)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => setState(() => _tiers.removeAt(index)),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    
    try {
      await ref.read(marketPricesControllerProvider(widget.marketId).notifier).addPrice(
        itemName: name,
        tiers: _tiers,
        brand: brand.isEmpty ? null : brand,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
