import 'package:admin_app/app/router/routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:repositories/repositories.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentBookings = [];
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);

    final overviewResult = await repo.getOverview();
    final bookingsResult = await repo.getAllBookings(limit: 5);

    if (!mounted) return;

    overviewResult.match(
      (_) {},
      (data) => _stats = data,
    );

    bookingsResult.match(
      (_) {},
      (list) => _recentBookings = list,
    );

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalRev = _stats['totalRevenue'] as num? ?? 0;
    final todayRev = _stats['todayRevenue'] as num? ?? 0;
    final activeBookings = _stats['activeBookings'] as num? ?? 0;
    final activeDrivers = _stats['activeDrivers'] as num? ?? 0;
    final pendingKyc = (_stats['pendingVerifications'] ?? _stats['pendingKyc']) as num? ?? 0;
    final completionRate = (_stats['completionRate'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Operations Dashboard'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh metrics',
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: RaftarSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RaftarSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pending KYC Urgent Alert banner if pending > 0
              if (pendingKyc > 0) ...[
                Container(
                  padding: const EdgeInsets.all(RaftarSpacing.md),
                  decoration: BoxDecoration(
                    color: RaftarColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RaftarRadii.md),
                    border: Border.all(color: RaftarColors.warning.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: RaftarColors.warning, size: 28),
                      const SizedBox(width: RaftarSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$pendingKyc Driver Documents Pending Verification',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Text(
                              'Drivers cannot take trips until their license and Aadhaar KYC are approved.',
                              style: TextStyle(color: RaftarColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Review Now'),
                        onPressed: () => context.go(AdminRoutes.drivers),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RaftarSpacing.lg),
              ],

              // KPI Metric Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: RaftarSpacing.md,
                    mainAxisSpacing: RaftarSpacing.md,
                    childAspectRatio: constraints.maxWidth > 1000 ? 1.7 : 2.0,
                    children: [
                      _KpiCard(
                        title: "Today's Revenue",
                        value: _currency.format(todayRev),
                        subtitle: 'Lifetime: ${_currency.format(totalRev)}',
                        icon: Icons.currency_rupee_rounded,
                        color: RaftarColors.primary,
                      ),
                      _KpiCard(
                        title: 'Active Trips',
                        value: '$activeBookings',
                        subtitle: '$completionRate% completed successfully',
                        icon: Icons.local_shipping_rounded,
                        color: RaftarColors.success,
                      ),
                      _KpiCard(
                        title: 'Online Drivers',
                        value: '$activeDrivers',
                        subtitle: 'Across Delhi NCR & Bengaluru',
                        icon: Icons.electric_rickshaw_rounded,
                        color: RaftarColors.navy,
                      ),
                      _KpiCard(
                        title: 'Pending KYC',
                        value: '$pendingKyc',
                        subtitle: 'Requires admin action',
                        icon: Icons.verified_user_rounded,
                        color: RaftarColors.warning,
                        onTap: () => context.go(AdminRoutes.drivers),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: RaftarSpacing.xl),

              // Quick Actions Bar
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
                        'Operations Shortcuts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: RaftarSpacing.md),
                      Wrap(
                        spacing: RaftarSpacing.md,
                        runSpacing: RaftarSpacing.sm,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.verified_user_rounded, size: 18, color: RaftarColors.primary),
                            label: const Text('Verify Pending Drivers'),
                            onPressed: () => context.go(AdminRoutes.drivers),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.bolt_rounded, size: 18, color: RaftarColors.warning),
                            label: const Text('Update Surge Multiplier'),
                            onPressed: () => context.go(AdminRoutes.pricing),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.alt_route_rounded, size: 18, color: RaftarColors.success),
                            label: const Text('Monitor Live Bookings'),
                            onPressed: () => context.go(AdminRoutes.bookings),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.bar_chart_rounded, size: 18, color: RaftarColors.navy),
                            label: const Text('View Financial Analytics'),
                            onPressed: () => context.go(AdminRoutes.analytics),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: RaftarSpacing.xl),

              // Recent Bookings Stream
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Recent Booking Activity',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            child: const Text('View All Bookings'),
                            onPressed: () => context.go(AdminRoutes.bookings),
                          ),
                        ],
                      ),
                      const SizedBox(height: RaftarSpacing.md),
                      if (_recentBookings.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(RaftarSpacing.xl),
                          child: Center(child: Text('No recent bookings recorded.')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentBookings.length,
                          separatorBuilder: (context, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final b = _recentBookings[index];
                            final status = b['status'] as String? ?? 'PENDING';
                            final fare = (b['fare'] as num?)?.toDouble() ?? 0.0;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: RaftarSpacing.sm,
                                vertical: RaftarSpacing.xs,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: RaftarColors.primaryContainer,
                                child: Icon(
                                  status == 'IN_TRANSIT'
                                      ? Icons.local_shipping_rounded
                                      : (status == 'COMPLETED' || status == 'TRIP_COMPLETED' ? Icons.check_circle_outline : Icons.schedule_rounded),
                                  color: RaftarColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      b['bookingNumber'] ?? b['id'] ?? 'BKG',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _StatusChip(status: status),
                                  const Spacer(),
                                  Text(
                                    _currency.format(fare),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${b['customerName']} • ${b['pickupAddress']} → ${b['dropAddress']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                              onTap: () => context.go('${AdminRoutes.bookings}/${b['id']}'),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaftarRadii.lg),
        side: const BorderSide(color: RaftarColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RaftarRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(RaftarSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: RaftarColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: RaftarColors.navy,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: RaftarColors.textTertiary, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

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
        fg = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status == 'TRIP_COMPLETED' ? 'COMPLETED' : status.replaceAll('_', ' '),
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
