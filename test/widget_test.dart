import 'package:flutter_test/flutter_test.dart';
import 'package:stallconnect_stall_owner/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LetsKonnectApp());
    await tester.pump(const Duration(milliseconds: 500));
    // Splash screen should render the logo image
    expect(find.byType(LetsKonnectApp), findsOneWidget);
  });
}
