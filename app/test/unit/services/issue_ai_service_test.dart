import 'package:app/services/device_context_service.dart';
import 'package:app/services/issue_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scripted [AiChatSession] that returns queued responses in order.
class _FakeAiChatSession implements AiChatSession {
  final List<String> responses;
  final List<String> sent = [];
  int _index = 0;

  _FakeAiChatSession(this.responses);

  @override
  Future<String> send(String message) async {
    sent.add(message);
    return responses[_index++];
  }
}

class _ThrowingAiChatSession implements AiChatSession {
  @override
  Future<String> send(String message) async => throw StateError('boom');
}

void main() {
  group('AiReply.parse', () {
    test('plain text is a non-final chat reply', () {
      final reply = AiReply.parse('מה בדיוק לא עבד?');
      expect(reply.isFinal, isFalse);
      expect(reply.text, 'מה בדיוק לא עבד?');
    });

    test('leading final-markdown tag marks the reply final and is stripped', () {
      final reply = AiReply.parse('${IssueAiService.finalMarkdownTag}\n# כותרת\nגוף');
      expect(reply.isFinal, isTrue);
      expect(reply.text, '# כותרת\nגוף');
      expect(reply.text, isNot(contains(IssueAiService.finalMarkdownTag)));
    });

    test('tolerates leading whitespace before the tag', () {
      final reply = AiReply.parse('   ${IssueAiService.finalMarkdownTag} גוף');
      expect(reply.isFinal, isTrue);
      expect(reply.text, 'גוף');
    });

    test('a tag that is not at the start stays a chat reply', () {
      final reply = AiReply.parse('אולי ${IssueAiService.finalMarkdownTag}');
      expect(reply.isFinal, isFalse);
    });
  });

  group('buildSystemPrompt', () {
    test('injects the device context and mandates the final tag', () {
      const context = DeviceContext(
        appName: 'SafeBite',
        appVersion: '1.0.0',
        buildNumber: '7',
        platform: 'iOS',
        osVersion: '17.4',
        deviceModel: 'iPhone15,2',
      );

      final prompt = IssueAiService.buildSystemPrompt(context);

      expect(prompt, contains('iPhone15,2'));
      expect(prompt, contains('SafeBite 1.0.0 (7)'));
      expect(prompt, contains(IssueAiService.finalMarkdownTag));
    });
  });

  group('IssueAiService.send', () {
    test('forwards the message and classifies a chat reply', () async {
      final session = _FakeAiChatSession(['תוכל/י לפרט?']);
      final service = IssueAiService(session);

      final reply = await service.send('הכפתור לא עובד');

      expect(session.sent.single, 'הכפתור לא עובד');
      expect(reply.isFinal, isFalse);
      expect(reply.text, 'תוכל/י לפרט?');
    });

    test('classifies a final markdown reply', () async {
      final session = _FakeAiChatSession([
        '${IssueAiService.finalMarkdownTag}\n# באג בכפתור',
      ]);
      final service = IssueAiService(session);

      final reply = await service.send('פרטים נוספים');

      expect(reply.isFinal, isTrue);
      expect(reply.text, '# באג בכפתור');
    });

    test('wraps underlying errors in IssueAiException', () async {
      final service = IssueAiService(_ThrowingAiChatSession());
      expect(() => service.send('x'), throwsA(isA<IssueAiException>()));
    });
  });
}
