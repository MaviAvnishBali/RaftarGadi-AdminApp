import 'dart:async';
import 'package:admin_app/app/router/routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repositories/repositories.dart';
import 'package:shared_models/shared_models.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<Map<String, dynamic>>? _adminUpdateSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _setupRealtime();
  }

  @override
  void dispose() {
    _adminUpdateSub?.cancel();
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _setupRealtime() {
    final socket = ref.read(socketServiceProvider);
    socket.connect(token: ref.read(apiClientProvider).authToken);

    _adminUpdateSub = socket.watchSupportAdminUpdates().listen((_) {
      if (!mounted) return;
      _fetchTickets(silent: true);
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchTickets(silent: true);
    });
  }

  Future<void> _fetchTickets({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final repo = ref.read(supportRepositoryProvider);
    final statusParam = _selectedStatus == 'ALL' ? null : _selectedStatus;
    final result = await repo.getAllTickets(status: statusParam);

    if (!mounted) return;

    result.match(
      (err) {
        if (!silent) {
          setState(() {
            _isLoading = false;
            _errorMessage = err.message;
          });
        }
      },
      (tickets) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      },
    );
  }

  List<SupportTicket> get _filteredTickets {
    return _tickets.where((ticket) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = (ticket.userName ?? '').toLowerCase();
      final phone = (ticket.userPhone ?? '').toLowerCase();
      final subject = ticket.subject.toLowerCase();
      final bookingId = (ticket.bookingId ?? '').toLowerCase();
      return name.contains(query) ||
          phone.contains(query) ||
          subject.contains(query) ||
          bookingId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTickets;
    final openCount = _tickets.where((t) => t.status == 'OPEN').length;
    final inProgressCount = _tickets.where((t) => t.status == 'IN_PROGRESS').length;
    final resolvedCount = _tickets.where((t) => t.status == 'RESOLVED' || t.status == 'CLOSED').length;

    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Customer Support Helpdesk'),
        backgroundColor: RaftarColors.navy,
        foregroundColor: RaftarColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Tickets',
            onPressed: () => _fetchTickets(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Metrics summary bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: RaftarSpacing.lg,
              vertical: RaftarSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetricBadge(
                    label: 'Open Tickets',
                    count: openCount,
                    color: Colors.orange,
                    isSelected: _selectedStatus == 'OPEN',
                    onTap: () {
                      setState(() => _selectedStatus = _selectedStatus == 'OPEN' ? 'ALL' : 'OPEN');
                      _fetchTickets();
                    },
                  ),
                ),
                const SizedBox(width: RaftarSpacing.md),
                Expanded(
                  child: _MetricBadge(
                    label: 'In Progress',
                    count: inProgressCount,
                    color: Colors.blue,
                    isSelected: _selectedStatus == 'IN_PROGRESS',
                    onTap: () {
                      setState(() => _selectedStatus =
                          _selectedStatus == 'IN_PROGRESS' ? 'ALL' : 'IN_PROGRESS');
                      _fetchTickets();
                    },
                  ),
                ),
                const SizedBox(width: RaftarSpacing.md),
                Expanded(
                  child: _MetricBadge(
                    label: 'Resolved',
                    count: resolvedCount,
                    color: Colors.green,
                    isSelected: _selectedStatus == 'RESOLVED',
                    onTap: () {
                      setState(() => _selectedStatus =
                          _selectedStatus == 'RESOLVED' ? 'ALL' : 'RESOLVED');
                      _fetchTickets();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: RaftarColors.border),

          // Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(RaftarSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by customer name, phone, order ID, or topic...',
                      hintStyle: const TextStyle(fontSize: 13, color: RaftarColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: RaftarColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RaftarRadii.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: RaftarSpacing.md),
                DropdownButton<String>(
                  value: _selectedStatus,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: RaftarColors.navy, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Filter: All')),
                    DropdownMenuItem(value: 'OPEN', child: Text('Status: Open')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Status: In Progress')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('Status: Resolved')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                      _fetchTickets();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: RaftarColors.border),

          // Tickets List
          Expanded(
            child: _isLoading
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
                            ElevatedButton.icon(
                              onPressed: () => _fetchTickets(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: RaftarSpacing.md),
                                const Text(
                                  'No support tickets found',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: RaftarSpacing.xs),
                                const Text(
                                  'Customer support tickets will appear here in real time.',
                                  style: TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(RaftarSpacing.md),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: RaftarSpacing.sm),
                            itemBuilder: (context, index) {
                              final ticket = filtered[index];
                              return _SupportTicketCard(
                                ticket: ticket,
                                onTap: () => context.go('${AdminRoutes.support}/${ticket.id}'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RaftarRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : RaftarColors.surfaceMuted,
          borderRadius: BorderRadius.circular(RaftarRadii.md),
          border: Border.all(
            color: isSelected ? color : RaftarColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : RaftarColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color : RaftarColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latestMsg = ticket.messages.isNotEmpty ? ticket.messages.last : null;
    final timeStr =
        '${ticket.updatedAt.hour.toString().padLeft(2, '0')}:${ticket.updatedAt.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    switch (ticket.status) {
      case 'OPEN':
        statusColor = Colors.orange;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue;
        break;
      case 'RESOLVED':
      case 'CLOSED':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaftarRadii.lg),
        side: const BorderSide(color: RaftarColors.border),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(RaftarRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(RaftarSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: User Avatar, Name, Status Pill
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: RaftarColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      ticket.userName?.isNotEmpty == true ? ticket.userName![0].toUpperCase() : 'C',
                      style: const TextStyle(color: RaftarColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: RaftarSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.userName ?? 'Customer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: RaftarColors.navy),
                        ),
                        if (ticket.userPhone != null)
                          Text(
                            ticket.userPhone!,
                            style: const TextStyle(fontSize: 11, color: RaftarColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RaftarSpacing.sm),

              // Subject & Booking Context
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: RaftarColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ticket.bookingId != null)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: RaftarColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: RaftarColors.border),
                      ),
                      child: Text(
                        '#${ticket.bookingId!.length > 6 ? ticket.bookingId!.substring(0, 6).toUpperCase() : ticket.bookingId}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RaftarColors.navy),
                      ),
                    ),
                ],
              ),

              // Latest Message Snippet
              if (latestMsg != null) ...[
                const SizedBox(height: 4),
                Text(
                  latestMsg.message,
                  style: const TextStyle(fontSize: 12, color: RaftarColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: RaftarSpacing.sm),
              const Divider(height: 1, color: RaftarColors.border),
              const SizedBox(height: RaftarSpacing.xs),

              // Bottom metadata
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Updated $timeStr',
                    style: const TextStyle(fontSize: 10, color: RaftarColors.textTertiary),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Open Chat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: RaftarColors.primary,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: RaftarColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
