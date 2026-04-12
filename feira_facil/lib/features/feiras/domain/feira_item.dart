import 'package:cloud_firestore/cloud_firestore.dart';

class FeiraItem {
  final String id;
  final String name;
  final String brand;
  final double unitPrice;
  final double quantity;
  final String unit;
  final String category;
  final bool isAdded;
  final String? groupId; // Adicionado para facilitar consultas globais
  final DateTime? date; // Adicionado para saber a data do preço

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
  });

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
    );
  }
}
