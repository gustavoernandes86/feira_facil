class AppUser {
  final String id;
  final String email;
  final String? name;
  final List<String> groupIds;
  final String? lastGroupId;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.groupIds = const [],
    this.lastGroupId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Pegamos a lista nova ou criamos uma vazia
    final List<String> groups = (json['groupIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    
    // Compatibilidade: se existir o campo antigo 'groupId', adicionamos ele na lista se não estiver lá
    final oldGroupId = json['groupId'] as String?;
    if (oldGroupId != null && oldGroupId.isNotEmpty && !groups.contains(oldGroupId)) {
      groups.add(oldGroupId);
    }

    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      groupIds: groups,
      lastGroupId: json['lastGroupId'] as String? ?? oldGroupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (name != null) 'name': name,
      'groupIds': groupIds,
      if (lastGroupId != null) 'lastGroupId': lastGroupId,
    };
  }
}
