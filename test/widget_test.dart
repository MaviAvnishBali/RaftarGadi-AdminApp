import 'package:admin_app/app/admin_app.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

class _InMemoryStore implements KeyValueStore {
  final Map<String, Object?> _data = {};

  @override
  T? read<T>(String key) => _data[key] as T?;
  @override
  Future<void> write<T>(String key, T value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> clear() async => _data.clear();
  @override
  bool containsKey(String key) => _data.containsKey(key);
  @override
  List<String> get keys => _data.keys.toList();
}

const _env = AppEnvironment(
  flavor: AppFlavor.development,
  apiBaseUrl: 'http://localhost:8080',
  simulatedLatency: Duration.zero,
);

void main() {
  testWidgets('Admin app boots to splash and login screen', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _InMemoryStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(_env),
          cacheStoreProvider.overrideWithValue(store),
        ],
        child: const RaftarAdminApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(RaftarLogo), findsWidgets);

    // Settle past splash delay
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Admin Operations Console'), findsOneWidget);
    expect(find.text('Sign In to Console'), findsOneWidget);
    expect(find.text('Quick Demo Access'), findsOneWidget);
  });

  testWidgets('Quick demo login navigates to Overview console', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _InMemoryStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(_env),
          cacheStoreProvider.overrideWithValue(store),
        ],
        child: const RaftarAdminApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Tap Quick Demo Access
    await tester.tap(find.text('Quick Demo Access'));
    await tester.pumpAndSettle();

    // Verifies Operations Dashboard
    expect(find.text('Operations Dashboard'), findsOneWidget);
    expect(find.text("Today's Revenue"), findsOneWidget);
    expect(find.text('Pending KYC'), findsOneWidget);
    expect(find.text('Recent Booking Activity'), findsOneWidget);
  });
}
