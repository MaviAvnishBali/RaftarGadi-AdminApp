import 'package:admin_app/app/router/routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:repositories/repositories.dart';

class AdminBookingDetailScreen extends ConsumerStatefulWidget {
  const AdminBookingDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<AdminBookingDetailScreen> createState() => _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends ConsumerState<AdminBookingDetailScreen> {
  bool _loading = true;
  bool _actionBusy = false;
  Map<String, dynamic>? _booking;
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _loading = true);
    final res = await ref.read(adminRepositoryProvider).getBookingById(widget.bookingId);
    if (!mounted) return;
    res.match(
      (_) => setState(() => _loading = false),
      (data) => setState(() {
        _booking = data;
        _loading = false;
      }),
    );
  }

  Future<void> _cancelBooking() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm admin cancellation for trip ${widget.bookingId}:'),
            const SizedBox(height: RaftarSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter cancellation reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Dismiss'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RaftarColors.error),
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() => _actionBusy = true);
    final res = await ref.read(adminRepositoryProvider).cancelBooking(widget.bookingId, reason);
    if (!mounted) return;
    setState(() => _actionBusy = false);

    res.match(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: RaftarColors.error),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled by Admin.'), backgroundColor: RaftarColors.error),
        );
        _loadBooking();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final b = _booking ?? {};
    final status = b['status'] as String? ?? 'PENDING';
    final fare = (b['fare'] as num?)?.toDouble() ?? 0.0;
    final isCancelled = status == 'CANCELLED';
    final isCompleted = status == 'COMPLETED';

    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: Text('Booking #${b['id']}'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AdminRoutes.bookings),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RaftarSpacing.xl),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Fare Summary Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                side: const BorderSide(color: RaftarColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RaftarSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Status: ${status.replaceAll('_', ' ')}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? RaftarColors.success
                                  : (isCancelled ? RaftarColors.error : RaftarColors.primary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${b['createdAt'] ?? 'N/A'}',
                            style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: RaftarSpacing.md),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _currency.format(fare),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: RaftarColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RaftarSpacing.xl),

            // Route Details
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                side: const BorderSide(color: RaftarColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RaftarSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route & Navigation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: RaftarSpacing.xl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, color: RaftarColors.primary, size: 14),
                        const SizedBox(width: RaftarSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP ADDRESS', style: TextStyle(color: RaftarColors.textTertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(b['pickupAddress'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 6.0),
                      child: SizedBox(height: 20, child: VerticalDivider(color: RaftarColors.borderStrong, thickness: 1.5)),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: RaftarColors.error, size: 16),
                        const SizedBox(width: RaftarSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DROP ADDRESS', style: TextStyle(color: RaftarColors.textTertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(b['dropAddress'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RaftarSpacing.lg),
                    Row(
                      children: [
                        _RouteStat(label: 'Distance', value: '${b['distanceKm'] ?? 0} km'),
                        _RouteStat(label: 'Est. Duration', value: '${b['durationMin'] ?? 0} mins'),
                        _RouteStat(label: 'Vehicle', value: b['vehicleType'] ?? 'Mini Truck'),
                        _RouteStat(label: 'Payment', value: b['paymentMode'] ?? 'UPI'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RaftarSpacing.xl),

            // Parties: Customer and Driver
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RaftarRadii.lg),
                      side: const BorderSide(color: RaftarColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(RaftarSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Divider(),
                          Text(b['customerName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(b['customerPhone'] ?? '', style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: RaftarSpacing.md),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RaftarRadii.lg),
                      side: const BorderSide(color: RaftarColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(RaftarSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assigned Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Divider(),
                          Text(b['driverName'] ?? 'Unassigned', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(b['driverPhone'] ?? '', style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (b['cancelReason'] != null) ...[
              const SizedBox(height: RaftarSpacing.lg),
              Container(
                padding: const EdgeInsets.all(RaftarSpacing.md),
                decoration: BoxDecoration(
                  color: RaftarColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RaftarRadii.md),
                  border: Border.all(color: RaftarColors.error.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Cancellation Reason: ${b['cancelReason']}',
                  style: const TextStyle(color: RaftarColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: RaftarSpacing.xxl),

            // Admin Actions
            if (!isCancelled && !isCompleted)
              RaftarButton(
                label: 'Cancel Booking (Admin Override)',
                variant: RaftarButtonVariant.secondary,
                icon: Icons.cancel_outlined,
                isLoading: _actionBusy,
                onPressed: _cancelBooking,
              ),
            const SizedBox(height: RaftarSpacing.xxl),
          ],
        ),
      ),
    ),
  );
}
}

class _RouteStat extends StatelessWidget {
  const _RouteStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: RaftarColors.textTertiary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
