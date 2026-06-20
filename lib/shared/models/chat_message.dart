/// In-app chat message exchanged between a household and their collector for a
/// specific booking. Backed by the Supabase `chat_messages` table and the
/// `GET/POST /api/bookings/:id/chat` endpoints.
///
/// The REST API returns camelCase (normalised by the backend), while Supabase
/// Realtime delivers the raw snake_case row — [ChatMessage.fromMap] accepts
/// both so a single model serves history fetch and live inserts.
class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderRole; // HOUSEHOLD | COLLECTOR | ADMIN
  final String? senderName;
  final String message;
  final DateTime? sentAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    this.senderName,
    this.sentAt,
  });

  /// Accepts both the camelCase REST shape and the snake_case Realtime row.
  factory ChatMessage.fromMap(Map<String, dynamic> m) {
    String? str(String camel, String snake) =>
        (m[camel] ?? m[snake]) as String?;

    final rawSent = m['sentAt'] ?? m['sent_at'];

    return ChatMessage(
      id: (m['id'] as String?) ?? '',
      bookingId: str('bookingId', 'booking_id') ?? '',
      senderId: str('senderId', 'sender_id') ?? '',
      senderRole: (str('senderRole', 'sender_role') ?? '').toUpperCase(),
      senderName: str('senderName', 'sender_name'),
      message: (m['message'] as String?) ?? '',
      sentAt: rawSent is String ? DateTime.tryParse(rawSent)?.toLocal() : null,
    );
  }

  /// True when this message was sent by the role running the current flavor.
  bool isMine(String myRole) => senderRole == myRole.toUpperCase();
}
