import 'package:flutter_test/flutter_test.dart';

import 'package:xroneadminpanel/app/app.dart';
import 'package:xroneadminpanel/app/routing/app_routes.dart';
import 'package:xroneadminpanel/core/constants/navigation_items.dart';

void main() {
  testWidgets('app starts on login route', (WidgetTester tester) async {
    await tester.pumpWidget(const XroneAdminPanelApp());
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Forgot Password'), findsOneWidget);
  });

  testWidgets('login does not expose dashboard without credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const XroneAdminPanelApp());
    await tester.pump();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back 👋'), findsNothing);
    expect(find.text('Enter admin email and password.'), findsOneWidget);
  });

  test('foundation exposes configured navigation routes', () {
    final navigationRoutes = NavigationItems.values.map((item) => item.route);

    expect(navigationRoutes, contains(AppRoutes.users));
    expect(navigationRoutes, contains(AppRoutes.pilots));
    expect(navigationRoutes, contains(AppRoutes.payments));
    expect(navigationRoutes, contains(AppRoutes.tracking));
  });
}
