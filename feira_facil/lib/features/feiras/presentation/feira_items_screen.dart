import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../core/utils/category_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../data/feira_items_repository.dart';
import '../data/feira_repository.dart';
import '../domain/feira.dart';
import '../domain/feira_item.dart';
import 'feira_items_controller.dart';

class FeiraItemsScreen extends ConsumerStatefulWidget {
  final String feiraId;
  final Feira? feiraContext;

  const FeiraItemsScreen({super.key, required this.feiraId, this.feiraContext});

  @override
  ConsumerState<FeiraItemsScreen> createState() => _FeiraItemsScreenState();
}

class _FeiraItemsScreenState extends ConsumerState<FeiraItemsScreen> {
  String _searchQuery = '';
  String _filterStatus = 'Tudo'; // Alles, Pendentes, Carrinho

  @override
  Widget build(BuildContext context) {
    final itemsAsyncValue = ref.watch(feiraItemsStreamProvider(widget.feiraId));
    final feiraAsyncValue = ref.watch(feiraProvider(widget.feiraId));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _buildHeader(context, feiraAsyncValue, itemsAsyncValue),

          Expanded(
            child: itemsAsyncValue.when(
              data: (items) {
                final filteredItems = _applyFilters(items);
                if (items.isEmpty) return _buildEmptyState();

                return Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _buildItemCard(context, item);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemModal(context, ref),
        label: const Text(
          'Novo Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.textBody,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<Feira?> feiraAsync,
    AsyncValue<List<FeiraItem>> itemsAsync,
  ) {
    final total =
        itemsAsync.value
            ?.where((i) => i.isAdded)
            .fold(
              0.0,
              (acc, i) => acc + (i.getEffectivePrice(i.quantity) * i.quantity),
            ) ??
        0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  feiraAsync.value?.marketName ?? 'Lista de Compras',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir Feira'),
                        content: const Text(
                            'Deseja excluir esta feira e todos os seus itens?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Excluir',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref
                          .read(feiraRepositoryProvider)
                          .deleteFeira(widget.feiraId);
                      if (context.mounted) context.go('/feiras');
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Excluir Feira',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text(
                    'TOTAL ATUAL',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'R\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Pesquisar item...',
                hintStyle: TextStyle(color: Colors.white54),
                icon: Icon(Icons.search, color: Colors.white54, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          _filterChip('Tudo'),
          const SizedBox(width: 8),
          _filterChip('Pendentes'),
          const SizedBox(width: 8),
          _filterChip('Carrinho'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _filterStatus == label;
    return InkWell(
      onTap: () => setState(() => _filterStatus = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.cream2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, FeiraItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir Item'),
            content: Text('Deseja excluir "${item.name}" da lista?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref
            .read(feiraItemsControllerProvider(widget.feiraId).notifier)
            .removeItem(item.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [AppColors.shadow1],
          border: Border.all(
            color: item.isAdded ? AppColors.greenLight : AppColors.cream2,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => ref
                  .read(feiraItemsControllerProvider(widget.feiraId).notifier)
                  .toggleItem(item, !item.isAdded),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: item.isAdded ? AppColors.green : AppColors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isAdded ? AppColors.green : AppColors.cream2,
                  ),
                ),
                child: item.isAdded
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: item.isAdded
                          ? AppColors.textTertiary
                          : AppColors.textBody,
                      decoration: item.isAdded
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    '${item.brand.isNotEmpty ? "${item.brand} • " : ""}${item.category}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'R\$ ${item.unitPrice.toStringAsFixed(2)} / ${item.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.isAdded
                          ? AppColors.textTertiary
                          : AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controller
            Container(
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _qtyBtn(Icons.remove, () {
                    if (item.quantity > 1) {
                      _updateQty(item, item.quantity - 1);
                    }
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.quantity.toStringAsFixed(0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _qtyBtn(Icons.add, () => _updateQty(item, item.quantity + 1)),
                ],
              ),
            ),
            
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Excluir Item'),
                    content: Text('Deseja excluir "${item.name}" da lista?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Excluir', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref
                      .read(feiraItemsControllerProvider(widget.feiraId).notifier)
                      .removeItem(item.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  void _updateQty(FeiraItem item, double newQty) {
    final updated = item.copyWith(quantity: newQty);
    ref
        .read(feiraItemsControllerProvider(widget.feiraId).notifier)
        .updateItem(updated);
  }

  List<FeiraItem> _applyFilters(List<FeiraItem> items) {
    var result = items;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_filterStatus == 'Pendentes') {
      result = result.where((i) => !i.isAdded).toList();
    } else if (_filterStatus == 'Carrinho') {
      result = result.where((i) => i.isAdded).toList();
    }
    return result;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📝', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            const Text(
              'Lista vazia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Comece adicionando itens clicando no botão abaixo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemModal(BuildContext context, WidgetRef ref) {
    String itemName = '';
    String itemBrand = '';
    double itemPrice = 0.0;
    double itemQuantity = 1.0;
    String selectedCategory = AppCategories.first.name;  // Default to first valid category
    String selectedUnit = 'un';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Novo Item',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nome do Produto',
                      ),
                      onChanged: (val) => itemName = val,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Marca'),
                      onChanged: (val) => itemBrand = val,
                    ),
                    const SizedBox(height: 16),
                    // Categories Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: AppCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.name,
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 20, color: cat.color),
                              const SizedBox(width: 12),
                              Text(cat.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Qtd'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                itemQuantity = double.tryParse(val) ?? 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Preço Unt.',
                              prefixText: 'R\$ ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                itemPrice = double.tryParse(val) ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (itemName.trim().isEmpty) return;
                        final feiraData = ref
                            .read(feiraProvider(widget.feiraId))
                            .value;
                        final newItem = FeiraItem(
                          id: FirebaseFirestore.instance
                              .collection('feiras')
                              .doc(widget.feiraId)
                              .collection('items')
                              .doc()
                              .id,
                          name: itemName,
                          brand: itemBrand,
                          unitPrice: itemPrice,
                          quantity: itemQuantity,
                          unit: selectedUnit,
                          category: selectedCategory,
                          groupId: widget.feiraContext?.groupId,
                          date: widget.feiraContext?.date,
                          tiers: [],
                          marketName: feiraData?.marketName,
                        );
                        ref
                            .read(
                              feiraItemsControllerProvider(
                                widget.feiraId,
                              ).notifier,
                            )
                            .addItem(newItem);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
