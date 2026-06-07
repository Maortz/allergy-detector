import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/user_profile.dart';
import 'package:app/widgets/profile_edit_sheet.dart';

void main() {
  // Pumps a host whose button opens the profile-edit sheet, capturing the
  // UserProfile the sheet returns (null if dismissed without saving).
  Future<UserProfile?> openSheet(
    WidgetTester tester, {
    required UserProfile current,
  }) async {
    UserProfile? result;
    var resolved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showProfileEditSheet(context, current);
                resolved = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Caller drives interactions; `resolved` lets us assert later if needed.
    expect(resolved, isFalse);
    return result;
  }

  const base = UserProfile(displayName: 'דנה');

  Finder emailField() => find.byType(TextFormField);
  Finder saveButton() => find.widgetWithText(ElevatedButton, 'שמור');

  testWidgets('invalid email blocks save and shows the error message',
      (tester) async {
    await openSheet(tester, current: base);

    await tester.enterText(emailField(), 'not-an-email');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    // Error surfaced, sheet still open (TextFormField still present).
    expect(find.text('נא להזין כתובת דוא״ל תקינה'), findsOneWidget);
    expect(emailField(), findsOneWidget);
  });

  testWidgets('valid email saves and returns the updated profile',
      (tester) async {
    UserProfile? returned;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returned = await showProfileEditSheet(context, base);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(emailField(), 'dana@example.com');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    // Sheet closed and the email persisted.
    expect(find.byType(TextFormField), findsNothing);
    expect(returned, isNotNull);
    expect(returned!.email, 'dana@example.com');
  });

  testWidgets('empty email is optional — passes validation and saves',
      (tester) async {
    UserProfile? returned;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returned = await showProfileEditSheet(context, base);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Leave the (already empty) email field blank and save.
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    // No validation error, sheet closed, profile returned with null email.
    expect(find.text('נא להזין כתובת דוא״ל תקינה'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(returned, isNotNull);
    expect(returned!.email, isNull);
  });
}
