import 'package:flutter/material.dart';

class FairList {
  final String id;
  final String name;
  final Color color; // Para visual differentiation
  final String status; // 'ativa', 'em_compra', 'concluida'
  final double? budget; // Orçamento opcional
  final String? activeMarketId; // Mercado selecionado para modo compra
  final DateTime createdAt;
  final String createdBy;
  final DateTime? updatedAt;

  FairList({
    required this.id,
    required this.name,
    required this.color,
    this.status = 'ativa',
    this.budget,
    this.activeMarketId,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
  });

  factory FairList.fromJson(Map<String, dynamic> json) {
    return FairList(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int? ?? 0xFFFFF8F2),
      status: json['status'] as String? ?? 'ativa',
      budget: (json['budget'] as num?)?.toDouble(),
      activeMarketId: json['activeMarketId'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'status': status,
    if (budget != null) 'budget': budget,
    if (activeMarketId != null) 'activeMarketId': activeMarketId,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
  };

  FairList copyWith({
    String? id,
    String? name,
    Color? color,
    String? status,
    double? budget,
    String? activeMarketId,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return FairList(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      activeMarketId: activeMarketId ?? this.activeMarketId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
