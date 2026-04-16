/// Representa uma faixa de preço progressivo
/// Ex: "3+ unidades por R$ 16,90 cada"
class PriceTier {
  final int quantityMinimum;
  final double pricePerUnit;

  const PriceTier({required this.quantityMinimum, required this.pricePerUnit});

  /// Calcula o preço total para uma quantidade
  double calculateTotal(int quantity) {
    return pricePerUnit * quantity;
  }

  factory PriceTier.fromJson(Map<String, dynamic> json) {
    return PriceTier(
      quantityMinimum: json['quantityMinimum'] as int? ?? 1,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'quantityMinimum': quantityMinimum,
    'pricePerUnit': pricePerUnit,
  };

  PriceTier copyWith({int? quantityMinimum, double? pricePerUnit}) {
    return PriceTier(
      quantityMinimum: quantityMinimum ?? this.quantityMinimum,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }

  @override
  String toString() =>
      'PriceTier(min: $quantityMinimum, price: R\$ $pricePerUnit)';
}
