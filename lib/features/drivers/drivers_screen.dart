import 'package:admin_app/app/router/routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repositories/repositories.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  String _selectedTab = 'ALL';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _drivers = [];

  final _tabs = ['ALL', 'PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED'];

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDrivers() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.getDrivers(
      status: _selectedTab,
      search: _searchQuery,
    );
    if (!mounted) return;
    result.match(
      (_) => setState(() => _loading = false),
      (list) => setState(() {
        _drivers = list;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Driver & Fleet Management'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh drivers',
            onPressed: _fetchDrivers,
          ),
          const SizedBox(width: RaftarSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs & Search Header
          Container(
            color: RaftarColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: RaftarSpacing.xl,
              vertical: RaftarSpacing.md,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search driver by name, phone, or vehicle plate...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    _fetchDrivers();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: RaftarColors.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(RaftarRadii.md),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                          _fetchDrivers();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RaftarSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tabs.map((tab) {
                      final isSelected = _selectedTab == tab;
                      final label = tab == 'ALL'
                          ? 'All Drivers'
                          : (tab == 'PENDING_APPROVAL'
                              ? 'Pending KYC'
                              : (tab == 'ACTIVE' ? 'Active' : 'Suspended'));
                      return Padding(
                        padding: const EdgeInsets.only(right: RaftarSpacing.sm),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: RaftarColors.navy,
                          labelStyle: TextStyle(
                            color: isSelected ? RaftarColors.white : RaftarColors.navy,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedTab = tab);
                              _fetchDrivers();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Driver List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _drivers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.no_accounts_rounded, size: 48, color: RaftarColors.textTertiary),
                            const SizedBox(height: RaftarSpacing.md),
                            Text(
                              'No drivers found matching "$_selectedTab"',
                              style: const TextStyle(color: RaftarColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchDrivers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(RaftarSpacing.xl),
                          itemCount: _drivers.length,
                          separatorBuilder: (context, _) => const SizedBox(height: RaftarSpacing.md),
                          itemBuilder: (context, index) {
                            final driver = _drivers[index];
                            final id = driver['id'] as String;
                            final name = driver['fullName'] as String? ?? 'Driver';
                            final phone = driver['phone'] as String? ?? '';
                            final vehicle = driver['vehicleType'] as String? ?? '';
                            final plate = driver['vehiclePlate'] as String? ?? '';
                            final status = driver['status'] as String? ?? 'ACTIVE';
                            final rating = (driver['rating'] as num?)?.toDouble() ?? 5.0;
                            final isPending = status == 'PENDING_APPROVAL';

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                                side: BorderSide(
                                  color: isPending
                                      ? RaftarColors.warning.withValues(alpha: 0.8)
                                      : RaftarColors.border,
                                  width: isPending ? 1.5 : 1.0,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                                onTap: () => context.go('${AdminRoutes.drivers}/$id'),
                                child: Padding(
                                  padding: const EdgeInsets.all(RaftarSpacing.lg),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: isPending
                                            ? RaftarColors.warning.withValues(alpha: 0.15)
                                            : RaftarColors.primaryContainer,
                                        child: Text(
                                          name.isNotEmpty ? name[0] : 'D',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isPending ? Colors.orange.shade800 : RaftarColors.primary,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: RaftarSpacing.lg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: RaftarSpacing.sm),
                                                _StatusBadge(status: status),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$phone • $vehicle ($plate)',
                                              style: const TextStyle(
                                                color: RaftarColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$rating',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                                ),
                                                const SizedBox(width: RaftarSpacing.md),
                                                Expanded(
                                                  child: Text(
                                                    'License: ${driver['licenseNumber'] ?? 'N/A'}',
                                                    style: const TextStyle(
                                                      color: RaftarColors.textTertiary,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: RaftarColors.textTertiary),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status;
    switch (status) {
      case 'PENDING_APPROVAL':
        bg = RaftarColors.warning.withValues(alpha: 0.15);
        fg = Colors.orange.shade900;
        label = 'Pending KYC';
      case 'ACTIVE':
        bg = RaftarColors.success.withValues(alpha: 0.15);
        fg = RaftarColors.success;
        label = 'Active';
      case 'SUSPENDED':
        bg = RaftarColors.error.withValues(alpha: 0.15);
        fg = RaftarColors.error;
        label = 'Suspended';
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
