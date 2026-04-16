/// Representa um ponto no histórico de preço de um item
class HistoricalPrice {
  final double price;
  final String marketName;
  final DateTime date;

  const HistoricalPrice({
    required this.price,
    required this.marketName,
    required this.date,
  });

  factory HistoricalPrice.fromJson(Map<String, dynamic> json) {
    return HistoricalPrice(
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      marketName: json['marketName'] as String? ?? '',
      date: DateTime.parse(
        json['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'price': price,
    'marketName': marketName,
    'date': date.toIso8601String(),
  };

  HistoricalPrice copyWith({
    double? price,
    String? marketName,
    DateTime? date,
  }) {
    return HistoricalPrice(
      price: price ?? this.price,
      marketName: marketName ?? this.marketName,
      date: date ?? this.date,
    );
  }
}
