/// Representa um item específico dentro de uma lista de compras
class ListItem {
  final String id;
  final String itemId; // Referência ao item base
  final int plannedQuantity; // Quantidade planejada
  final int cartQuantity; // Quantidade no carrinho (durante modo compra)
  final bool marked; // Marcado como "Peguei!"
  final String? selectedMarketId; // Mercado escolhido para este item (opcional)
  final String category; // Categoria do item

  const ListItem({
    required this.id,
    required this.itemId,
    required this.plannedQuantity,
    this.cartQuantity = 0,
    this.marked = false,
    this.selectedMarketId,
    this.category = 'Outros',
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      plannedQuantity: json['plannedQuantity'] as int? ?? 1,
      cartQuantity: json['cartQuantity'] as int? ?? 0,
      marked: json['marked'] as bool? ?? false,
      selectedMarketId: json['selectedMarketId'] as String?,
      category: json['category'] as String? ?? 'Outros',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'plannedQuantity': plannedQuantity,
    'cartQuantity': cartQuantity,
    'marked': marked,
    if (selectedMarketId != null) 'selectedMarketId': selectedMarketId,
    'category': category,
  };

  ListItem copyWith({
    String? id,
    String? itemId,
    int? plannedQuantity,
    int? cartQuantity,
    bool? marked,
    String? selectedMarketId,
    String? category,
  }) {
    return ListItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      plannedQuantity: plannedQuantity ?? this.plannedQuantity,
      cartQuantity: cartQuantity ?? this.cartQuantity,
      marked: marked ?? this.marked,
      selectedMarketId: selectedMarketId ?? this.selectedMarketId,
      category: category ?? this.category,
    );
  }
}
