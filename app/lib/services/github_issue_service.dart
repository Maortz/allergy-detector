import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A successfully created GitHub issue.
@immutable
class CreatedIssue {
  final int number;
  final String url;

  const CreatedIssue({required this.number, required this.url});
}

/// Thrown when the GitHub Issues API rejects the request.
class GitHubIssueException implements Exception {
  final String message;
  GitHubIssueException(this.message);

  @override
  String toString() => 'GitHubIssueException: $message';
}

/// Posts finalized feedback to the repository's GitHub Issues API.
///
/// The Personal Access Token is read from
/// `--dart-define=GITHUB_ISSUE_TOKEN=...` via [String.fromEnvironment] and is
/// never hardcoded (issue #337 DoD). The [http.Client] is injectable so the
/// network path is fully unit-testable.
class GitHubIssueService {
  static const String _envToken = String.fromEnvironment('GITHUB_ISSUE_TOKEN');

  final http.Client _client;
  final String owner;
  final String repo;
  final String _token;

  GitHubIssueService({
    http.Client? client,
    this.owner = 'Maortz',
    this.repo = 'allergy-detector',
    String? token,
  }) : _client = client ?? http.Client(),
       _token = token ?? _envToken;

  /// Whether an issue-creation token was supplied at build time.
  static bool get isConfigured => _envToken.isNotEmpty;

  /// Releases the underlying [http.Client]'s connection pool. Call from the
  /// owning widget's `dispose()` to avoid leaking idle sockets across sessions.
  void close() => _client.close();

  /// Derives a concise issue title from AI-generated markdown: the first H1
  /// (`# ...`) heading, else the first non-empty line, capped in length. Pure —
  /// unit-tested directly.
  static String deriveTitle(String markdown) {
    for (final rawLine in const LineSplitter().convert(markdown)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final title = line.startsWith('#')
          ? line.replaceFirst(RegExp(r'^#+\s*'), '').trim()
          : line;
      if (title.isEmpty) continue;
      return title.length > 120 ? '${title.substring(0, 117)}...' : title;
    }
    return 'משוב מהאפליקציה';
  }

  Future<CreatedIssue> createIssue({
    required String title,
    required String body,
  }) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/issues',
    );
    late final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        body: jsonEncode({'title': title, 'body': body}),
      );
    } catch (e, st) {
      debugPrint('GitHubIssueService.createIssue network error: $e\n$st');
      throw GitHubIssueException(e.toString());
    }

    if (response.statusCode != 201) {
      throw GitHubIssueException(
        'GitHub API responded ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CreatedIssue(
      number: json['number'] as int,
      url: json['html_url'] as String,
    );
  }
}
