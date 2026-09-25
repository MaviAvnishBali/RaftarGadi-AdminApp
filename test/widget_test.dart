import 'package:admin_app/main.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Admin app renders themed home with brand components', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(
            AppEnvironment.development(),
          ),
        ],
        child: const RaftarAdminApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(RaftarAdminApp), findsOneWidget);
    expect(find.byType(RaftarLogo), findsOneWidget);
    expect(find.byType(RaftarButton), findsWidgets);
    expect(find.text('Admin app'), findsOneWidget);
  });
}
