import 'dart:convert';

import 'package:app/screens/ai_feedback_screen.dart';
import 'package:app/services/github_issue_service.dart';
import 'package:app/services/issue_ai_service.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAiChatSession implements AiChatSession {
  final List<String> responses;
  int _index = 0;
  _FakeAiChatSession(this.responses);

  @override
  Future<String> send(String message) async => responses[_index++];
}

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: buildAppTheme(), home: child);

  testWidgets('unconfigured build shows the fallback message', (tester) async {
    // No injected services and no --dart-define keys → not configured.
    await tester.pumpWidget(wrap(const AiFeedbackScreen()));
    await tester.pumpAndSettle();

    expect(find.text('העוזר החכם אינו מוגדר בגרסה זו.'), findsOneWidget);
  });

  testWidgets('shows a clarifying reply for a chat turn', (tester) async {
    final ai = IssueAiService(_FakeAiChatSession(['מה בדיוק לא עבד?']));
    final github = GitHubIssueService(
      client: MockClient((_) async => http.Response('{}', 201)),
      token: 't',
    );

    await tester.pumpWidget(
      wrap(AiFeedbackScreen(aiService: ai, githubService: github)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'הכפתור לא עובד');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('הכפתור לא עובד'), findsOneWidget); // echoed user bubble
    expect(find.text('מה בדיוק לא עבד?'), findsOneWidget); // assistant reply
  });

  testWidgets('an empty AI reply does not add a blank assistant bubble', (
    tester,
  ) async {
    final ai = IssueAiService(_FakeAiChatSession(['']));
    final github = GitHubIssueService(
      client: MockClient((_) async => http.Response('{}', 201)),
      token: 't',
    );

    await tester.pumpWidget(
      wrap(AiFeedbackScreen(aiService: ai, githubService: github)),
    );
    await tester.pumpAndSettle();

    final textsBefore = tester.widgetList(find.byType(Text)).length;

    await tester.enterText(find.byType(TextField), 'הכפתור לא עובד');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // The user's message is echoed, but the empty assistant reply is dropped:
    // exactly one new bubble (the user's) renders, so the Text-widget count
    // rises by one, not two.
    expect(find.text('הכפתור לא עובד'), findsOneWidget);
    expect(tester.widgetList(find.byType(Text)).length, textsBefore + 1);
  });

  testWidgets('final markdown enables issue creation and shows success', (
    tester,
  ) async {
    final ai = IssueAiService(
      _FakeAiChatSession(['${IssueAiService.finalMarkdownTag}\n# באג בכפתור']),
    );
    final github = GitHubIssueService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'number': 777,
            'html_url': 'https://github.com/x/y/issues/777',
          }),
          201,
        ),
      ),
      token: 't',
    );

    await tester.pumpWidget(
      wrap(AiFeedbackScreen(aiService: ai, githubService: github)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'יש באג');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // The final markdown body renders and the create-issue CTA appears.
    expect(find.text('# באג בכפתור'), findsOneWidget);
    final createButton = find.widgetWithText(FilledButton, 'צור דיווח');
    expect(createButton, findsOneWidget);

    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('תודה על המשוב!'), findsOneWidget);
    expect(find.textContaining('#777'), findsOneWidget);
  });
}
