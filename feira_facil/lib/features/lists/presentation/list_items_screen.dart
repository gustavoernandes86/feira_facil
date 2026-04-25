import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:feira_facil/core/providers/user_providers.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/core/utils/category_utils.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/features/lists/domain/list_item.dart';
import 'package:feira_facil/features/lists/presentation/fair_lists_controller.dart';

class ListItemsScreen extends ConsumerStatefulWidget {
  final String listId;
  final FairList? listContext;

  const ListItemsScreen({super.key, required this.listId, this.listContext});

  @override
  ConsumerState<ListItemsScreen> createState() => _ListItemsScreenState();
}

class _ListItemsScreenState extends ConsumerState<ListItemsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    if (groupId == null) return const Scaffold(body: Center(child: Text('Erro: Nenhum grupo selecionado')));

    final itemsAsync = ref.watch(listItemsStreamProvider((groupId: groupId, listId: widget.listId)));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: Text(widget.listContext?.name ?? 'Lista Base', style: GoogleFonts.fraunces(fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
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
                  hintText: 'Pesquisar produto...',
                  hintStyle: TextStyle(color: Colors.white54),
                  icon: Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(Icons.search, color: Colors.white54, size: 20),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          var filteredItems = items;
          if (_searchQuery.isNotEmpty) {
            filteredItems = items.where((i) => i.itemId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          if (filteredItems.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildItemCard(context, item, groupId);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemModal(context, ref, groupId),
        label: const Text('Adicionar Produto', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.textBody,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            Text(
              'Lista Base Vazia',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione produtos que você costuma comprar nesta lista.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ListItem item, String groupId) {
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
      onDismissed: (_) {
        ref.read(fairListsControllerProvider(groupId).notifier).removeItemFromList(
          listId: widget.listId, 
          listItemId: item.id
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [AppColors.shadow1],
          border: Border.all(color: AppColors.cream2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.textTertiary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemId,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textBody),
                  ),
                  Text(
                    'Geral',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _qtyBtn(Icons.remove, () {
                    if (item.plannedQuantity > 1) {
                      ref.read(fairListsControllerProvider(groupId).notifier).updateItemQuantity(
                        listId: widget.listId, 
                        listItemId: item.id,
                        newQuantity: item.plannedQuantity - 1
                      );
                    }
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.plannedQuantity.toStringAsFixed(0),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  _qtyBtn(Icons.add, () {
                    ref.read(fairListsControllerProvider(groupId).notifier).updateItemQuantity(
                      listId: widget.listId, 
                      listItemId: item.id,
                      newQuantity: item.plannedQuantity + 1
                    );
                  }),
                ],
              ),
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

  void _showAddItemModal(BuildContext context, WidgetRef ref, String groupId) {
    String itemName = '';
    double itemQuantity = 1.0;
    String selectedCategory = AppCategories.first.name;

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
                      'Adicionar Produto',
                      style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nome do Produto'),
                      onChanged: (val) => itemName = val,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
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
                            if (val != null) setState(() => selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                      initialValue: '1',
                      onChanged: (val) => itemQuantity = double.tryParse(val) ?? 1.0,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (itemName.trim().isEmpty) return;
                        ref.read(fairListsControllerProvider(groupId).notifier).addItemToList(
                          listId: widget.listId, 
                          itemId: itemName.trim(),
                          quantity: itemQuantity.toInt()
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Adicionar à Lista'),
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
