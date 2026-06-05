import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

void showChatSheet(
  BuildContext context, {
  required String bookingId,
  required String myRole,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ChatSheet(bookingId: bookingId, myRole: myRole),
  );
}

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key, required this.bookingId, required this.myRole});
  final String bookingId;
  final String myRole; // 'HOUSEHOLD' | 'COLLECTOR'

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  // Store handler reference so we can remove only this handler later
  late final void Function(dynamic) _socketHandler;

  @override
  void initState() {
    super.initState();
    _socketHandler = (data) {
      if (!mounted) return;
      final msg = Map<String, dynamic>.from(data as Map);
      // Avoid duplicates: check if id already in list
      if (_messages.any((m) => m['id'] == msg['id'])) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    };
    SocketService.on('chat:message', _socketHandler);
    _load();
  }

  @override
  void dispose() {
    SocketService.offHandler('chat:message', _socketHandler);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/api/bookings/${widget.bookingId}/chat');
      if (!mounted) return;
      setState(() {
        _messages = List<Map<String, dynamic>>.from(res.data['data'] as List);
        _loading  = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      await ApiClient.post(
          '/api/bookings/${widget.bookingId}/chat', {'message': text});
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepOcean,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.steelBlue.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(PhosphorIconsFill.chatCircle,
                          color: AppColors.steelBlue, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('Live Chat', style: AppTextStyles.h4),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.success.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('Live',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),

          // Messages
          Flexible(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.steelBlue))
                : _messages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                  PhosphorIconsRegular.chatTeardrop,
                                  color: AppColors.muted, size: 28),
                            ),
                            const SizedBox(height: 16),
                            const Text('No messages yet',
                                style: AppTextStyles.h4),
                            const SizedBox(height: 6),
                            Text(
                              'Send a message to the '
                              '${widget.myRole == 'HOUSEHOLD' ? 'collector' : 'household'}',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _MessageBubble(
                          message: _messages[i],
                          isMe: _messages[i]['senderRole'] ==
                              widget.myRole,
                        ),
                      ),
          ),

          // Input
          _ChatInput(
            controller: _msgCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});
  final Map<String, dynamic> message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final text   = message['message'] as String? ?? '';
    final sentAt = DateTime.tryParse(message['sentAt'] as String? ?? '');
    final time   = sentAt != null
        ? '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppColors.steelBlue.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.steelBlue.withAlpha(60)),
              ),
              child: const Icon(PhosphorIconsFill.user,
                  color: AppColors.skyBlue, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.steelBlue : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: AppTextStyles.caption.copyWith(
                        color: isMe
                            ? AppColors.white.withAlpha(140)
                            : AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Chat input bar ─────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.muted, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: sending ? AppColors.fieldFill : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: sending
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.steelBlue),
                    )
                  : const Icon(PhosphorIconsFill.paperPlaneTilt,
                      color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
