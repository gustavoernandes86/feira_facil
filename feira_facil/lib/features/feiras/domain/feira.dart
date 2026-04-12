import 'package:cloud_firestore/cloud_firestore.dart';

enum FeiraStatus { aberta, finalizada }

class Feira {
  final String id;
  final String groupId;
  final String? marketName;
  final DateTime date;
  final double totalSpent;
  final double estimatedTotal;
  final int itemsCount;
  final int checkedItemsCount;
  final FeiraStatus status;

  const Feira({
    required this.id,
    required this.groupId,
    this.marketName,
    required this.date,
    this.totalSpent = 0.0,
    this.estimatedTotal = 0.0,
    this.itemsCount = 0,
    this.checkedItemsCount = 0,
    this.status = FeiraStatus.aberta,
  });

  factory Feira.fromJson(Map<String, dynamic> json) {
    return Feira(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      marketName: json['marketName'] as String?,
      date: (json['date'] as Timestamp).toDate(),
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      estimatedTotal: (json['estimatedTotal'] as num?)?.toDouble() ?? 0.0,
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      checkedItemsCount: (json['checkedItemsCount'] as num?)?.toInt() ?? 0,
      status: FeiraStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'aberta'),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      if (marketName != null) 'marketName': marketName,
      'date': Timestamp.fromDate(date),
      'totalSpent': totalSpent,
      'estimatedTotal': estimatedTotal,
      'itemsCount': itemsCount,
      'checkedItemsCount': checkedItemsCount,
      'status': status.name,
    };
  }
}
