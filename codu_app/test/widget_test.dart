import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codu_app/main.dart';
import 'package:codu_app/views/login_screen.dart';

void main() {
  testWidgets('Login Screen initial state and tab switching smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify we are on the login screen and the email input field is present.
    // In initial state (Sign In):
    // - LOG IN tab + LOG IN button = 2 widgets
    // - REGISTER tab = 1 widget
    expect(find.text('LOG IN'), findsNWidgets(2));
    expect(find.text('REGISTER'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email Address'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    // Tap the REGISTER tab
    await tester.tap(find.text('REGISTER'));
    await tester.pumpAndSettle();

    // In Register state:
    // - REGISTER tab + REGISTER button = 2 widgets
    // - LOG IN tab = 1 widget
    expect(find.text('REGISTER'), findsNWidgets(2));
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm Password'), findsOneWidget);

    // Tap LOG IN tab to go back
    await tester.tap(find.text('LOG IN'));
    await tester.pumpAndSettle();

    // Tap Forgot Password link
    expect(find.text('Forgot Password?'), findsOneWidget);
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    // Verify Forgot Password screen is shown
    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('SEND LINK'), findsOneWidget);
  });
}
