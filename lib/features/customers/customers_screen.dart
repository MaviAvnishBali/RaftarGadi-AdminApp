import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repositories/repositories.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  bool _loading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _loading = true);
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.getCustomers(search: _searchQuery);
    if (!mounted) return;
    res.match(
      (_) => setState(() => _loading = false),
      (list) => setState(() {
        _customers = list;
        _loading = false;
      }),
    );
  }

  Future<void> _toggleUserStatus(String id, String name, bool currentActive) async {
    final action = currentActive ? 'deactivate' : 'activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${currentActive ? 'Deactivate' : 'Activate'} Customer?'),
        content: Text(
          'Are you sure you want to $action account for $name? '
          '${currentActive ? 'They will not be able to book new trips.' : 'Their account access will be restored.'}',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentActive ? RaftarColors.error : RaftarColors.success,
            ),
            child: Text(
              currentActive ? 'Deactivate' : 'Activate',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(adminRepositoryProvider);
    await repo.manageUser(id, action);
    _fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaftarColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Customer Directory'),
        backgroundColor: RaftarColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh customers',
            onPressed: _fetchCustomers,
          ),
          const SizedBox(width: RaftarSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: RaftarColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: RaftarSpacing.xl,
              vertical: RaftarSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _fetchCustomers();
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
                _fetchCustomers();
              },
            ),
          ),

          const Divider(height: 1),

          // Customers List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? const Center(child: Text('No customers found.'))
                    : RefreshIndicator(
                        onRefresh: _fetchCustomers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(RaftarSpacing.xl),
                          itemCount: _customers.length,
                          separatorBuilder: (context, _) => const SizedBox(height: RaftarSpacing.md),
                          itemBuilder: (context, index) {
                            final c = _customers[index];
                            final id = c['id'] as String;
                            final name = c['fullName'] as String? ?? 'Customer';
                            final phone = c['phone'] as String? ?? '';
                            final email = c['email'] as String? ?? 'No email';
                            final rides = c['totalBookings'] as num? ?? 0;
                            final isActive = c['isActive'] as bool? ?? true;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(RaftarRadii.lg),
                                side: const BorderSide(color: RaftarColors.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(RaftarSpacing.lg),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: RaftarColors.primaryContainer,
                                      child: Text(
                                        name.isNotEmpty ? name[0] : 'C',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: RaftarColors.primary,
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
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? RaftarColors.success.withValues(alpha: 0.15)
                                                      : RaftarColors.error.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isActive ? 'Active' : 'Suspended',
                                                  style: TextStyle(
                                                    color: isActive ? RaftarColors.success : RaftarColors.error,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$phone • $email',
                                            style: const TextStyle(color: RaftarColors.textSecondary, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$rides completed moves',
                                            style: const TextStyle(color: RaftarColors.textTertiary, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                        color: isActive ? RaftarColors.error : RaftarColors.success,
                                      ),
                                      tooltip: isActive ? 'Deactivate customer' : 'Activate customer',
                                      onPressed: () => _toggleUserStatus(id, name, isActive),
                                    ),
                                  ],
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
