import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/items/domain/price_tier.dart';
import 'package:feira_facil/core/utils/unit_utils.dart';
import 'package:feira_facil/features/items/presentation/providers/item_search_provider.dart';
import 'package:feira_facil/features/markets/presentation/market_prices_controller.dart';
import 'package:feira_facil/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

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
  ItemUnit _selectedUnit = ItemUnit.un;
  final _tiers = <PriceTier>[const PriceTier(quantityMinimum: 1, pricePerUnit: 0.0)];
  final _qtyControllers = <TextEditingController>[];
  final _priceControllers = <TextEditingController>[];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItemName);
    _qtyControllers.add(TextEditingController(text: '1'));
    _priceControllers.add(TextEditingController(text: '0,00'));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    for (var c in _qtyControllers) {
      c.dispose();
    }
    for (var c in _priceControllers) {
      c.dispose();
    }
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
            if (widget.initialItemName != null && widget.initialItemName!.isNotEmpty)
              TextField(
                controller: _nameController,
                readOnly: true,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textBody),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.check_circle, size: 20, color: AppColors.green),
                  filled: true,
                  fillColor: AppColors.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              )
            else
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
                error: (_, __) => TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Nome do Produto')
                ),
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

            const SizedBox(height: 16),
            Text(
              'UNIDADE DE MEDIDA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ItemUnit>(
              value: _selectedUnit,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                filled: true,
                fillColor: AppColors.cream.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: ItemUnit.values.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit.label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedUnit = val);
              },
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
              onPressed: () {
                setState(() {
                  _tiers.add(PriceTier(quantityMinimum: _tiers.length.toDouble() + 1, pricePerUnit: 0.0));
                  _qtyControllers.add(TextEditingController(text: (_tiers.length).toString()));
                  _priceControllers.add(TextEditingController(text: '0,00'));
                });
              },
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
      key: ValueKey('tier_$index'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(labelText: 'Qtd min.'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: _qtyControllers[index],
              onChanged: (val) {
                final q = double.tryParse(val.replaceAll(',', '.')) ?? 1.0;
                _tiers[index] = tier.copyWith(quantityMinimum: q);
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedUnit.abbreviation} =', 
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _priceControllers[index],
              decoration: const InputDecoration(
                labelText: 'Preço/un',
                prefixText: 'R\$ ',
              ),
              inputFormatters: [CurrencyInputFormatter()],
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final cleanVal = val.replaceAll('.', '').replaceAll(',', '.');
                final p = double.tryParse(cleanVal) ?? 0.0;
                _tiers[index] = tier.copyWith(pricePerUnit: p);
              },
            ),
          ),
          if (index > 0)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _tiers.removeAt(index);
                  _qtyControllers[index].dispose();
                  _qtyControllers.removeAt(index);
                  _priceControllers[index].dispose();
                  _priceControllers.removeAt(index);
                });
              },
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
        unit: _selectedUnit,
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
