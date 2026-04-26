import 'package:feira_facil/core/utils/unit_utils.dart';
import 'price_tier.dart';

/// Representa um registro de preço de um item em um mercado específico
class Price {
  final String id;
  final String itemId;
  final String marketId;
  final List<PriceTier> tiers;
  final ItemUnit unit; // Unidade de medida (un, kg, bandeja, etc)
  final String? observation;
  final String? photoUrl; // URL da foto da etiqueta (evidência)
  final String sourceType; // 'manual' ou 'ocr'
  final String? brand; // Marca do produto
  final DateTime registeredAt;
  final String registeredBy;

  const Price({
    required this.id,
    required this.itemId,
    required this.marketId,
    required this.tiers,
    this.unit = ItemUnit.un,
    this.observation,
    this.photoUrl,
    this.sourceType = 'manual',
    this.brand,
    required this.registeredAt,
    required this.registeredBy,
  });

  /// Calcula o melhor preço (faixa mais vantajosa) para uma quantidade
  double calculateBestPrice(double quantity) {
    // Ordena as faixas por quantidade mínima DESC e encontra a primeira aplicável
    final applicableTiers = tiers
        .where((tier) => tier.quantityMinimum <= quantity)
        .toList();

    if (applicableTiers.isEmpty) {
      // Se nenhuma faixa aplica, usa a primeira
      return tiers.isNotEmpty ? tiers.first.calculateTotal(quantity) : 0.0;
    }

    // Retorna a faixa com maior qttMinima que still applies
    applicableTiers.sort(
      (a, b) => b.quantityMinimum.compareTo(a.quantityMinimum),
    );
    return applicableTiers.first.calculateTotal(quantity);
  }

  /// Encontra a melhor faixa aplicável para uma quantidade
  PriceTier? getBestTier(double quantity) {
    final applicableTiers = tiers
        .where((tier) => tier.quantityMinimum <= quantity)
        .toList();

    if (applicableTiers.isEmpty) return tiers.isNotEmpty ? tiers.first : null;

    applicableTiers.sort(
      (a, b) => b.quantityMinimum.compareTo(a.quantityMinimum),
    );
    return applicableTiers.first;
  }

  /// Calcula a economia em relação à primeira faixa
  double calculateSavings(double quantity) {
    final baseTier = tiers.isNotEmpty ? tiers.first : null;
    final bestTier = getBestTier(quantity);

    if (baseTier == null || bestTier == null || baseTier == bestTier) {
      return 0.0;
    }

    final basePrice = baseTier.calculateTotal(quantity);
    final bestPrice = bestTier.calculateTotal(quantity);
    return basePrice - bestPrice;
  }

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      marketId: json['marketId'] as String,
      tiers: (json['tiers'] as List<dynamic>? ?? [])
          .map((tier) => PriceTier.fromJson(tier as Map<String, dynamic>))
          .toList(),
      unit: ItemUnit.fromString(json['unit'] as String?),
      observation: json['observation'] as String?,
      photoUrl: json['photoUrl'] as String?,
      sourceType: json['sourceType'] as String? ?? 'manual',
      brand: json['brand'] as String?,
      registeredAt: DateTime.parse(
        json['registeredAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      registeredBy: json['registeredBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'marketId': marketId,
    'tiers': tiers.map((tier) => tier.toJson()).toList(),
    'unit': unit.name,
    if (observation != null) 'observation': observation,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'sourceType': sourceType,
    if (brand != null) 'brand': brand,
    'registeredAt': registeredAt.toIso8601String(),
    'registeredBy': registeredBy,
  };

  Price copyWith({
    String? id,
    String? itemId,
    String? marketId,
    List<PriceTier>? tiers,
    ItemUnit? unit,
    String? observation,
    String? photoUrl,
    String? sourceType,
    String? brand,
    DateTime? registeredAt,
    String? registeredBy,
  }) {
    return Price(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      marketId: marketId ?? this.marketId,
      tiers: tiers ?? this.tiers,
      unit: unit ?? this.unit,
      observation: observation ?? this.observation,
      photoUrl: photoUrl ?? this.photoUrl,
      sourceType: sourceType ?? this.sourceType,
      brand: brand ?? this.brand,
      registeredAt: registeredAt ?? this.registeredAt,
      registeredBy: registeredBy ?? this.registeredBy,
    );
  }
}
