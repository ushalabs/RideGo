import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridego/app/app.dart';
import 'package:ridego/core/widgets/ridego_logo.dart';

void main() {
  testWidgets('RideGo app loads splash and navigates to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RideGoApp()));

    // Verify RideGoLogo widget is present on splash
    expect(find.byType(RideGoLogo), findsOneWidget);
    expect(find.text('Samar & Leyte Transit Booking'), findsOneWidget);

    // Advance timer past splash duration
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify Login Screen reached
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
  });
}
