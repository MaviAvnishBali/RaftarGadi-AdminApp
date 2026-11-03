import 'package:admin_app/app/router/routes.dart';
import 'package:admin_app/session/admin_session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repositories/repositories.dart';
import 'package:shared_widgets/shared_widgets.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _pendingKycCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPendingCount();
  }

  Future<void> _fetchPendingCount() async {
    final result = await ref.read(adminRepositoryProvider).getOverview();
    if (!mounted) return;
    result.match(
      (_) {},
      (stats) {
        setState(() {
          _pendingKycCount = (stats['pendingVerifications'] as num?)?.toInt() ?? 0;
        });
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AdminRoutes.drivers)) return 1;
    if (location.startsWith(AdminRoutes.bookings)) return 2;
    if (location.startsWith(AdminRoutes.customers)) return 3;
    if (location.startsWith(AdminRoutes.pricing)) return 4;
    if (location.startsWith(AdminRoutes.serviceableAreas)) return 5;
    if (location.startsWith(AdminRoutes.analytics)) return 6;
    if (location.startsWith(AdminRoutes.support)) return 7;
    return 0; // overview
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AdminRoutes.overview);
      case 1:
        context.go(AdminRoutes.drivers);
      case 2:
        context.go(AdminRoutes.bookings);
      case 3:
        context.go(AdminRoutes.customers);
      case 4:
        context.go(AdminRoutes.pricing);
      case 5:
        context.go(AdminRoutes.serviceableAreas);
      case 6:
        context.go(AdminRoutes.analytics);
      case 7:
        context.go(AdminRoutes.support);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(adminSessionControllerProvider);
    final user = session.user;
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final navItems = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Overview', route: AdminRoutes.overview),
      _NavItem(
        icon: Icons.badge_rounded,
        label: 'Drivers & KYC',
        route: AdminRoutes.drivers,
        badge: _pendingKycCount > 0 ? '$_pendingKycCount' : null,
      ),
      _NavItem(icon: Icons.local_shipping_rounded, label: 'Bookings', route: AdminRoutes.bookings),
      _NavItem(icon: Icons.people_alt_rounded, label: 'Customers', route: AdminRoutes.customers),
      _NavItem(icon: Icons.price_change_rounded, label: 'Pricing & Surge', route: AdminRoutes.pricing),
      _NavItem(icon: Icons.location_city_rounded, label: 'Service Areas', route: AdminRoutes.serviceableAreas),
      _NavItem(icon: Icons.analytics_rounded, label: 'Analytics', route: AdminRoutes.analytics),
      _NavItem(icon: Icons.support_agent_rounded, label: 'Support Chats', route: AdminRoutes.support),
    ];

    if (!isDesktop) {
      // Mobile / Tablet Drawer Layout
      return DoubleBackExitScope(
        onBack: () {
          if (selectedIndex != 0) {
            _onItemTapped(0, context);
            return true;
          }
          return false;
        },
        child: Scaffold(
        appBar: AppBar(
          backgroundColor: RaftarColors.navy,
          foregroundColor: RaftarColors.white,
          title: Row(
            children: [
              const RaftarLogo(height: 28, onNavyPanel: false),
              const SizedBox(width: RaftarSpacing.sm),
              const Text(
                'Admin Console',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: RaftarColors.navy,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: RaftarColors.navyDark),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const RaftarLogo(height: 52, onNavyPanel: false),
                        const SizedBox(height: RaftarSpacing.sm),
                        Text(
                          user?.name ?? 'Admin',
                          style: const TextStyle(color: RaftarColors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.role ?? 'OPERATOR',
                          style: const TextStyle(color: RaftarColors.accent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: navItems.length,
                    itemBuilder: (context, idx) {
                      final item = navItems[idx];
                      final isSelected = selectedIndex == idx;
                      return ListTile(
                        leading: Icon(
                          item.icon,
                          color: isSelected ? RaftarColors.primary : Colors.white70,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? RaftarColors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: item.badge != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RaftarColors.warning,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.badge!,
                                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor: RaftarColors.primary.withValues(alpha: 0.15),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onItemTapped(idx, context);
                        },
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: RaftarColors.error),
                  title: const Text('Sign Out', style: TextStyle(color: RaftarColors.error)),
                  onTap: () async {
                    await ref.read(adminSessionControllerProvider.notifier).signOut();
                    if (context.mounted) context.go(AdminRoutes.login);
                  },
                ),
                const SizedBox(height: RaftarSpacing.md),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: widget.child,
        ),
      ),
    );
    }

    // Desktop / Web Full Sidebar Layout
    return DoubleBackExitScope(
      onBack: () {
        if (selectedIndex != 0) {
          _onItemTapped(0, context);
          return true;
        }
        return false;
      },
      child: Scaffold(
        body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: RaftarColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RaftarSpacing.xl,
                    vertical: RaftarSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RaftarLogo(height: 48, onNavyPanel: false),
                      const SizedBox(height: RaftarSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: RaftarColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OPERATIONS CONSOLE',
                          style: TextStyle(
                            color: RaftarColors.accent,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: RaftarSpacing.md),

                // Nav Links
                Expanded(
                  child: ListView.builder(
                    itemCount: navItems.length,
                    itemBuilder: (context, idx) {
                      final item = navItems[idx];
                      final isSelected = selectedIndex == idx;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RaftarSpacing.md,
                          vertical: 2,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(RaftarRadii.md),
                            onTap: () => _onItemTapped(idx, context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: RaftarSpacing.md,
                                vertical: RaftarSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? RaftarColors.primary.withValues(alpha: 0.25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(RaftarRadii.md),
                                border: isSelected
                                    ? Border.all(color: RaftarColors.primary.withValues(alpha: 0.5))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected ? RaftarColors.accent : Colors.white70,
                                  ),
                                  const SizedBox(width: RaftarSpacing.md),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: isSelected ? RaftarColors.white : Colors.white70,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (item.badge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: RaftarColors.warning,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item.badge!,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                // Operator Profile Footer
                Padding(
                  padding: const EdgeInsets.all(RaftarSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: RaftarColors.primary,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0] : 'A',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: RaftarSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Admin',
                              style: const TextStyle(
                                color: RaftarColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.role ?? 'ADMIN',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Sign out',
                        onPressed: () async {
                          await ref.read(adminSessionControllerProvider.notifier).signOut();
                          if (context.mounted) context.go(AdminRoutes.login);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    ),
  );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String route;
  final String? badge;
}
