import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repositories/repositories.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _loading = false;
  Map<String, dynamic> _revenueData = {};
  List<Map<String, dynamic>> _auditLogs = [];
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);
    final revRes = await repo.getRevenueReport();
    final auditRes = await repo.getAuditLogs();
    if (!mounted) return;

    revRes.match(
      (_) {},
      (data) => _revenueData = data,
    );

    auditRes.match(
      (_) {},
      (logs) => _auditLogs = logs,
    );

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final gross = (_revenueData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final commission = (_revenueData['platformCommission'] as num?)?.toDouble() ?? 0.0;
    final driverPayouts = (_revenueData['driverPayouts'] as num?)?.toDouble() ?? 0.0;
    final dailyStats = (_revenueData['dailyStats'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Analytics & Audit Logs'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh analytics',
            onPressed: _fetchAnalytics,
          ),
          const SizedBox(width: RaftarSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RaftarSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Revenue Summary Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;
                if (isNarrow) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 155,
                          child: _FinancialCard(
                            title: 'Gross Platform Bookings',
                            amount: _currency.format(gross),
                            color: RaftarColors.navy,
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.md),
                        SizedBox(
                          width: 155,
                          child: _FinancialCard(
                            title: 'Platform Take (Commission)',
                            amount: _currency.format(commission),
                            color: RaftarColors.success,
                            icon: Icons.monetization_on_rounded,
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.md),
                        SizedBox(
                          width: 155,
                          child: _FinancialCard(
                            title: 'Driver Earnings Disbursed',
                            amount: _currency.format(driverPayouts),
                            color: RaftarColors.primary,
                            icon: Icons.payments_rounded,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _FinancialCard(
                        title: 'Gross Platform Bookings',
                        amount: _currency.format(gross),
                        color: RaftarColors.navy,
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: RaftarSpacing.md),
                    Expanded(
                      child: _FinancialCard(
                        title: 'Platform Take (Commission)',
                        amount: _currency.format(commission),
                        color: RaftarColors.success,
                        icon: Icons.monetization_on_rounded,
                      ),
                    ),
                    const SizedBox(width: RaftarSpacing.md),
                    Expanded(
                      child: _FinancialCard(
                        title: 'Driver Earnings Disbursed',
                        amount: _currency.format(driverPayouts),
                        color: RaftarColors.primary,
                        icon: Icons.payments_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: RaftarSpacing.xl),

            // Weekly Trend Bar Chart
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                side: const BorderSide(color: RaftarColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RaftarSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Revenue Volume (Past 7 Days)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: RaftarSpacing.xs),
                    const Text(
                      'Aggregated logistics gross revenue recorded on the platform.',
                      style: TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: RaftarSpacing.xl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dailyStats.map((item) {
                        final amt = (item['amount'] as num?)?.toDouble() ?? 10000.0;
                        final heightFactor = (amt / 60000.0).clamp(0.1, 1.0);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${(amt / 1000).toStringAsFixed(1)}k',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 120 * heightFactor,
                                  decoration: BoxDecoration(
                                    color: RaftarColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['date'] ?? '',
                                  style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RaftarSpacing.xl),

            // Admin Audit Logs Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                side: const BorderSide(color: RaftarColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RaftarSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Administrative Audit Logs',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.security_rounded, color: RaftarColors.primary, size: 20),
                      ],
                    ),
                    const SizedBox(height: RaftarSpacing.xs),
                    const Text(
                      'Immutable trail of privileged operational actions performed by system operators.',
                      style: TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                    ),
                    const Divider(height: RaftarSpacing.xl),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _auditLogs.length,
                      separatorBuilder: (context, _) => const Divider(height: RaftarSpacing.md),
                      itemBuilder: (context, index) {
                        final log = _auditLogs[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: RaftarColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_rounded, size: 16, color: RaftarColors.primary),
                            ),
                            const SizedBox(width: RaftarSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        log['action'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: RaftarSpacing.sm),
                                      Text(
                                        'by ${log['performedBy']}',
                                        style: const TextStyle(color: RaftarColors.textTertiary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log['details'] ?? '',
                                    style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              (log['timestamp'] as String? ?? '').split('T').first,
                              style: const TextStyle(color: RaftarColors.textTertiary, fontSize: 11),
                            ),
                          ],
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
    );
  }
}

class _FinancialCard extends StatelessWidget {
  const _FinancialCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaftarRadii.lg),
        side: const BorderSide(color: RaftarColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RaftarSpacing.md, vertical: RaftarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: RaftarColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: RaftarSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
