import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feira_facil/features/items/domain/price_tier.dart';

class FeiraItem {
  final String id;
  final String name;
  final String brand;
  final double unitPrice;
  final double quantity;
  final String unit;
  final String category;
  final bool isAdded;
  final String? groupId;
  final DateTime? date;
  final List<PriceTier> tiers;
  final String? marketName;

  const FeiraItem({
    required this.id,
    required this.name,
    this.brand = '',
    this.unitPrice = 0.0,
    this.quantity = 1.0,
    this.unit = 'un',
    this.category = 'Geral',
    this.isAdded = false,
    this.groupId,
    this.date,
    this.tiers = const [],
    this.marketName,
  });

  /// Retorna o preço unitário efetivo baseado na quantidade atual e nos tiers
  double getEffectivePrice(double currentQuantity) {
    if (tiers.isEmpty) return unitPrice;
    
    // Filtra as faixas alcançadas e pega a que tem a maior quantidade mínima (mais desconto)
    PriceTier? bestTier;
    for (final tier in tiers) {
      if (currentQuantity >= tier.quantityMinimum) {
        if (bestTier == null || tier.quantityMinimum > bestTier.quantityMinimum) {
          bestTier = tier;
        }
      }
    }
    
    return bestTier?.pricePerUnit ?? unitPrice;
  }

  /// Retorna a próxima faixa disponível para sugerir economia
  PriceTier? getNextTierSuggestion(double currentQuantity) {
    if (tiers.isEmpty) return null;
    
    PriceTier? nextTier;
    for (final tier in tiers) {
      if (tier.quantityMinimum > currentQuantity) {
        if (nextTier == null || tier.quantityMinimum < nextTier.quantityMinimum) {
          nextTier = tier;
        }
      }
    }
    return nextTier;
  }

  factory FeiraItem.fromJson(Map<String, dynamic> json) {
    return FeiraItem(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'un',
      category: json['category'] as String? ?? 'Geral',
      isAdded: json['isAdded'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      date: json['date'] != null ? (json['date'] as Timestamp).toDate() : null,
      tiers: (json['tiers'] as List?)
              ?.map((t) => PriceTier.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
      marketName: json['marketName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'isAdded': isAdded,
      'tiers': tiers.map((t) => t.toJson()).toList(),
      if (marketName != null) 'marketName': marketName,
      if (groupId != null) 'groupId': groupId,
      if (date != null) 'date': Timestamp.fromDate(date!),
    };
  }

  FeiraItem copyWith({
    String? id,
    String? name,
    String? brand,
    double? unitPrice,
    double? quantity,
    String? unit,
    String? category,
    bool? isAdded,
    String? groupId,
    DateTime? date,
    List<PriceTier>? tiers,
    String? marketName,
  }) {
    return FeiraItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isAdded: isAdded ?? this.isAdded,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      tiers: tiers ?? this.tiers,
      marketName: marketName ?? this.marketName,
    );
  }
}
