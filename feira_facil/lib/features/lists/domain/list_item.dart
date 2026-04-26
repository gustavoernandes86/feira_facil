import 'package:feira_facil/core/utils/unit_utils.dart';

/// Representa um item específico dentro de uma lista de compras
class ListItem {
  final String id;
  final String itemId; // Referência ao item base
  final double plannedQuantity; // Quantidade planejada
  final double cartQuantity; // Quantidade no carrinho (durante modo compra)
  final ItemUnit unit; // Unidade de medida
  final bool marked; // Marcado como "Peguei!"
  final String? selectedMarketId; // Mercado escolhido para este item (opcional)
  final String category; // Categoria do item

  const ListItem({
    required this.id,
    required this.itemId,
    required this.plannedQuantity,
    this.cartQuantity = 0.0,
    this.unit = ItemUnit.un,
    this.marked = false,
    this.selectedMarketId,
    this.category = 'Outros',
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      plannedQuantity: (json['plannedQuantity'] as num?)?.toDouble() ?? 1.0,
      cartQuantity: (json['cartQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: ItemUnit.fromString(json['unit'] as String?),
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
    'unit': unit.name,
    'marked': marked,
    if (selectedMarketId != null) 'selectedMarketId': selectedMarketId,
    'category': category,
  };

  ListItem copyWith({
    String? id,
    String? itemId,
    double? plannedQuantity,
    double? cartQuantity,
    ItemUnit? unit,
    bool? marked,
    String? selectedMarketId,
    String? category,
  }) {
    return ListItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      plannedQuantity: plannedQuantity ?? this.plannedQuantity,
      cartQuantity: cartQuantity ?? this.cartQuantity,
      unit: unit ?? this.unit,
      marked: marked ?? this.marked,
      selectedMarketId: selectedMarketId ?? this.selectedMarketId,
      category: category ?? this.category,
    );
  }
}
