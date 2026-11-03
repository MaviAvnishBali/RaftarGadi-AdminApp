import 'dart:async';
import 'package:admin_app/app/router/routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repositories/repositories.dart';
import 'package:shared_models/shared_models.dart';

class AdminSupportChatScreen extends ConsumerStatefulWidget {
  const AdminSupportChatScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<AdminSupportChatScreen> createState() => _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState extends ConsumerState<AdminSupportChatScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  SupportTicket? _ticket;
  List<SupportMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUpdatingStatus = false;
  String? _errorMessage;

  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _pollTimer?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(supportRepositoryProvider);

    // Fetch messages
    final msgsResult = await repo.getMessages(widget.ticketId);
    // Also fetch all tickets to find this ticket's metadata
    final allResult = await repo.getAllTickets();

    if (!mounted) return;

    msgsResult.match(
      (err) {
        setState(() {
          _isLoading = false;
          _errorMessage = err.message;
        });
      },
      (msgs) {
        SupportTicket? foundTicket;
        allResult.match(
          (_) {},
          (list) {
            final match = list.where((t) => t.id == widget.ticketId);
            if (match.isNotEmpty) foundTicket = match.first;
          },
        );

        setState(() {
          _messages = msgs;
          _ticket = foundTicket ??
              SupportTicket(
                id: widget.ticketId,
                userId: '',
                subject: 'Customer Ticket',
                status: 'OPEN',
                priority: 'MEDIUM',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                messages: msgs,
              );
          _isLoading = false;
        });

        _setupSocketAndPolling();
        _scrollToBottom();
      },
    );
  }

  void _setupSocketAndPolling() {
    final socket = ref.read(socketServiceProvider);
    socket.connect(token: ref.read(apiClientProvider).authToken);
    socket.joinSupportTicket(widget.ticketId);

    _socketSub = socket.watchSupportMessages(widget.ticketId).listen((data) {
      if (!mounted) return;
      try {
        final newMsg = SupportMessage.fromJson(data);
        if (!_messages.any((m) => m.id == newMsg.id)) {
          setState(() {
            _messages.add(newMsg);
          });
          _scrollToBottom();
        }
      } catch (e) {
        debugPrint('[AdminSupportChat] Socket parse error: $e');
      }
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshMessages());
  }

  Future<void> _refreshMessages() async {
    final repo = ref.read(supportRepositoryProvider);
    final result = await repo.getMessages(widget.ticketId);
    if (!mounted) return;

    result.match(
      (_) {},
      (msgs) {
        if (msgs.length != _messages.length) {
          setState(() {
            _messages = msgs;
          });
          _scrollToBottom();
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    _replyController.clear();
    setState(() => _isSending = true);

    final repo = ref.read(supportRepositoryProvider);
    final result = await repo.sendMessage(widget.ticketId, text);

    if (!mounted) return;
    setState(() => _isSending = false);

    result.match(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: ${err.message}'),
            backgroundColor: RaftarColors.error,
          ),
        );
      },
      (msg) {
        if (!_messages.any((m) => m.id == msg.id)) {
          setState(() {
            _messages.add(msg);
            if (_ticket != null && _ticket!.status == 'OPEN') {
              _ticket = SupportTicket(
                id: _ticket!.id,
                userId: _ticket!.userId,
                userName: _ticket!.userName,
                userPhone: _ticket!.userPhone,
                userEmail: _ticket!.userEmail,
                bookingId: _ticket!.bookingId,
                subject: _ticket!.subject,
                status: 'IN_PROGRESS',
                priority: _ticket!.priority,
                assignedTo: _ticket!.assignedTo,
                assignedName: _ticket!.assignedName,
                createdAt: _ticket!.createdAt,
                updatedAt: DateTime.now(),
                messages: _messages,
              );
            }
          });
          _scrollToBottom();
        }
      },
    );
  }

  Future<void> _toggleTicketStatus() async {
    if (_ticket == null || _isUpdatingStatus) return;

    final newStatus = _ticket!.status == 'RESOLVED' ? 'IN_PROGRESS' : 'RESOLVED';
    setState(() => _isUpdatingStatus = true);

    final repo = ref.read(supportRepositoryProvider);
    final result = await repo.updateTicketStatus(widget.ticketId, newStatus);

    if (!mounted) return;
    setState(() => _isUpdatingStatus = false);

    result.match(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${err.message}'),
            backgroundColor: RaftarColors.error,
          ),
        );
      },
      (updated) {
        setState(() {
          _ticket = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket marked as $newStatus'),
            backgroundColor: newStatus == 'RESOLVED' ? Colors.green : RaftarColors.primary,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: RaftarColors.navy,
        foregroundColor: RaftarColors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: RaftarColors.primary,
              child: Text(
                _ticket?.userName?.isNotEmpty == true ? _ticket!.userName![0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: RaftarSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _ticket?.userName ?? 'Customer Support Chat',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${_ticket?.userPhone ?? ''} • ${_ticket?.subject ?? ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_ticket != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ticket!.isResolved ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RaftarRadii.pill),
                  ),
                ),
                icon: _isUpdatingStatus
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_ticket!.isResolved ? Icons.replay_rounded : Icons.check_circle_rounded, size: 16),
                label: Text(
                  _ticket!.isResolved ? 'Reopen' : 'Mark Resolved',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _isUpdatingStatus ? null : _toggleTicketStatus,
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Messages',
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: RaftarColors.primary),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: RaftarColors.error, size: 48),
                      const SizedBox(height: RaftarSpacing.md),
                      Text(_errorMessage!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: RaftarSpacing.md),
                      ElevatedButton(
                        onPressed: _fetchDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Linked Booking details banner
                    if (_ticket?.bookingId != null) _buildBookingBanner(_ticket!.bookingId!),

                    // Chat messages list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(RaftarSpacing.md),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildAdminMessageBubble(msg);
                        },
                      ),
                    ),

                    // Reply Input Box
                    _buildAdminInputBar(),
                  ],
                ),
    );
  }

  Widget _buildBookingBanner(String bookingId) {
    final displayId = bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: RaftarSpacing.md, vertical: 8),
      color: RaftarColors.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: RaftarColors.primary, size: 18),
          const SizedBox(width: RaftarSpacing.sm),
          Expanded(
            child: Text(
              'Linked Booking: #$displayId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: RaftarColors.navy,
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('View Order', style: TextStyle(fontSize: 11)),
            onPressed: () => context.push('${AdminRoutes.bookings}/$bookingId'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMessageBubble(SupportMessage msg) {
    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(RaftarRadii.pill),
            ),
            child: Text(
              msg.message,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    final isAgent = msg.isAgent;
    final timeStr =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isAgent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAgent) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAgent ? RaftarColors.navy : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(RaftarRadii.lg),
                  topRight: const Radius.circular(RaftarRadii.lg),
                  bottomLeft: Radius.circular(isAgent ? RaftarRadii.lg : 2),
                  bottomRight: Radius.circular(isAgent ? 2 : RaftarRadii.lg),
                ),
                border: isAgent ? null : Border.all(color: RaftarColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAgent ? (msg.senderName ?? 'Support Agent') : (_ticket?.userName ?? 'Customer'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAgent ? RaftarColors.accent : RaftarColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isAgent ? Colors.white : RaftarColors.navy,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isAgent ? Colors.white60 : Colors.black45,
                        ),
                      ),
                      if (isAgent) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 13, color: Colors.lightBlueAccent),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isAgent) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildAdminInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RaftarSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: RaftarColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: RaftarColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(RaftarRadii.pill),
                  border: Border.all(color: RaftarColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: RaftarSpacing.md),
                child: TextField(
                  controller: _replyController,
                  style: const TextStyle(fontSize: 14, color: RaftarColors.navy),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(),
                  decoration: const InputDecoration(
                    hintText: 'Reply as Support Agent to customer...',
                    hintStyle: TextStyle(fontSize: 13, color: RaftarColors.textSecondary),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: RaftarSpacing.sm),
            Container(
              decoration: const BoxDecoration(
                color: RaftarColors.navy,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _isSending ? null : _sendReply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
