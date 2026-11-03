import 'package:admin_app/features/serviceable_areas/serviceable_areas_screen.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repositories/repositories.dart';
import 'package:shared_models/shared_models.dart';

class _FakeAdminRepository implements AdminRepository {
  List<ServiceableArea> areas = [
    const ServiceableArea(
      id: 'area-1',
      name: 'New Delhi',
      state: 'Delhi NCR',
      centerLat: 28.6139,
      centerLng: 77.2090,
      radiusKm: 35.0,
      isActive: true,
    ),
    const ServiceableArea(
      id: 'area-2',
      name: 'Mumbai',
      state: 'Maharashtra',
      centerLat: 19.0760,
      centerLng: 72.8777,
      radiusKm: 40.0,
      isActive: false,
    ),
  ];

  bool toggleCalled = false;
  String? toggledId;
  bool? toggledState;

  @override
  Future<Result<List<ServiceableArea>>> getServiceableAreas({bool? onlyActive}) async {
    if (onlyActive == true) {
      return success(areas.where((a) => a.isActive).toList());
    }
    return success(areas);
  }

  @override
  Future<Result<void>> toggleServiceableAreaStatus(String id, bool isActive) async {
    toggleCalled = true;
    toggledId = id;
    toggledState = isActive;
    areas = areas.map((a) => a.id == id ? a.copyWith(isActive: isActive) : a).toList();
    return success(null);
  }

  @override
  Future<Result<ServiceableArea>> createServiceableArea({
    required String name,
    required String state,
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    bool isActive = true,
  }) async {
    final newArea = ServiceableArea(
      id: 'area-new',
      name: name,
      state: state,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
      isActive: isActive,
    );
    areas.add(newArea);
    return success(newArea);
  }

  @override
  Future<Result<ServiceableArea>> updateServiceableArea({
    required String id,
    String? name,
    String? state,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    bool? isActive,
  }) async {
    final idx = areas.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final updated = areas[idx].copyWith(
        name: name,
        state: state,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
        isActive: isActive,
      );
      areas[idx] = updated;
      return success(updated);
    }
    return failure(const NotFoundFailure('Area not found'));
  }

  @override
  Future<Result<void>> deleteServiceableArea(String id) async {
    areas.removeWhere((a) => a.id == id);
    return success(null);
  }

  @override
  Future<Result<Map<String, dynamic>>> checkServiceability(double lat, double lng) async {
    return success({'isServiceable': true});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ServiceableAreasScreen renders list, metrics, and handles toggle', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepo = _FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ServiceableAreasScreen(),
        ),
      ),
    );

    // Initial load
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify Title & Metrics
    expect(find.text('Serviceable Areas Management'), findsOneWidget);
    expect(find.text('Total Cities'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // 2 total areas
    expect(find.text('Active Zones'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2)); // 1 active, 1 inactive

    // Verify Area Cards
    expect(find.text('New Delhi'), findsOneWidget);
    expect(find.text('Delhi NCR'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    expect(find.text('Mumbai'), findsOneWidget);
    expect(find.text('Maharashtra'), findsOneWidget);
    expect(find.text('DISABLED'), findsOneWidget);

    // Tap switch on Mumbai to activate it
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));
    await tester.tap(switches.last);
    await tester.pumpAndSettle();

    expect(fakeRepo.toggleCalled, isTrue);
    expect(fakeRepo.toggledId, 'area-2');
    expect(fakeRepo.toggledState, isTrue);

    // Verify FAB "Add Service Area" opens dialog
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.text('Add Serviceable City / Area'), findsOneWidget);
    expect(find.text('City / Area Name *'), findsOneWidget);
    expect(find.text('State / Region *'), findsOneWidget);
    expect(find.text('Center Latitude *'), findsOneWidget);
    expect(find.text('Center Longitude *'), findsOneWidget);
  });
}
