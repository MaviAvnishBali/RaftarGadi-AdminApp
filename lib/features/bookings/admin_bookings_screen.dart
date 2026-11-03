import 'package:admin_app/app/router/routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:repositories/repositories.dart';

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  String _selectedStatus = 'ALL';
  bool _loading = false;
  List<Map<String, dynamic>> _bookings = [];
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final _statuses = ['ALL', 'IN_TRANSIT', 'PENDING', 'COMPLETED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.getAllBookings(status: _selectedStatus);
    if (!mounted) return;
    res.match(
      (_) => setState(() => _loading = false),
      (list) => setState(() {
        _bookings = list;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Live Bookings & Dispatch'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh bookings',
            onPressed: _fetchBookings,
          ),
          const SizedBox(width: RaftarSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: RaftarColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: RaftarSpacing.xl,
              vertical: RaftarSpacing.md,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: RaftarSpacing.sm),
                    child: ChoiceChip(
                      label: Text(status.replaceAll('_', ' ')),
                      selected: isSelected,
                      selectedColor: RaftarColors.navy,
                      labelStyle: TextStyle(
                        color: isSelected ? RaftarColors.white : RaftarColors.navy,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStatus = status);
                          _fetchBookings();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Booking List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 48, color: RaftarColors.textTertiary),
                            const SizedBox(height: RaftarSpacing.md),
                            Text(
                              'No bookings found for "$_selectedStatus"',
                              style: const TextStyle(color: RaftarColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(RaftarSpacing.xl),
                          itemCount: _bookings.length,
                          separatorBuilder: (context, _) => const SizedBox(height: RaftarSpacing.md),
                          itemBuilder: (context, index) {
                            final b = _bookings[index];
                            final id = b['id'] as String;
                            final bookingNumber = b['bookingNumber'] as String? ?? '';
                            final displayId = bookingNumber.isNotEmpty ? bookingNumber : id;
                            final status = b['status'] as String? ?? 'PENDING';
                            final fare = (b['fare'] as num?)?.toDouble() ?? 0.0;
                            final km = (b['distanceKm'] as num?)?.toDouble() ?? 0.0;
                            final vehicle = b['vehicleType'] as String? ?? '';

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                                side: const BorderSide(color: RaftarColors.border),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                                onTap: () => context.go('${AdminRoutes.bookings}/$id'),
                                child: Padding(
                                  padding: const EdgeInsets.all(RaftarSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    displayId,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: RaftarSpacing.sm),
                                                _BookingStatusBadge(status: status),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: RaftarSpacing.sm),
                                          Text(
                                            _currency.format(fare),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: RaftarColors.navy,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: RaftarSpacing.lg),
                                      Row(
                                        children: [
                                          const Icon(Icons.circle, color: RaftarColors.primary, size: 10),
                                          const SizedBox(width: RaftarSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              b['pickupAddress'] ?? '',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: RaftarColors.error, size: 12),
                                          const SizedBox(width: RaftarSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              b['dropAddress'] ?? '',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: RaftarSpacing.md),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Customer: ${b['customerName']} (${b['customerPhone']})',
                                              style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: RaftarSpacing.sm),
                                          Text(
                                            '$vehicle • $km km',
                                            style: const TextStyle(
                                              color: RaftarColors.textTertiary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'IN_TRANSIT':
        bg = RaftarColors.primary.withValues(alpha: 0.15);
        fg = RaftarColors.primary;
      case 'COMPLETED':
      case 'TRIP_COMPLETED':
        bg = RaftarColors.success.withValues(alpha: 0.15);
        fg = RaftarColors.success;
      case 'CANCELLED':
        bg = RaftarColors.error.withValues(alpha: 0.15);
        fg = RaftarColors.error;
      default:
        bg = RaftarColors.warning.withValues(alpha: 0.15);
        fg = Colors.orange.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
