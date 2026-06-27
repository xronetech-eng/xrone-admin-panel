import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xroneadminpanel/features/users/models/users_model.dart';
import 'package:xroneadminpanel/features/users/pages/users_screen.dart';
import 'package:xroneadminpanel/features/users/widgets/users_table.dart';

void main() {
  test('users screen search matches name, phone, and email partially', () {
    final users = [
      _user(index: 0, name: 'Nishant Kumar', phone: '9876543210'),
      _user(
        index: 1,
        name: 'Anika Rao',
        phone: '8123456789',
        email: 'anika@gmail.com',
      ),
      _user(index: 2, phone: '7000011111', email: 'rahul@yahoo.com'),
    ];

    expect(filterUsersForUsersScreen(users, 'Nish'), [users[0]]);
    expect(filterUsersForUsersScreen(users, '9876'), [users[0]]);
    expect(filterUsersForUsersScreen(users, 'GMAIL'), [users[1]]);
    expect(filterUsersForUsersScreen(users, '1111'), [users[2]]);
  });

  testWidgets('users table uses a virtualized scrolling row viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp(
            home: Scaffold(
              body: UsersTable(
                users: [
                  for (var index = 0; index < 12; index++) _user(index: index),
                ],
                selectedIndex: 0,
                onUserSelected: (_) {},
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('User 0'), findsOneWidget);
    expect(find.text('User 1'), findsOneWidget);
    expect(find.text('User 5'), findsNothing);
    expect(find.text('User 11'), findsNothing);

    await tester.drag(
      find.byType(ListView),
      Offset(0, -UsersTable.rowHeight.h),
    );
    await tester.pumpAndSettle();

    expect(find.text('User 0'), findsNothing);
    expect(find.text('User 5'), findsOneWidget);
  });
}

UserAdminViewData _user({
  required int index,
  String? name,
  String? phone,
  String? email,
}) {
  return UserAdminViewData(
    id: 'user-$index',
    profileLabel: 'U',
    name: name ?? 'User $index',
    phone: phone ?? '98760000$index',
    email: email ?? 'user$index@example.com',
    gender: 'Not specified',
    city: 'Not specified',
    bookingsCount: 0,
    latestBookingDate: '-',
    latestBookingStatus: '-',
    status: UserStatus.active,
    emergencyPhone: 'No phone',
    createdDate: '-',
    savedLocations: const [],
    bookingHistory: const [],
    paymentHistory: const [],
    offersUsed: const [],
    liveTracking: UserLiveTrackingData.empty,
  );
}
