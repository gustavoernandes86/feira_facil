class PriceTier {
  final double minQuantity;
  final double unitPrice;

  const PriceTier({
    required this.minQuantity,
    required this.unitPrice,
  });

  factory PriceTier.fromJson(Map<String, dynamic> json) {
    return PriceTier(
      minQuantity: (json['minQuantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minQuantity': minQuantity,
      'unitPrice': unitPrice,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceTier &&
          runtimeType == other.runtimeType &&
          minQuantity == other.minQuantity &&
          unitPrice == other.unitPrice;

  @override
  int get hashCode => minQuantity.hashCode ^ unitPrice.hashCode;
}
