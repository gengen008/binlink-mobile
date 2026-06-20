class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? bookingId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      bookingId: json['bookingId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
