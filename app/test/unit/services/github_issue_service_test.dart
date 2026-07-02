import 'dart:convert';

import 'package:app/services/github_issue_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('deriveTitle', () {
    test('uses the first H1 heading with the hashes stripped', () {
      expect(
        GitHubIssueService.deriveTitle('# באג בהתחברות\n\nגוף הדיווח'),
        'באג בהתחברות',
      );
    });

    test('falls back to the first non-empty line when no heading', () {
      expect(
        GitHubIssueService.deriveTitle('\n\nשורה ראשונה\nשורה שנייה'),
        'שורה ראשונה',
      );
    });

    test('truncates very long titles', () {
      final title = GitHubIssueService.deriveTitle('# ${'א' * 200}');
      expect(title.length, lessThanOrEqualTo(120));
      expect(title, endsWith('...'));
    });

    test('provides a Hebrew fallback for empty input', () {
      expect(GitHubIssueService.deriveTitle('   '), 'משוב מהאפליקציה');
    });
  });

  group('createIssue', () {
    test('POSTs to the issues endpoint and returns the created issue', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'number': 501,
            'html_url': 'https://github.com/Maortz/allergy-detector/issues/501',
          }),
          201,
        );
      });

      final service = GitHubIssueService(
        client: client,
        token: 'test-token',
      );

      final issue = await service.createIssue(
        title: 'כותרת',
        body: '# כותרת\nגוף',
      );

      expect(issue.number, 501);
      expect(issue.url, endsWith('/issues/501'));
      expect(
        captured.url.toString(),
        'https://api.github.com/repos/Maortz/allergy-detector/issues',
      );
      expect(captured.headers['Authorization'], 'Bearer test-token');
      final payload = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(payload['title'], 'כותרת');
      expect(payload['body'], '# כותרת\nגוף');
    });

    test('throws GitHubIssueException on a non-201 response', () async {
      final client = MockClient(
        (request) async => http.Response('Bad credentials', 401),
      );
      final service = GitHubIssueService(client: client, token: 'bad');

      await expectLater(
        () => service.createIssue(title: 't', body: 'b'),
        throwsA(isA<GitHubIssueException>()),
      );
    });
  });
}
