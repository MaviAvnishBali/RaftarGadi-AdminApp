import 'dart:async';
import 'package:admin_app/app/router/routes.dart';
import 'package:admin_app/session/admin_session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await ref.read(adminSessionControllerProvider.notifier).bootstrap();
    if (!mounted) return;

    final session = ref.read(adminSessionControllerProvider);
    if (session.isAuthenticated) {
      context.go(AdminRoutes.overview);
    } else {
      context.go(AdminRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RaftarColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RaftarLogo(height: 110, onNavyPanel: false),
            const SizedBox(height: RaftarSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RaftarSpacing.md,
                vertical: RaftarSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: RaftarColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(RaftarRadii.sm),
                border: Border.all(color: RaftarColors.primary),
              ),
              child: Text(
                'ADMIN CONSOLE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: RaftarColors.white,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
