import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/fair_list.dart';
import '../domain/list_item.dart';
import '../presentation/fair_lists_controller.dart';
import '../../feiras/domain/feira_item.dart';

/// Notifier para gerenciar o filtro de itens
class ItemFilterNotifier extends Notifier<String> {
  @override
  String build() => 'todos';

  void setFilter(String filter) {
    state = filter;
  }
}

/// Estado do filtro de itens
final _itemFilterProvider = NotifierProvider<ItemFilterNotifier, String>(() {
  return ItemFilterNotifier();
});

/// Subtotal da lista com cálculos de melhor preço
final _listSubtotalProvider =
    FutureProvider.family<
      double,
      ({String groupId, String listId, String marketId})
    >((ref, params) async {
      // Aqui você implementaria a lógica de cálculo do subtotal
      // considerando os preços dos itens no mercado selecionado
      return 0.0;
    });

class ShoppingCartScreen extends ConsumerWidget {
  final String groupId;
  final String listId;
  final FairList fairList;
  final List<({ListItem listItem, FeiraItem feiraItem})> itemsWithDetails;

  const ShoppingCartScreen({
    super.key,
    required this.groupId,
    required this.listId,
    required this.fairList,
    required this.itemsWithDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_itemFilterProvider);
    // Instantiate controller directly with groupId
    final listController = FairListsController(groupId);

    // Filtra itens baseado no filtro selecionado
    final filteredItems = _applyFilter(filter);

    // Calcula subtotal
    double subtotal = 0;
    for (final item in filteredItems) {
      subtotal += item.listItem.cartQuantity * item.feiraItem.unitPrice;
    }

    final hasActiveBudget = fairList.budget != null && fairList.budget! > 0;
    final percentageUsed = hasActiveBudget
        ? ((subtotal / (fairList.budget ?? 1.0)) * 100).toDouble()
        : 0.0;
    final budgetStatus = _getBudgetStatus(percentageUsed);
    final statusEmoji = _getStatusEmoji(percentageUsed);

    return Scaffold(
      appBar: AppBar(
        title: Text(fairList.name),
        centerTitle: true,
        backgroundColor: fairList.color,
        elevation: 0,
        actions: [
          if (fairList.activeMarketId != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${fairList.activeMarketId!.substring(0, 1).toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Budget Display
          if (hasActiveBudget)
            _buildBudgetBar(subtotal, budgetStatus, statusEmoji),

          // Filter Tabs
          _buildFilterTabs(context, ref, filter),

          // Items List
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState(filter)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return CartItemTile(
                        listItem: item.listItem,
                        feiraItem: item.feiraItem,
                        onQuantityChanged: (newQuantity) async {
                          await listController.updateCartQuantity(
                            listId: listId,
                            listItemId: item.listItem.id,
                            cartQuantity: newQuantity,
                          );
                        },
                        onToggleItem: () async {
                          await listController.updateCartQuantity(
                            listId: listId,
                            listItemId: item.listItem.id,
                            marked: !item.listItem.marked,
                          );
                        },
                      );
                    },
                  ),
          ),

          // Floating Action Button with Subtotal
          if (filteredItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.cream2, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          'R\$ ${subtotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                        ),
                      ],
                    ),
                    if (percentageUsed > 100) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('🚨'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alerta de estouro! Orçamento ultrapassado em ${(percentageUsed - 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _showCheckoutDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Finalizar Compras',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetBar(double subtotal, String status, String emoji) {
    final hasActiveBudget = fairList.budget != null && fairList.budget! > 0;
    if (!hasActiveBudget) return const SizedBox.shrink();

    final budget = fairList.budget ?? 0.0;
    final percentage = (subtotal / budget) * 100;
    final remaining = (budget - subtotal).clamp(0, budget);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fairList.color.withAlpha(20),
        border: Border(
          bottom: BorderSide(color: fairList.color.withAlpha(50), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$emoji ${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'R\$ ${subtotal.toStringAsFixed(2)} de R\$ ${budget.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (percentage / 100).clamp(0, 1),
              backgroundColor: AppColors.orangeUltraLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(percentage),
              ),
            ),
          ),

          // Remaining Budget
          const SizedBox(height: 8),
          Text(
            'Restam: R\$ ${remaining.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, WidgetRef ref, String filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.cream2, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['todos', 'pendentes', 'pegos'].map((filterOption) {
            final isSelected = filter == filterOption;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref
                        .read(_itemFilterProvider.notifier)
                        .setFilter(filterOption);
                  }
                },
                label: Text(_getFilterLabel(filterOption)),
                selectedColor: AppColors.orange,
                side: BorderSide(
                  color: isSelected ? AppColors.orange : AppColors.cream2,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    final message = filter == 'pegos'
        ? '✅ Todos os itens foram pegos!'
        : filter == 'pendentes'
        ? '🛒 Nenhum item pendente'
        : '📋 Adicione itens à sua lista';

    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 16),
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Compras'),
        content: const Text('Marcar esta lista como concluída?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementar lógica de conclusão
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Concluír'),
          ),
        ],
      ),
    );
  }

  List<({ListItem listItem, FeiraItem feiraItem})> _applyFilter(String filter) {
    switch (filter) {
      case 'pendentes':
        return itemsWithDetails.where((item) => !item.listItem.marked).toList();
      case 'pegos':
        return itemsWithDetails.where((item) => item.listItem.marked).toList();
      default:
        return itemsWithDetails;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'pendentes':
        return 'Pendentes';
      case 'pegos':
        return 'Pegos ✓';
      default:
        return 'Todos';
    }
  }

  String _getBudgetStatus(double percentage) {
    if (percentage > 100) return 'crítico';
    if (percentage > 90) return 'alto';
    if (percentage > 75) return 'moderado';
    return 'baixo';
  }

  String _getStatusEmoji(double percentage) {
    if (percentage > 90) return '🔴';
    if (percentage > 75) return '🟡';
    return '🟢';
  }

  Color _getStatusColor(double percentage) {
    if (percentage > 90) return AppColors.red;
    if (percentage > 75) return AppColors.orangeMedium;
    return AppColors.green;
  }
}

/// Widget para cada item do carrinho
class CartItemTile extends ConsumerWidget {
  final ListItem listItem;
  final FeiraItem feiraItem;
  final VoidCallback onToggleItem;
  final Function(int) onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.listItem,
    required this.feiraItem,
    required this.onToggleItem,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemUnitPrice = feiraItem.unitPrice;
    final cartQuantity = listItem.cartQuantity;
    final itemTotal = itemUnitPrice * cartQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.cream2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header with Toggle
          Row(
            children: [
              Checkbox(
                value: listItem.marked,
                onChanged: (_) => onToggleItem(),
                activeColor: AppColors.green,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feiraItem.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: listItem.marked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: listItem.marked
                            ? AppColors.textTertiary
                            : AppColors.textBody,
                      ),
                    ),
                    Text(
                      feiraItem.brand.isNotEmpty ? feiraItem.brand : 'Sem marca',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quantity Controls and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      iconSize: 18,
                      constraints: const BoxConstraints(minWidth: 36),
                      onPressed: () =>
                          onQuantityChanged((cartQuantity - 1).clamp(0, 999)),
                      icon: const Icon(Icons.remove),
                      color: AppColors.orange,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$cartQuantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      constraints: const BoxConstraints(minWidth: 36),
                      onPressed: () => onQuantityChanged(cartQuantity + 1),
                      icon: const Icon(Icons.add),
                      color: AppColors.orange,
                    ),
                  ],
                ),
              ),

              // Unit Price and Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${itemUnitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    'R\$ ${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
