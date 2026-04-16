class FamilyGroup {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> memberIds;
  final DateTime createdAt;
  final String createdBy;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
    required this.createdBy,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String? ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  FamilyGroup copyWith({
    String? id,
    String? name,
    String? inviteCode,
    List<String>? memberIds,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return FamilyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
