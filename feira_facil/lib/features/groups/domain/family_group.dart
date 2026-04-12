class FamilyGroup {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> memberIds;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      memberIds: List<String>.from(json['memberIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
    };
  }
}
