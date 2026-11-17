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
    try {
      await Future.wait([
        ref
            .read(adminSessionControllerProvider.notifier)
            .bootstrap()
            .timeout(const Duration(seconds: 2), onTimeout: () {
              ref.read(adminSessionControllerProvider.notifier).setUnauthenticated();
            }),
        Future<void>.delayed(const Duration(milliseconds: 1200)),
      ]);
    } catch (_) {
      ref.read(adminSessionControllerProvider.notifier).setUnauthenticated();
    }

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
      backgroundColor: RaftarColors.navyDark,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const RaftarLogo(
                height: 110,
                onNavyPanel: true,
                showTagline: true,
              ),
              const Spacer(flex: 2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: RaftarSpacing.xl),
                child: RaftarHeroTruck(height: 150, isDark: true),
              ),
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RaftarSpacing.md,
                  vertical: RaftarSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: RaftarColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RaftarColors.green.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'ADMIN OPERATIONS CONSOLE',
                  style: TextStyle(
                    color: RaftarColors.green,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: RaftarSpacing.xl),
              const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor: AlwaysStoppedAnimation(RaftarColors.green),
                ),
              ),
              const SizedBox(height: RaftarSpacing.sm),
              Text(
                'Loading Console...',
                style: RaftarTypography.textTheme.bodySmall?.copyWith(
                  color: RaftarColors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: RaftarSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
