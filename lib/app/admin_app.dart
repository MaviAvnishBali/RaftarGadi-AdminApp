import 'package:admin_app/app/router/app_router.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RaftarAdminApp extends ConsumerWidget {
  const RaftarAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'Raftar Gaddi Admin',
      debugShowCheckedModeBanner: false,
      theme: RaftarTheme.light,
      routerConfig: router,
    );
  }
}
