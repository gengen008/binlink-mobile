class RewardLedger {
  final String id;
  final int points;
  final String description;
  final String? bookingId;
  final DateTime createdAt;

  const RewardLedger({
    required this.id,
    required this.points,
    required this.description,
    required this.createdAt,
    this.bookingId,
  });

  factory RewardLedger.fromJson(Map<String, dynamic> json) {
    return RewardLedger(
      id: json['id'] as String,
      points: (json['points'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      bookingId: json['bookingId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class RewardTransaction {
  final String id;
  final String type;
  final int points;
  final String description;
  final DateTime createdAt;

  const RewardTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'EARNED',
      points: (json['points'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class Coupon {
  final String id;
  final String title;
  final int pointsRequired;
  final bool eligible;

  const Coupon({
    required this.id,
    required this.title,
    required this.pointsRequired,
    required this.eligible,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      pointsRequired: (json['pointsRequired'] as num?)?.toInt() ?? 0,
      eligible: json['eligible'] as bool? ?? false,
    );
  }
}
