import 'package:admin_app/app/router/routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repositories/repositories.dart';

class DriverDetailScreen extends ConsumerStatefulWidget {
  const DriverDetailScreen({required this.driverId, super.key});

  final String driverId;

  @override
  ConsumerState<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> {
  bool _loading = true;
  bool _actionBusy = false;
  Map<String, dynamic>? _driver;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    setState(() => _loading = true);
    final result = await ref.read(adminRepositoryProvider).getDriver(widget.driverId);
    if (!mounted) return;
    result.match(
      (_) => setState(() => _loading = false),
      (data) => setState(() {
        _driver = data;
        _loading = false;
      }),
    );
  }

  Future<void> _approveKyc() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Driver KYC?'),
        content: Text(
          'Are you sure you want to approve ${_driver?['fullName']} for live trips on Raftar Gaddi? '
          'Verify that the Driving License (${_driver?['licenseNumber']}) and Aadhaar details match.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RaftarColors.success),
            child: const Text('Approve & Verify', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionBusy = true);
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.approveDriver(widget.driverId);
    if (!mounted) return;
    setState(() => _actionBusy = false);

    res.match(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: ${err.message}'), backgroundColor: RaftarColors.error),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver KYC successfully verified and approved!'),
            backgroundColor: RaftarColors.success,
          ),
        );
        _loadDriver();
      },
    );
  }

  Future<void> _suspendDriver() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide the operational reason to suspend ${_driver?['fullName']}:'),
            const SizedBox(height: RaftarSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Document discrepancy, customer misconduct',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RaftarColors.error),
            child: const Text('Suspend Account', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() => _actionBusy = true);
    final res = await ref.read(adminRepositoryProvider).suspendDriver(widget.driverId, reason);
    if (!mounted) return;
    setState(() => _actionBusy = false);

    res.match(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suspension failed: ${err.message}'), backgroundColor: RaftarColors.error),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver has been suspended.'), backgroundColor: RaftarColors.error),
        );
        _loadDriver();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final d = _driver ?? {};
    final status = d['status'] as String? ?? 'ACTIVE';
    final isPending = status == 'PENDING_APPROVAL';
    final isSuspended = status == 'SUSPENDED';

    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: Text(d['fullName'] ?? 'Driver Details'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AdminRoutes.drivers),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RaftarSpacing.xl),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                side: const BorderSide(color: RaftarColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RaftarSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: RaftarColors.primaryContainer,
                      child: Text(
                        (d['fullName'] as String? ?? 'D')[0],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: RaftarColors.primary),
                      ),
                    ),
                    const SizedBox(width: RaftarSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['fullName'] ?? 'Driver',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d['phone']} • ID: ${d['id']}',
                            style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? RaftarColors.warning.withValues(alpha: 0.15)
                                      : (isSuspended
                                          ? RaftarColors.error.withValues(alpha: 0.15)
                                          : RaftarColors.success.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: isPending
                                        ? Colors.orange.shade900
                                        : (isSuspended ? RaftarColors.error : RaftarColors.success),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: RaftarSpacing.md),
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text('${d['rating'] ?? 5.0} rating', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: RaftarSpacing.md),
                              Text('${d['totalTrips'] ?? 0} trips', style: const TextStyle(color: RaftarColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RaftarSpacing.xl),

            // KYC & Identification Section
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
                        Text(
                          'KYC & Verification Inspection',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: d['kycStatus'] == 'VERIFIED'
                                ? RaftarColors.success.withValues(alpha: 0.12)
                                : RaftarColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            d['kycStatus'] ?? 'UNDER REVIEW',
                            style: TextStyle(
                              color: d['kycStatus'] == 'VERIFIED' ? RaftarColors.success : Colors.orange.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: RaftarSpacing.xl),
                    _DetailRow(label: 'Driving License Number', value: d['licenseNumber'] ?? 'Not submitted'),
                    _DetailRow(label: 'License Expiry', value: d['licenseExpiry'] ?? 'Permanent / Unspecified'),
                    _DetailRow(label: 'Aadhaar Card', value: d['aadhaarNumber'] ?? 'Not submitted'),
                    _DetailRow(label: 'Aadhaar Verified Name', value: d['aadhaarName'] ?? d['fullName'] ?? 'N/A'),
                    _DetailRow(label: 'Operating City', value: d['city'] ?? 'Delhi NCR'),
                    if (d['suspensionReason'] != null)
                      _DetailRow(
                        label: 'Suspension Reason',
                        value: d['suspensionReason'],
                        valueColor: RaftarColors.error,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RaftarSpacing.xl),

            // Vehicle Details
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
                      'Assigned Vehicle Specifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: RaftarSpacing.xl),
                    _DetailRow(label: 'Vehicle Category', value: d['vehicleType'] ?? 'N/A'),
                    _DetailRow(label: 'Registration Plate', value: d['vehiclePlate'] ?? 'N/A'),
                    _DetailRow(label: 'Model / Make', value: d['vehicleModel'] ?? 'N/A'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RaftarSpacing.xxl),

            // Operational Action Buttons
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: RaftarButton(
                      label: 'Approve & Verify Driver',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _actionBusy,
                      onPressed: _approveKyc,
                    ),
                  ),
                  const SizedBox(width: RaftarSpacing.md),
                ],
                if (!isSuspended) ...[
                  Expanded(
                    child: RaftarButton(
                      label: 'Suspend Account',
                      variant: RaftarButtonVariant.secondary,
                      icon: Icons.block_rounded,
                      isLoading: _actionBusy,
                      onPressed: _suspendDriver,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: RaftarButton(
                      label: 'Re-activate Driver',
                      icon: Icons.restore_rounded,
                      isLoading: _actionBusy,
                      onPressed: _approveKyc,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: RaftarSpacing.xxl),
          ],
        ),
      ),
    ),
  );
}
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RaftarSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? RaftarColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
