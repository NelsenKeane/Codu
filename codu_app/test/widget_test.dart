// This is a basic Flutter widget test for MyApp.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:codu_app/main.dart';

void main() {
  testWidgets('Login screen tab switching test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen starts with "Welcome Back !" in the speech bubble.
    expect(find.text('Welcome Back !'), findsOneWidget);
    expect(find.text('Lets Get Started !'), findsNothing);

    // Tap the 'REGISTER' tab and trigger a frame.
    await tester.tap(find.text('REGISTER'));
    await tester.pumpAndSettle();

    // Verify that the speech bubble updates to "Lets Get Started !".
    expect(find.text('Welcome Back !'), findsNothing);
    expect(find.text('Lets Get Started !'), findsOneWidget);

    // Tap the 'LOG IN' tab and trigger a frame.
    await tester.tap(find.text('LOG IN'));
    await tester.pumpAndSettle();

    // Verify that the speech bubble resets to "Welcome Back !".
    expect(find.text('Welcome Back !'), findsOneWidget);
    expect(find.text('Lets Get Started !'), findsNothing);
  });
}

