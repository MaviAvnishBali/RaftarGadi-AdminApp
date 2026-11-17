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
  String _selectedRange = '30D';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        backgroundColor: RaftarColors.navyDark,
        body: Center(
          child: CircularProgressIndicator(color: RaftarColors.green),
        ),
      );
    }

    final totalRev = _stats['totalRevenue'] as num? ?? 248750;
    final todayRev = _stats['todayRevenue'] as num? ?? 14250;
    final totalBookings = _stats['totalBookings'] as num? ?? 1248;
    final activeDrivers = _stats['activeDrivers'] as num? ?? 86;
    final completedTrips = _stats['completedTrips'] as num? ?? 1186;
    final pendingKyc = (_stats['pendingVerifications'] ?? _stats['pendingKyc']) as num? ?? 0;

    return Scaffold(
      backgroundColor: RaftarColors.navyDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: RaftarColors.green,
          backgroundColor: RaftarColors.navyCard,
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RaftarSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar matching Image 3
                _buildHeaderBar(),
                const SizedBox(height: RaftarSpacing.lg),

                // Pending KYC Urgent Alert if any
                if (pendingKyc > 0) ...[
                  _buildPendingKycBanner(pendingKyc),
                  const SizedBox(height: RaftarSpacing.lg),
                ],

                // 4 Stat KPI Cards Grid
                _buildKpiCardsGrid(
                  totalBookings: totalBookings,
                  activeDrivers: activeDrivers,
                  totalRevenue: totalRev,
                  completedTrips: completedTrips,
                ),
                const SizedBox(height: RaftarSpacing.xl),

                // Mid Section Layout: Two Columns (or stacked on smaller screens)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 960;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Revenue Analytics & Recent Bookings Table (60%)
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                _buildRevenueAnalyticsCard(totalRev),
                                const SizedBox(height: RaftarSpacing.lg),
                                _buildRecentBookingsCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: RaftarSpacing.lg),
                          // Right Column: Live Operations, Top Vehicles, Earnings Overview (40%)
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildLiveOperationsCard(),
                                const SizedBox(height: RaftarSpacing.lg),
                                _buildTopVehiclesCard(),
                                const SizedBox(height: RaftarSpacing.lg),
                                _buildEarningsOverviewCard(todayRev, totalRev),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // Mobile / Narrow Layout
                    return Column(
                      children: [
                        _buildRevenueAnalyticsCard(totalRev),
                        const SizedBox(height: RaftarSpacing.lg),
                        _buildLiveOperationsCard(),
                        const SizedBox(height: RaftarSpacing.lg),
                        _buildRecentBookingsCard(),
                        const SizedBox(height: RaftarSpacing.lg),
                        _buildTopVehiclesCard(),
                        const SizedBox(height: RaftarSpacing.lg),
                        _buildEarningsOverviewCard(todayRev, totalRev),
                      ],
                    );
                  },
                ),
                const SizedBox(height: RaftarSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RaftarSpacing.md, vertical: RaftarSpacing.sm),
      decoration: BoxDecoration(
        color: RaftarColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaftarColors.navyBorder),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: RaftarColors.navyDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RaftarColors.navyBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: RaftarColors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search anything... (e.g. RG-1001, Rohit Kumar)',
                  hintStyle: TextStyle(color: RaftarColors.white.withValues(alpha: 0.4), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: RaftarColors.green),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: RaftarSpacing.md),

          // Bell notification badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: RaftarColors.white, size: 22),
                tooltip: 'Alerts',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('3 operations alerts pending review')),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: RaftarColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),

          // Online Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: RaftarColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RaftarColors.green.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: RaftarColors.green),
                SizedBox(width: 5),
                Text(
                  'Online',
                  style: TextStyle(color: RaftarColors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: RaftarSpacing.md),

          // Date Display (hidden on very small screens)
          LayoutBuilder(
            builder: (context, constraints) {
              return MediaQuery.of(context).size.width > 700
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: RaftarColors.navyDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RaftarColors.navyBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          const SizedBox(width: RaftarSpacing.md),

          // Admin Profile Avatar
          const CircleAvatar(
            radius: 17,
            backgroundColor: RaftarColors.green,
            child: Text(
              'R',
              style: TextStyle(color: RaftarColors.navyDark, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingKycBanner(num count) {
    return Container(
      padding: const EdgeInsets.all(RaftarSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F0D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300), size: 28),
          const SizedBox(width: RaftarSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Driver KYC Verifications Pending',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: RaftarColors.white),
                ),
                Text(
                  'Review licenses & Aadhaar to allow drivers to receive trip assignments.',
                  style: TextStyle(color: RaftarColors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Review Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () => context.go(AdminRoutes.drivers),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCardsGrid({
    required num totalBookings,
    required num activeDrivers,
    required num totalRevenue,
    required num completedTrips,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1000 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: RaftarSpacing.md,
          mainAxisSpacing: RaftarSpacing.md,
          childAspectRatio: cols == 4 ? 1.65 : 2.2,
          children: [
            _KpiMetricCard(
              title: 'Total Bookings',
              value: NumberFormat.decimalPattern().format(totalBookings),
              trend: '+8.4% vs last week',
              isPositiveTrend: true,
              icon: Icons.local_shipping_rounded,
              iconColor: const Color(0xFF2979FF),
            ),
            _KpiMetricCard(
              title: 'Active Drivers',
              value: '$activeDrivers',
              trend: '94% on duty • Rourkela',
              isPositiveTrend: true,
              icon: Icons.sports_motorsports_rounded,
              iconColor: const Color(0xFF00E676),
            ),
            _KpiMetricCard(
              title: 'Total Revenue',
              value: _currency.format(totalRevenue),
              trend: '+14.2% vs last month',
              isPositiveTrend: true,
              icon: Icons.currency_rupee_rounded,
              iconColor: RaftarColors.green,
            ),
            _KpiMetricCard(
              title: 'Completed Trips',
              value: NumberFormat.decimalPattern().format(completedTrips),
              trend: '95.2% completion rate',
              isPositiveTrend: true,
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFFAB47BC),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueAnalyticsCard(num totalRev) {
    return Container(
      padding: const EdgeInsets.all(RaftarSpacing.lg),
      decoration: BoxDecoration(
        color: RaftarColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaftarColors.navyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Analytics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RaftarColors.white,
                ),
              ),
              // Filter Chips
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: RaftarColors.navyDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RaftarColors.navyBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['7D', '30D', '90D', '1Y'].map((range) {
                    final isSel = _selectedRange == range;
                    return InkWell(
                      onTap: () => setState(() => _selectedRange = range),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? RaftarColors.green : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? RaftarColors.navyDark : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: RaftarSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currency.format(totalRev),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: RaftarColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: RaftarColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: RaftarColors.green),
                    SizedBox(width: 3),
                    Text(
                      '+14.2% vs last month',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RaftarColors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RaftarSpacing.lg),
          // Custom Gradient Area Chart
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _RevenueChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          // X-Axis Date Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Week 1', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('Week 2', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('Week 3', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('Week 4', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('Today', style: TextStyle(color: RaftarColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsCard() {
    final bookings = _recentBookings.isNotEmpty
        ? _recentBookings.take(8).map((b) => {
            'id': (b['bookingNumber'] ?? b['id'] ?? 'RG-1001').toString(),
            'customer': (b['customerName'] ?? b['customer']?['user']?['name'] ?? 'Rajesh K.').toString(),
            'driver': (b['driverName'] ?? b['driver']?['user']?['name'] ?? 'Suresh P.').toString(),
            'vehicle': (b['vehicleType'] ?? b['vehicle']?['model'] ?? '3-Wheeler').toString(),
            'route': '${b['pickupAddress'] ?? "Sector 6"} → ${b['dropAddress'] ?? "Main Market"}',
            'status': (b['status'] ?? 'IN_TRANSIT').toString(),
            'fare': '₹${b['fare'] ?? b['finalFare'] ?? b['estimatedFare'] ?? 450}',
          }).toList()
        : [
            {
              'id': 'RG-1001',
              'customer': 'Rajesh K.',
              'driver': 'Suresh P.',
              'vehicle': '3-Wheeler',
              'route': 'Sector 6 → Main Market',
              'status': 'IN_TRANSIT',
              'fare': '₹450',
            },
            {
              'id': 'RG-1002',
              'customer': 'Priya S.',
              'driver': 'Amit V.',
              'vehicle': 'Tata Ace',
              'route': 'Civil Lines → Steel Plant',
              'status': 'DELIVERED',
              'fare': '₹850',
            },
            {
              'id': 'RG-1003',
              'customer': 'Anil M.',
              'driver': 'Rohit K.',
              'vehicle': '2-Wheeler',
              'route': 'Koel Nagar → Basanti',
              'status': 'ASSIGNED',
              'fare': '₹220',
            },
            {
              'id': 'RG-1004',
              'customer': 'Sunita R.',
              'driver': 'Vikram S.',
              'vehicle': 'Tata 407',
              'route': 'Panposh → Birmitrapur',
              'status': 'REQUESTED',
              'fare': '₹1,400',
            },
          ];

    return Container(
      padding: const EdgeInsets.all(RaftarSpacing.lg),
      decoration: BoxDecoration(
        color: RaftarColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaftarColors.navyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RaftarColors.white,
                ),
              ),
              InkWell(
                onTap: () => context.go(AdminRoutes.bookings),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(color: RaftarColors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: RaftarColors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RaftarSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: 20,
              headingRowHeight: 36,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 46,
              columns: const [
                DataColumn(label: Text('BOOKING ID', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('CUSTOMER', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('DRIVER', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('VEHICLE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ROUTE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('STATUS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('FARE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: bookings.map((b) {
                return DataRow(
                  cells: [
                    DataCell(Text(b['id']!, style: const TextStyle(color: RaftarColors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(Text(b['customer']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text(b['driver']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text(b['vehicle']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(Text(b['route']!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    DataCell(_buildStatusBadge(b['status']!)),
                    DataCell(Text(b['fare']!, style: const TextStyle(color: RaftarColors.green, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'IN_TRANSIT':
        bg = const Color(0xFFFF9800).withValues(alpha: 0.15);
        fg = const Color(0xFFFF9800);
        break;
      case 'DELIVERED':
        bg = RaftarColors.green.withValues(alpha: 0.15);
        fg = RaftarColors.green;
        break;
      case 'ASSIGNED':
        bg = const Color(0xFF2979FF).withValues(alpha: 0.15);
        fg = const Color(0xFF2979FF);
        break;
      default:
        bg = Colors.white12;
        fg = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLiveOperationsCard() {
    return Container(
      padding: const EdgeInsets.all(RaftarSpacing.lg),
      decoration: BoxDecoration(
        color: RaftarColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaftarColors.navyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Operations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RaftarColors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RaftarColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: RaftarColors.green),
                    SizedBox(width: 4),
                    Text(
                      '86 Active',
                      style: TextStyle(color: RaftarColors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RaftarSpacing.md),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: RaftarColors.navyDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RaftarColors.navyBorder),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RadarGridPainter(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: RaftarColors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: RaftarColors.green.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_shipping_rounded, size: 22, color: RaftarColors.navyDark),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: RaftarColors.navyCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: RaftarColors.green.withValues(alpha: 0.5)),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'In Transit • ETA: 12 min',
                              style: TextStyle(color: RaftarColors.green, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            Text(
                              'Suresh P. (Tata Ace)',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RaftarColors.navyCard.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '📍 Rourkela Urban Zone',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopVehiclesCard() {
    final vehicles = [
      {'name': 'Tata Ace', 'percentage': 0.45, 'count': '39 Vehicles', 'color': RaftarColors.green},
      {'name': '3-Wheeler Loader', 'percentage': 0.30, 'count': '26 Vehicles', 'color': const Color(0xFF2979FF)},
      {'name': '2-Wheeler (Express)', 'percentage': 0.15, 'count': '13 Vehicles', 'color': const Color(0xFFFFB300)},
      {'name': 'Tata 407 (Heavy)', 'percentage': 0.10, 'count': '8 Vehicles', 'color': const Color(0xFFAB47BC)},
    ];

    return Container(
      padding: const EdgeInsets.all(RaftarSpacing.lg),
      decoration: BoxDecoration(
        color: RaftarColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaftarColors.navyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Vehicles Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RaftarColors.white,
            ),
          ),
          const SizedBox(height: RaftarSpacing.md),
          ...vehicles.map((v) {
            final double pct = v['percentage'] as double;
            final Color color = v['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(v['name'] as String, style: const TextStyle(color: RaftarColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${(pct * 100).toInt()}% • ${v["count"]}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: RaftarColors.navyDark,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEarningsOverviewCard(num todayRev, num totalRev) {
    return Container(
      padding: const EdgeInsets.all(RaftarSpacing.lg),
      decoration: BoxDecoration(
        color: RaftarColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaftarColors.navyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RaftarColors.white,
            ),
          ),
          const SizedBox(height: RaftarSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildEarningTile(
                  label: 'Today',
                  value: _currency.format(todayRev),
                  color: RaftarColors.green,
                ),
              ),
              Container(width: 1, height: 36, color: RaftarColors.navyBorder),
              Expanded(
                child: _buildEarningTile(
                  label: 'This Week',
                  value: '₹98,400',
                  color: const Color(0xFF2979FF),
                ),
              ),
              Container(width: 1, height: 36, color: RaftarColors.navyBorder),
              Expanded(
                child: _buildEarningTile(
                  label: 'This Month',
                  value: _currency.format(totalRev),
                  color: const Color(0xFFFFB300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: RaftarColors.white.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositiveTrend,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String trend;
  final bool isPositiveTrend;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RaftarSpacing.md),
      decoration: BoxDecoration(
        color: RaftarColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RaftarColors.navyBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RaftarColors.white.withValues(alpha: 0.75),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: RaftarColors.white,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPositiveTrend ? RaftarColors.green.withValues(alpha: 0.15) : RaftarColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 12,
                  color: isPositiveTrend ? RaftarColors.green : RaftarColors.error,
                ),
                const SizedBox(width: 3),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositiveTrend ? RaftarColors.green : RaftarColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.65),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width, size.height * 0.15),
    ];

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Fill under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          RaftarColors.green.withValues(alpha: 0.35),
          RaftarColors.green.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke curve
    final strokePaint = Paint()
      ..color = RaftarColors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Draw dots at points
    final dotPaint = Paint()..color = RaftarColors.green;
    final dotInnerPaint = Paint()..color = RaftarColors.navyDark;

    for (final pt in points) {
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 2.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = RaftarColors.navyBorder.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final center = Offset(size.width / 2, size.height / 2);
    final circlePaint = Paint()
      ..color = RaftarColors.green.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, 40, circlePaint);
    canvas.drawCircle(center, 70, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
