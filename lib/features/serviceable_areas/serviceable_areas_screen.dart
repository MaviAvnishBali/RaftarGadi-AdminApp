import 'dart:math' as math;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repositories/repositories.dart';
import 'package:shared_models/shared_models.dart';

class ServiceableAreasScreen extends ConsumerStatefulWidget {
  const ServiceableAreasScreen({super.key});

  @override
  ConsumerState<ServiceableAreasScreen> createState() => _ServiceableAreasScreenState();
}

class _ServiceableAreasScreenState extends ConsumerState<ServiceableAreasScreen> {
  bool _loading = false;
  List<ServiceableArea> _areas = [];
  String _searchQuery = '';
  String _filter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'

  @override
  void initState() {
    super.initState();
    _fetchAreas();
  }

  Future<void> _fetchAreas() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.getServiceableAreas();
    if (!mounted) return;
    res.match(
      (err) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load operational areas: ${err.message}'),
            backgroundColor: RaftarColors.error,
          ),
        );
      },
      (list) {
        setState(() {
          _areas = list;
          _loading = false;
        });
      },
    );
  }

  Future<void> _toggleStatus(ServiceableArea area, bool isActive) async {
    // Optimistic UI update
    final prevList = List<ServiceableArea>.from(_areas);
    setState(() {
      _areas = _areas.map((a) => a.id == area.id ? a.copyWith(isActive: isActive) : a).toList();
    });

    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.toggleServiceableAreaStatus(area.id, isActive);
    if (!mounted) return;

    res.match(
      (err) {
        // Rollback
        setState(() => _areas = prevList);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle status: ${err.message}'),
            backgroundColor: RaftarColors.error,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Operational area "${area.name}" is now ACTIVE. Bookings enabled.'
                  : 'Operational area "${area.name}" is now DISABLED. Bookings blocked.',
            ),
            backgroundColor: isActive ? RaftarColors.success : RaftarColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Future<void> _deleteArea(ServiceableArea area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${area.name}"?'),
        content: Text(
          'Are you sure you want to permanently delete ${area.name}, ${area.state}?\n\n'
          'Customers in this zone will immediately be unable to book rides.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RaftarColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Area', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.deleteServiceableArea(area.id);
    if (!mounted) return;

    res.match(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete area: ${err.message}'),
            backgroundColor: RaftarColors.error,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Serviceable area "${area.name}" removed successfully.'),
            backgroundColor: RaftarColors.success,
          ),
        );
        _fetchAreas();
      },
    );
  }

  void _showAddAreaDialog() {
    _showAreaFormDialog(null);
  }

  void _showEditAreaDialog(ServiceableArea area) {
    _showAreaFormDialog(area);
  }

  void _showAreaFormDialog(ServiceableArea? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final stateCtrl = TextEditingController(text: existing?.state ?? '');
    final latCtrl = TextEditingController(text: existing != null ? existing.centerLat.toString() : '');
    final lngCtrl = TextEditingController(text: existing != null ? existing.centerLng.toString() : '');
    double radiusKm = existing?.radiusKm ?? 25.0;
    bool isActive = existing?.isActive ?? true;

    final presets = [
      {'name': 'Delhi NCR (Central)', 'state': 'Delhi NCR', 'lat': 28.6139, 'lng': 77.2090, 'r': 35.0},
      {'name': 'Noida', 'state': 'Uttar Pradesh', 'lat': 28.5355, 'lng': 77.3910, 'r': 25.0},
      {'name': 'Gurugram', 'state': 'Haryana', 'lat': 28.4595, 'lng': 77.0266, 'r': 30.0},
      {'name': 'Ghaziabad', 'state': 'Uttar Pradesh', 'lat': 28.6692, 'lng': 77.4538, 'r': 25.0},
      {'name': 'Mumbai', 'state': 'Maharashtra', 'lat': 19.0760, 'lng': 72.8777, 'r': 40.0},
      {'name': 'Bengaluru', 'state': 'Karnataka', 'lat': 12.9716, 'lng': 77.5946, 'r': 35.0},
      {'name': 'Hyderabad', 'state': 'Telangana', 'lat': 17.3850, 'lng': 78.4867, 'r': 30.0},
      {'name': 'Pune', 'state': 'Maharashtra', 'lat': 18.5204, 'lng': 73.8567, 'r': 25.0},
      {'name': 'Chandigarh', 'state': 'Punjab/Haryana', 'lat': 30.7333, 'lng': 76.7794, 'r': 20.0},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                  color: RaftarColors.primary,
                ),
                const SizedBox(width: RaftarSpacing.sm),
                Text(isEdit ? 'Edit Operational Area' : 'Add Serviceable City / Area'),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEdit) ...[
                      const Text(
                        'Quick City Presets:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: RaftarSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: presets.map((p) {
                          return ActionChip(
                            label: Text(p['name'] as String, style: const TextStyle(fontSize: 11)),
                            backgroundColor: RaftarColors.navyDark.withValues(alpha: 0.05),
                            onPressed: () {
                              setDialogState(() {
                                nameCtrl.text = p['name'] as String;
                                stateCtrl.text = p['state'] as String;
                                latCtrl.text = p['lat'].toString();
                                lngCtrl.text = p['lng'].toString();
                                radiusKm = (p['r'] as num).toDouble();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: RaftarSpacing.md),
                      const Divider(),
                    ],
                    const SizedBox(height: RaftarSpacing.sm),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City / Area Name *',
                        hintText: 'e.g. New Delhi, Noida, Mumbai Central',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city_rounded),
                      ),
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    TextField(
                      controller: stateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'State / Region *',
                        hintText: 'e.g. Delhi NCR, Uttar Pradesh, Maharashtra',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map_rounded),
                      ),
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Center Latitude *',
                              hintText: '28.6139',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Center Longitude *',
                              hintText: '77.2090',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RaftarSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Coverage Radius: ${radiusKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '~${(math.pi * radiusKm * radiusKm).toStringAsFixed(0)} km²',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    Slider(
                      value: radiusKm.clamp(5.0, 100.0),
                      min: 5.0,
                      max: 100.0,
                      divisions: 95,
                      label: '${radiusKm.toStringAsFixed(0)} km',
                      activeColor: RaftarColors.primary,
                      onChanged: (val) => setDialogState(() => radiusKm = val),
                    ),
                    const SizedBox(height: RaftarSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Accept Bookings in this Area (Active)'),
                      subtitle: Text(
                        isActive
                            ? 'Drivers can receive orders and customers can book.'
                            : 'Orders in this area will be blocked immediately.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: isActive,
                      activeThumbColor: RaftarColors.success,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RaftarColors.primary,
                  foregroundColor: RaftarColors.navy,
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final state = stateCtrl.text.trim();
                  final lat = double.tryParse(latCtrl.text.trim());
                  final lng = double.tryParse(lngCtrl.text.trim());

                  if (name.isEmpty || state.isEmpty || lat == null || lng == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid city name, state, and coordinates.'),
                        backgroundColor: RaftarColors.error,
                      ),
                    );
                    return;
                  }

                  Navigator.of(ctx).pop();

                  final repo = ref.read(adminRepositoryProvider);
                  if (isEdit) {
                    final res = await repo.updateServiceableArea(
                      id: existing.id,
                      name: name,
                      state: state,
                      centerLat: lat,
                      centerLng: lng,
                      radiusKm: radiusKm,
                      isActive: isActive,
                    );
                    if (!mounted) return;
                    res.match(
                      (err) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update area: ${err.message}'), backgroundColor: RaftarColors.error),
                      ),
                      (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Operational area "$name" updated.'), backgroundColor: RaftarColors.success),
                        );
                        _fetchAreas();
                      },
                    );
                  } else {
                    final res = await repo.createServiceableArea(
                      name: name,
                      state: state,
                      centerLat: lat,
                      centerLng: lng,
                      radiusKm: radiusKm,
                      isActive: isActive,
                    );
                    if (!mounted) return;
                    res.match(
                      (err) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add area: ${err.message}'), backgroundColor: RaftarColors.error),
                      ),
                      (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Serviceable area "$name" added.'), backgroundColor: RaftarColors.success),
                        );
                        _fetchAreas();
                      },
                    );
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Create Area'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<ServiceableArea> get _filteredAreas {
    return _areas.where((a) {
      if (_filter == 'ACTIVE' && !a.isActive) return false;
      if (_filter == 'INACTIVE' && a.isActive) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = a.name.toLowerCase().contains(q);
        final matchesState = a.state.toLowerCase().contains(q);
        return matchesName || matchesState;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _areas.where((a) => a.isActive).length;
    final inactiveCount = _areas.where((a) => !a.isActive).length;
    final totalKm = _areas.fold<double>(0, (sum, a) => sum + a.radiusKm);

    return Scaffold(
      backgroundColor: RaftarColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RaftarColors.primary,
        foregroundColor: RaftarColors.navy,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Service Area', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddAreaDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAreas,
        child: ListView(
          padding: const EdgeInsets.all(RaftarSpacing.xl),
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serviceable Areas Management',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: RaftarColors.navy,
                            ),
                      ),
                      const SizedBox(height: RaftarSpacing.xs),
                      Text(
                        'Configure operational cities, GPS boundaries, and radii to accept orders in authorized zones.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: RaftarSpacing.md),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Areas',
                  onPressed: _fetchAreas,
                ),
              ],
            ),
            const SizedBox(height: RaftarSpacing.lg),

            // Metrics Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final cards = [
                  _MetricCard(
                    title: 'Total Cities',
                    value: '${_areas.length}',
                    icon: Icons.location_city_rounded,
                    color: RaftarColors.navy,
                  ),
                  _MetricCard(
                    title: 'Active Zones',
                    value: '$activeCount',
                    icon: Icons.check_circle_rounded,
                    color: RaftarColors.success,
                    subtitle: 'Accepting bookings',
                  ),
                  _MetricCard(
                    title: 'Inactive / Paused',
                    value: '$inactiveCount',
                    icon: Icons.pause_circle_filled_rounded,
                    color: inactiveCount > 0 ? RaftarColors.warning : Colors.grey,
                    subtitle: 'Orders blocked',
                  ),
                  _MetricCard(
                    title: 'Coverage Hubs',
                    value: '${totalKm.toStringAsFixed(0)} km',
                    icon: Icons.radar_rounded,
                    color: RaftarColors.primary,
                    subtitle: 'Combined service radius',
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
                  );
                } else {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 8) / 2, child: c)).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: RaftarSpacing.xl),

            // Search & Filter Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final searchField = TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search operational city or state...',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                );

                final filterSegment = SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ALL', label: Text('All')),
                    ButtonSegment(value: 'ACTIVE', label: Text('Active')),
                    ButtonSegment(value: 'INACTIVE', label: Text('Inactive')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (val) => setState(() => _filter = val.first),
                );

                return RaftarCard(
                  padding: const EdgeInsets.all(RaftarSpacing.md),
                  child: isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            searchField,
                            const SizedBox(height: RaftarSpacing.sm),
                            filterSegment,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: RaftarSpacing.md),
                            filterSegment,
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: RaftarSpacing.lg),

            // Content List
            if (_loading && _areas.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredAreas.isEmpty)
              RaftarCard(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: RaftarSpacing.md),
                      const Text(
                        'No operational areas match your criteria.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: RaftarSpacing.sm),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_location_alt_rounded),
                        label: const Text('Add Serviceable City'),
                        onPressed: _showAddAreaDialog,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredAreas.map((area) {
                return _AreaCard(
                  area: area,
                  onToggleActive: (val) => _toggleStatus(area, val),
                  onEdit: () => _showEditAreaDialog(area),
                  onDelete: () => _deleteArea(area),
                );
              }),
            const SizedBox(height: 80), // Fab clearance
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return RaftarCard(
      padding: const EdgeInsets.all(RaftarSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RaftarRadii.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: RaftarSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: RaftarColors.navy,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final ServiceableArea area;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final areaSqKm = (math.pi * area.radiusKm * area.radiusKm).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: RaftarSpacing.md),
      child: RaftarCard(
        padding: const EdgeInsets.all(RaftarSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading City Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: area.isActive
                        ? RaftarColors.primary.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(RaftarRadii.md),
                    border: Border.all(
                      color: area.isActive ? RaftarColors.primary : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.location_city_rounded,
                      color: area.isActive ? RaftarColors.navy : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: RaftarSpacing.md),

                // City Name & State
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: RaftarSpacing.xs,
                        runSpacing: 4,
                        children: [
                          Text(
                            area.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: RaftarColors.navy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: RaftarColors.navyDark.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              area.state,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: RaftarColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (area.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: RaftarColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 11, color: RaftarColors.success),
                              SizedBox(width: 3),
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: RaftarColors.success,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: RaftarColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block_rounded, size: 11, color: RaftarColors.error),
                              SizedBox(width: 3),
                              Text(
                                'DISABLED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: RaftarColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      area.isActive ? 'Accepting' : 'Blocked',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: area.isActive ? RaftarColors.success : RaftarColors.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: area.isActive,
                      activeThumbColor: RaftarColors.success,
                      onChanged: onToggleActive,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: RaftarSpacing.lg),

            // Bottom Row: Radius, Coordinates & Edit/Delete Actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radar_rounded, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Radius: ${area.radiusKm} km (~$areaSqKm km²)',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fmd_good_rounded, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Center: ${area.centerLat.toStringAsFixed(4)}, ${area.centerLng.toStringAsFixed(4)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: RaftarColors.navy, size: 20),
                  tooltip: 'Edit Area',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: RaftarColors.error, size: 20),
                  tooltip: 'Delete Area',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
