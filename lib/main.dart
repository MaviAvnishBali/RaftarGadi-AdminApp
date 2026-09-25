import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(AppEnvironment.development()),
      ],
      child: const RaftarAdminApp(),
    ),
  );
}

class RaftarAdminApp extends StatelessWidget {
  const RaftarAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raftar Gaddi Admin',
      debugShowCheckedModeBanner: false,
      theme: RaftarTheme.light,
      home: const _Phase2Home(app: 'Admin'),
    );
  }
}

class _Phase2Home extends ConsumerWidget {
  const _Phase2Home({required this.app});

  final String app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvironmentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RaftarSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: RaftarSpacing.lg),
            const Center(child: RaftarLogo(height: 84)),
            const SizedBox(height: RaftarSpacing.xxl),
            Text(
              '$app app',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: RaftarSpacing.xs),
            Text(
              'Design system preview • flavor ${env.flavor.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: RaftarSpacing.xl),
            RaftarCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sample booking',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const RaftarBadge(
                        label: 'IN TRANSIT',
                        status: RaftarStatus.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: RaftarSpacing.md),
                  Text(
                    'Koramangala → Indiranagar',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: RaftarSpacing.xl),
            RaftarButton(
              label: 'Primary action',
              icon: Icons.local_shipping_rounded,
              onPressed: () => RaftarFeedback.showSnackbar(
                context,
                message: 'Design system wired for the Admin app',
                status: RaftarStatus.success,
              ),
            ),
            const SizedBox(height: RaftarSpacing.md),
            RaftarButton(
              label: 'Secondary action',
              variant: RaftarButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
