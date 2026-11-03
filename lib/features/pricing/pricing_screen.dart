import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repositories/repositories.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  double _currentSurge = 1.0;
  bool _updatingSurge = false;
  bool _loading = false;
  List<Map<String, dynamic>> _rules = [];
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final _multipliers = [1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _fetchRules();
  }

  Future<void> _fetchRules() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.getPricingRules();
    if (!mounted) return;
    res.match(
      (_) => setState(() => _loading = false),
      (list) => setState(() {
        _rules = list;
        if (list.isNotEmpty) {
          final s = (list.first['surgeMultiplier'] as num?)?.toDouble();
          if (s != null && s > 0) {
            _currentSurge = s;
          }
        }
        _loading = false;
      }),
    );
  }

  Future<void> _updateSurge(double multiplier) async {
    setState(() => _updatingSurge = true);
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.setSurge(multiplier: multiplier);
    if (!mounted) return;
    setState(() {
      _currentSurge = multiplier;
      _updatingSurge = false;
    });

    res.match(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update surge: ${err.message}'), backgroundColor: RaftarColors.error),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Live Surge Multiplier set to ${multiplier}x across active zones.'),
            backgroundColor: RaftarColors.success,
          ),
        );
        _fetchRules();
      },
    );
  }

  void _showCustomSurgeDialog() {
    final controller = TextEditingController(text: _currentSurge.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Surge Multiplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter surge multiplier between 1.0x and 5.0x:'),
            const SizedBox(height: RaftarSpacing.md),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Multiplier (e.g. 1.3, 1.8, 2.5)',
                suffixText: 'x',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RaftarColors.primary),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 1.0 && val <= 5.0) {
                Navigator.pop(ctx);
                _updateSurge(val);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid multiplier (1.0 to 5.0)')),
                );
              }
            },
            child: const Text('Apply', style: TextStyle(color: RaftarColors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditSpecsDialog(Map<String, dynamic> rule) {
    final vTypeObj = rule['vehicleType'] is Map ? (rule['vehicleType'] as Map) : null;
    final vName = (vTypeObj?['name'] ?? rule['vehicleType'] ?? 'Vehicle').toString();
    final ruleId = rule['id']?.toString() ?? '';

    final baseFareController = TextEditingController(
      text: ((rule['baseFare'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    final perKmController = TextEditingController(
      text: (((rule['perKmCharge'] ?? rule['perKmRate']) as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    final perMinController = TextEditingController(
      text: (((rule['perMinCharge'] ?? rule['perMinRate']) as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    final dimensionsController = TextEditingController(
      text: (vTypeObj?['dimensions'] ?? rule['dimensions'] ?? '').toString(),
    );
    final maxWeightController = TextEditingController(
      text: ((vTypeObj?['maxWeightKg'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaftarRadii.lg)),
              title: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: RaftarColors.primary),
                  const SizedBox(width: RaftarSpacing.sm),
                  Expanded(
                    child: Text(
                      'Edit $vName Rates',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Update base rates, per km rates, and cargo dimensions.',
                      style: TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: RaftarSpacing.lg),
                    TextField(
                      controller: baseFareController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Base Fare (₹)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: perKmController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Per Km Rate',
                              suffixText: '₹/km',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: perMinController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Per Min Rate',
                              suffixText: '₹/min',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    TextField(
                      controller: dimensionsController,
                      decoration: const InputDecoration(
                        labelText: 'Cargo Dimensions',
                        hintText: 'e.g. 7ft x 4.8ft x 4.8ft',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    TextField(
                      controller: maxWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Max Payload Capacity',
                        suffixText: 'kg',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RaftarColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final baseFare = double.tryParse(baseFareController.text.trim());
                          final perKm = double.tryParse(perKmController.text.trim());
                          final perMin = double.tryParse(perMinController.text.trim());
                          final dimensions = dimensionsController.text.trim();
                          final maxWeight = double.tryParse(maxWeightController.text.trim());

                          if (baseFare == null || perKm == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid Base Fare and Per Km Rate.')),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          final repo = ref.read(adminRepositoryProvider);
                          final res = await repo.updatePricingRule(
                            ruleId: ruleId,
                            baseFare: baseFare,
                            perKmCharge: perKm,
                            perMinCharge: perMin,
                            dimensions: dimensions.isNotEmpty ? dimensions : null,
                            maxWeightKg: maxWeight,
                          );

                          if (!mounted) return;
                          res.match(
                            (err) {
                              setDialogState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: ${err.message}'), backgroundColor: RaftarColors.error),
                              );
                            },
                            (_) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Updated $vName rates and dimensions!'),
                                  backgroundColor: RaftarColors.success,
                                ),
                              );
                              _fetchRules();
                            },
                          );
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(color: RaftarColors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddVehicleDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxWeightController = TextEditingController();
    final dimensionsController = TextEditingController();
    final baseFareController = TextEditingController(text: '150');
    final perKmController = TextEditingController(text: '20');
    final perMinController = TextEditingController(text: '2');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaftarRadii.lg)),
              title: Row(
                children: const [
                  Icon(Icons.add_circle_outline_rounded, color: RaftarColors.primary),
                  SizedBox(width: RaftarSpacing.sm),
                  Text('Add New Vehicle Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create a new fleet category with specifications and base pricing.',
                      style: TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: RaftarSpacing.lg),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Category Name',
                        hintText: 'e.g. E-Rickshaw Cargo, Tata Yodha',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g. Eco-friendly city deliveries',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: maxWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Max Payload',
                              suffixText: 'kg',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: dimensionsController,
                            decoration: const InputDecoration(
                              labelText: 'Dimensions',
                              hintText: '5ft x 4ft x 4ft',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: baseFareController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Base Fare',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: perKmController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Per Km Rate',
                              suffixText: '₹/km',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    TextField(
                      controller: perMinController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Per Min Rate',
                        suffixText: '₹/min',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RaftarColors.primary,
                    foregroundColor: RaftarColors.white,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final maxWeight = double.tryParse(maxWeightController.text.trim());
                          final baseFare = double.tryParse(baseFareController.text.trim());
                          final perKm = double.tryParse(perKmController.text.trim());
                          final perMin = double.tryParse(perMinController.text.trim()) ?? 0.0;

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a vehicle category name')),
                            );
                            return;
                          }
                          if (maxWeight == null || maxWeight <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid payload capacity (kg)')),
                            );
                            return;
                          }
                          if (baseFare == null || perKm == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid base and per km rates')),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          final repo = ref.read(adminRepositoryProvider);
                          final res = await repo.createVehicleType(
                            name: name,
                            description: descriptionController.text.trim().isNotEmpty
                                ? descriptionController.text.trim()
                                : null,
                            maxWeightKg: maxWeight,
                            dimensions: dimensionsController.text.trim().isNotEmpty
                                ? dimensionsController.text.trim()
                                : null,
                            baseFare: baseFare,
                            perKmCharge: perKm,
                            perMinCharge: perMin,
                          );

                          if (!mounted) return;
                          setDialogState(() => saving = false);

                          res.match(
                            (err) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add vehicle: ${err.message}'),
                                  backgroundColor: RaftarColors.error,
                                ),
                              );
                            },
                            (_) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Vehicle category "$name" created successfully!'),
                                  backgroundColor: RaftarColors.success,
                                ),
                              );
                              _fetchRules();
                            },
                          );
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: RaftarColors.white),
                        )
                      : const Text('Add Vehicle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Pricing & Surge Control'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RaftarSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Surge Multiplier Controller Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                side: BorderSide(
                  color: _currentSurge > 1.0 ? RaftarColors.warning : RaftarColors.border,
                  width: _currentSurge > 1.0 ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RaftarSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.bolt_rounded, color: RaftarColors.warning, size: 28),
                              const SizedBox(width: RaftarSpacing.sm),
                              Flexible(
                                child: Text(
                                  'Live Surge Multiplier',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentSurge > 1.0
                                ? RaftarColors.warning.withValues(alpha: 0.2)
                                : RaftarColors.primaryContainer,
                            borderRadius: BorderRadius.circular(RaftarRadii.sm),
                          ),
                          child: Text(
                            'Active: ${_currentSurge}x',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _currentSurge > 1.0 ? Colors.orange.shade900 : RaftarColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RaftarSpacing.sm),
                    const Text(
                      'Dynamically adjust trip fares across high-demand logistics zones during peak delivery hours.',
                      style: TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: RaftarSpacing.xl),
                    Row(
                      children: _multipliers.map((m) {
                        final isSelected = _currentSurge == m;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? RaftarColors.navy : RaftarColors.surfaceMuted,
                                foregroundColor: isSelected ? RaftarColors.white : RaftarColors.navy,
                                elevation: isSelected ? 2 : 0,
                                side: BorderSide(color: isSelected ? RaftarColors.navy : RaftarColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _updatingSurge ? null : () => _updateSurge(m),
                              child: Column(
                                children: [
                                  Text('${m}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text(
                                    m == 1.0
                                        ? 'Normal'
                                        : (m == 1.25 ? 'Moderate' : (m == 1.5 ? 'Busy' : 'Peak Surge')),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected ? RaftarColors.accent : RaftarColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: RaftarSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        label: Text(_multipliers.contains(_currentSurge)
                            ? 'Set Custom Surge Multiplier'
                            : 'Custom Surge Active (${_currentSurge}x) — Tap to Change'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RaftarColors.primary,
                          side: BorderSide(
                            color: _multipliers.contains(_currentSurge) ? RaftarColors.border : RaftarColors.primary,
                            width: _multipliers.contains(_currentSurge) ? 1.0 : 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _updatingSurge ? null : _showCustomSurgeDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RaftarSpacing.xl),

            // Base Pricing Table per Vehicle Type
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fleet Base Rates & Dimensions',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: RaftarSpacing.xs),
                              const Text(
                                'Standard logistics fare calculation rules configured for the platform.',
                                style: TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: RaftarSpacing.sm),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Vehicle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RaftarColors.primary,
                            foregroundColor: RaftarColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaftarRadii.md)),
                          ),
                          onPressed: _showAddVehicleDialog,
                        ),
                      ],
                    ),
                    const Divider(height: RaftarSpacing.xl),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _rules.length,
                        separatorBuilder: (context, _) => const Divider(height: RaftarSpacing.lg),
                        itemBuilder: (context, index) {
                          final r = _rules[index];
                          final vTypeObj = r['vehicleType'] is Map ? (r['vehicleType'] as Map) : null;
                          final vType = (vTypeObj?['name'] ?? vTypeObj?['displayName'] ?? r['vehicleType'] ?? 'Vehicle').toString();
                          final base = (r['baseFare'] as num?)?.toDouble() ?? 0.0;
                          final perKm = ((r['perKmCharge'] ?? r['perKmRate']) as num?)?.toDouble() ?? 0.0;
                          final perMin = ((r['perMinCharge'] ?? r['perMinRate']) as num?)?.toDouble() ?? 0.0;
                          final maxWeight = vTypeObj?['maxWeightKg'];
                          final capacity = maxWeight != null
                              ? '$maxWeight kg'
                              : (vTypeObj?['capacity'] ?? r['capacity'] ?? 'Standard');
                          final dimensions = (vTypeObj?['dimensions'] ?? r['dimensions'] ?? '').toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: RaftarColors.primaryContainer,
                                  child: Icon(
                                    vType.contains('Bike')
                                        ? Icons.two_wheeler_rounded
                                        : (vType.contains('Auto') || vType.contains('3-Wheeler')
                                            ? Icons.electric_rickshaw_rounded
                                            : Icons.local_shipping_rounded),
                                    color: RaftarColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: RaftarSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vType,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Payload: $capacity',
                                        style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 12),
                                      ),
                                      if (dimensions.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.aspect_ratio_rounded, size: 13, color: RaftarColors.primary),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                dimensions,
                                                style: const TextStyle(color: RaftarColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: RaftarColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: RaftarColors.border),
                                            ),
                                            child: Text(
                                              'Base: ${_currency.format(base)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: RaftarColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: RaftarColors.border),
                                            ),
                                            child: Text(
                                              '${_currency.format(perKm)}/km • ${_currency.format(perMin)}/min',
                                              style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: RaftarSpacing.xs),
                                IconButton.outlined(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Edit Rates & Specs',
                                  style: IconButton.styleFrom(
                                    foregroundColor: RaftarColors.primary,
                                    side: const BorderSide(color: RaftarColors.border),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  onPressed: () => _showEditSpecsDialog(r),
                                ),
                              ],
                            ),
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
