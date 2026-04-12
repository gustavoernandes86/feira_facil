import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/category_utils.dart';
import '../data/feira_items_repository.dart';
import '../domain/feira.dart';
import '../domain/feira_item.dart';
import 'feira_items_controller.dart';
import 'providers/price_history_provider.dart';

class FeiraItemsScreen extends ConsumerWidget {
  final String feiraId;
  final Feira? feiraContext;

  const FeiraItemsScreen({super.key, required this.feiraId, this.feiraContext});

  void _showAddItemModal(BuildContext context, WidgetRef ref) {
    String itemName = '';
    String itemBrand = '';
    double itemPrice = 0.0;
    double itemQuantity = 1.0;
    String selectedCategory = 'Geral';
    String selectedUnit = 'un';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Novo Item',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nome do Produto (ex: Arroz)',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      onChanged: (val) => itemName = val,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Marca (ex: Tio João)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => itemBrand = val,
                    ),
                    const SizedBox(height: 16),
                    const Text('Categoria:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppCategories.length,
                        itemBuilder: (context, index) {
                          final cat = AppCategories[index];
                          final isSelected = selectedCategory == cat.name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                              label: Text(cat.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => selectedCategory = cat.name);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Qtd',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => itemQuantity = double.tryParse(val) ?? 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unidade',
                              border: OutlineInputBorder(),
                            ),
                            items: ['un', 'kg', 'L', 'g', 'ml', 'cx', 'fardo']
                                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedUnit = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Preço Unt.',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) => itemPrice = double.tryParse(val) ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (itemName.trim().isEmpty) return;
                        final newItem = FeiraItem(
                          id: FirebaseFirestore.instance.collection('feiras').doc(feiraId).collection('items').doc().id,
                          name: itemName,
                          brand: itemBrand,
                          unitPrice: itemPrice,
                          quantity: itemQuantity,
                          unit: selectedUnit,
                          category: selectedCategory,
                          groupId: feiraContext?.groupId,
                          date: feiraContext?.date,
                        );
                        ref.read(feiraItemsControllerProvider(feiraId).notifier).addItem(newItem);
                        Navigator.pop(ctx);
                      },
                      child: const Text('ADICIONAR À LISTA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = feiraContext?.marketName ?? 'Detalhes da Feira';
    final itemsAsyncValue = ref.watch(feiraItemsStreamProvider(feiraId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          itemsAsyncValue.when(
            data: (items) {
              final totalCart = items.where((i) => i.isAdded).fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));
              final totalEstimated = items.fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));
              
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NO CARRINHO',
                            style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2),
                          ),
                          Text(
                            'R\$ ${totalCart.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimado: R\$ ${totalEstimated.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 40),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: itemsAsyncValue.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart, size: 80, color: Colors.green.withOpacity(0.15)),
                          const SizedBox(height: 24),
                          const Text(
                            'Hora de planejar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Adicione os itens que você precisa clicando no botão + ali embaixo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group logical
                final groupedItems = <String, List<FeiraItem>>{};
                for (var item in items) {
                  groupedItems.putIfAbsent(item.category, () => []).add(item);
                }

                // Sort keys based on AppCategories order
                final sortedCategories = groupedItems.keys.toList()
                  ..sort((a, b) {
                    final idxA = AppCategories.indexWhere((c) => c.name == a);
                    final idxB = AppCategories.indexWhere((c) => c.name == b);
                    return idxA.compareTo(idxB);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, catIndex) {
                    final catName = sortedCategories[catIndex];
                    final catItems = groupedItems[catName]!;
                    final catInfo = AppCategories.firstWhere((c) => c.name == catName, orElse: () => AppCategories.last);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              Icon(catInfo.icon, size: 16, color: catInfo.color),
                              const SizedBox(width: 8),
                              Text(
                                catName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${catItems.length} Itens',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                        ...catItems.map((item) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isAdded ? Colors.grey.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: item.isAdded ? Colors.grey.shade200 : Colors.transparent),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: item.isAdded ? TextDecoration.lineThrough : null,
                                color: item.isAdded ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.brand.isNotEmpty ? "${item.brand} • " : ""}${item.quantity.toStringAsFixed(item.unit == "un" ? 0 : 2)} ${item.unit} x R\$ ${item.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(color: item.isAdded ? Colors.grey.shade400 : Colors.black54, fontSize: 13),
                                ),
                                _PriceTrendBadge(item: item),
                              ],
                            ),
                            leading: Checkbox(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              activeColor: Colors.green,
                              value: item.isAdded,
                              onChanged: (bool? checked) {
                                if (checked == null) return;
                                ref.read(feiraItemsControllerProvider(feiraId).notifier).toggleItem(item, checked);
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                ref.read(feiraItemsControllerProvider(feiraId).notifier).removeItem(item.id);
                              },
                            ),
                          ),
                        )),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemModal(context, ref),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('ADICIONAR ITEM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}

class _PriceTrendBadge extends ConsumerWidget {
  final FeiraItem item;
  const _PriceTrendBadge({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.groupId == null || item.unitPrice == 0) return const SizedBox.shrink();

    final trend = ref.watch(priceTrendProvider((
      groupId: item.groupId!,
      itemName: item.name,
      currentItemId: item.id,
      currentPrice: item.unitPrice,
    )));

    if (trend == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: trend.isCheaper ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: trend.isCheaper ? Colors.green.shade100 : Colors.red.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              trend.isCheaper ? Icons.trending_down : Icons.trending_up,
              size: 12,
              color: trend.isCheaper ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              trend.isCheaper 
                ? 'MAIS BARATO (R\$ ${trend.difference.toStringAsFixed(2)})'
                : 'MAIS CARO (R\$ ${trend.difference.toStringAsFixed(2)})',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: trend.isCheaper ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
