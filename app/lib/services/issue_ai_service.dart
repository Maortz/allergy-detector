import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'device_context_service.dart';

/// A single turn of the AI conversation, already classified as either an
/// ongoing chat message or the final structured GitHub-issue markdown.
@immutable
class AiReply {
  /// True once the model has emitted the [IssueAiService.finalMarkdownTag]
  /// prefix, signalling it has gathered enough detail to file the issue.
  final bool isFinal;

  /// For a chat turn: the question/message to show the user.
  /// For a final turn: the issue markdown body with the tag stripped.
  final String text;

  const AiReply({required this.isFinal, required this.text});

  /// Parses a raw model response, detecting the leading
  /// [IssueAiService.finalMarkdownTag]. Pure — the core logic under test.
  factory AiReply.parse(String raw) {
    final trimmed = raw.trimLeft();
    if (trimmed.startsWith(IssueAiService.finalMarkdownTag)) {
      final body = trimmed
          .substring(IssueAiService.finalMarkdownTag.length)
          .trim();
      return AiReply(isFinal: true, text: body);
    }
    return AiReply(isFinal: false, text: raw.trim());
  }
}

/// Abstraction over one Gemini chat conversation. Acts as a seam so the AI
/// feedback flow is unit- and widget-testable without a live network call or a
/// configured API key.
abstract class AiChatSession {
  Future<String> send(String message);
}

/// Production [AiChatSession] backed by `google_generative_ai`'s [ChatSession],
/// which retains conversation history across turns.
class GeminiChatSession implements AiChatSession {
  final ChatSession _chat;

  GeminiChatSession(this._chat);

  @override
  Future<String> send(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? '';
  }
}

/// Thrown when the AI conversation cannot proceed (network / SDK failure).
class IssueAiException implements Exception {
  final String message;
  IssueAiException(this.message);

  @override
  String toString() => 'IssueAiException: $message';
}

/// Drives the dynamic bug/feature-report conversation with Gemini and turns
/// raw model output into typed [AiReply]s.
///
/// The API key is read from `--dart-define=GEMINI_API_KEY=...` via
/// [String.fromEnvironment] — never hardcoded (issue #337 DoD).
class IssueAiService {
  /// Exact prefix the model must emit to signal the final issue markdown.
  static const String finalMarkdownTag = '[FINAL_MARKDOWN]';

  static const String modelName = 'gemini-2.5-flash';

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final AiChatSession _session;

  IssueAiService(this._session);

  /// Whether a Gemini API key was supplied at build time.
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// System instruction injecting the device context and the strict
  /// final-markdown protocol. Pure — asserted in tests.
  static String buildSystemPrompt(DeviceContext context) {
    return '''
You are a friendly Flutter QA assistant for "SafeBite", a Hebrew, RTL allergen-safety app. Your job is to help the user report a bug or request a feature.

App / device context (do not ask the user for this — it is already known):
${context.toPromptBlock()}

Instructions:
1. Always talk to the user in Hebrew, concisely and politely.
2. Analyse the user's input. If it lacks the detail needed for a good bug/feature report (what happened, expected vs actual, steps to reproduce, or the feature's goal), ask ONE focused clarification question at a time.
3. When you have enough information, produce a well-structured GitHub issue in Markdown.
4. CRITICAL: the final response — and ONLY the final one — must start with the exact tag `$finalMarkdownTag` on its own, followed by the Markdown. Every clarification turn must be plain chat with NO tag.
5. The Markdown must begin with a single H1 title line (`# ...`) suitable as the issue title, then a body with clear sections (e.g. תיאור, שחזור, ציפייה מול מציאות). Write the issue content in Hebrew.
''';
  }

  /// Builds a production instance wired to Gemini. [apiKey] overrides the
  /// compile-time define (used only in tests / tooling).
  factory IssueAiService.gemini({
    required DeviceContext deviceContext,
    String? apiKey,
  }) {
    final key = apiKey ?? _apiKey;
    final model = GenerativeModel(
      model: modelName,
      apiKey: key,
      systemInstruction: Content.system(buildSystemPrompt(deviceContext)),
    );
    return IssueAiService(GeminiChatSession(model.startChat()));
  }

  /// Sends a user message and returns the classified reply.
  Future<AiReply> send(String message) async {
    try {
      final raw = await _session.send(message);
      return AiReply.parse(raw);
    } on IssueAiException {
      rethrow;
    } catch (e, st) {
      debugPrint('IssueAiService.send failed: $e\n$st');
      throw IssueAiException(e.toString());
    }
  }
}
