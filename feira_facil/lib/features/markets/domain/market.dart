class Market {
  final String id;
  final String name;
  final String address;
  final String? observations;
  final double rating;
  final String groupId;
  final String createdBy;
  final DateTime createdAt;

  const Market({
    required this.id,
    required this.name,
    required this.address,
    this.observations,
    this.rating = 0.0,
    required this.groupId,
    required this.createdBy,
    required this.createdAt,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      observations: json['observations'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      groupId: json['groupId'] as String,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (observations != null) 'observations': observations,
      'rating': rating,
      'groupId': groupId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Market copyWith({
    String? id,
    String? name,
    String? address,
    String? observations,
    double? rating,
    String? groupId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Market(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      observations: observations ?? this.observations,
      rating: rating ?? this.rating,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
