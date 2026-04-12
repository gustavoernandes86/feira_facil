class Market {
  final String id;
  final String name;
  final String? neighborhood;
  final String groupId;

  const Market({
    required this.id,
    required this.name,
    this.neighborhood,
    required this.groupId,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] as String,
      name: json['name'] as String,
      neighborhood: json['neighborhood'] as String?,
      groupId: json['groupId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (neighborhood != null) 'neighborhood': neighborhood,
      'groupId': groupId,
    };
  }

  Market copyWith({
    String? id,
    String? name,
    String? neighborhood,
    String? groupId,
  }) {
    return Market(
      id: id ?? this.id,
      name: name ?? this.name,
      neighborhood: neighborhood ?? this.neighborhood,
      groupId: groupId ?? this.groupId,
    );
  }
}
