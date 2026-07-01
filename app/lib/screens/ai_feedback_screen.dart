import 'package:flutter/material.dart';

import '../services/device_context_service.dart';
import '../services/github_issue_service.dart';
import '../services/issue_ai_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';

/// Role of a chat bubble in the AI feedback conversation.
enum _Author { user, assistant }

@immutable
class _ChatMessage {
  final _Author author;
  final String text;

  /// When non-null, this assistant message is the final structured issue and
  /// carries the raw markdown body used to create the GitHub issue.
  final String? finalMarkdown;

  const _ChatMessage(this.author, this.text, {this.finalMarkdown});
}

/// In-app AI-powered feedback assistant (issue #337).
///
/// The user describes a bug or feature request in free text; Gemini asks
/// clarifying questions until it has enough detail, then emits a structured
/// Markdown issue which is filed directly to the GitHub Issues API.
///
/// Services are injectable for testing. In production the AI service is built
/// lazily after the device context is gathered, and both services read their
/// secrets from `--dart-define` (never hardcoded).
class AiFeedbackScreen extends StatefulWidget {
  final IssueAiService? aiService;
  final GitHubIssueService? githubService;
  final DeviceContextService? deviceContextService;

  const AiFeedbackScreen({
    super.key,
    this.aiService,
    this.githubService,
    this.deviceContextService,
  });

  @override
  State<AiFeedbackScreen> createState() => _AiFeedbackScreenState();
}

class _AiFeedbackScreenState extends State<AiFeedbackScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      _Author.assistant,
      'שלום! ספר/י לי בקצרה על התקלה או ההצעה שלך, ואשאל שאלות עד שיהיה לנו דיווח מסודר.',
    ),
  ];

  IssueAiService? _ai;
  late final GitHubIssueService _github;

  bool _aiReady = false;
  bool _sending = false;
  bool _creatingIssue = false;
  String? _initError;

  bool get _configured =>
      (widget.aiService != null || IssueAiService.isConfigured) &&
      (widget.githubService != null || GitHubIssueService.isConfigured);

  @override
  void initState() {
    super.initState();
    _github = widget.githubService ?? GitHubIssueService();
    _initAi();
  }

  Future<void> _initAi() async {
    if (widget.aiService != null) {
      // Injected (tests): ready synchronously — initState runs before the first
      // build, so no setState is needed or allowed here.
      _ai = widget.aiService;
      _aiReady = true;
      return;
    }
    if (!IssueAiService.isConfigured) return;
    try {
      final context = await (widget.deviceContextService ??
              DeviceContextService())
          .gather();
      _ai = IssueAiService.gemini(deviceContext: context);
      if (mounted) setState(() => _aiReady = true);
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _appendMessage(_ChatMessage message) {
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    final ai = _ai;
    if (text.isEmpty || _sending || ai == null) return;

    _appendMessage(_ChatMessage(_Author.user, text));
    _inputController.clear();
    setState(() => _sending = true);

    try {
      final reply = await ai.send(text);
      if (!mounted) return;
      _appendMessage(
        _ChatMessage(
          _Author.assistant,
          reply.isFinal
              ? 'סיכמתי את הדיווח. בדוק/י ולחץ/י "צור דיווח" כדי לשלוח.'
              : reply.text,
          finalMarkdown: reply.isFinal ? reply.text : null,
        ),
      );
    } catch (e, st) {
      debugPrint('AiFeedbackScreen send failed: $e\n$st');
      if (mounted) {
        AppToast.error(context, 'שגיאה בתקשורת עם העוזר. נסה שנית.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _createIssue(String markdown) async {
    if (_creatingIssue) return;
    setState(() => _creatingIssue = true);
    try {
      final issue = await _github.createIssue(
        title: GitHubIssueService.deriveTitle(markdown),
        body: markdown,
      );
      if (!mounted) return;
      // Stop the button spinner before awaiting the (blocking) success dialog,
      // otherwise its indeterminate progress animation never settles.
      setState(() => _creatingIssue = false);
      await _showSuccessDialog(issue);
      return;
    } catch (e, st) {
      debugPrint('AiFeedbackScreen createIssue failed: $e\n$st');
      if (mounted) {
        AppToast.error(context, 'שגיאה ביצירת הדיווח ב-GitHub. נסה שנית.');
      }
    }
    if (mounted) setState(() => _creatingIssue = false);
  }

  Future<void> _showSuccessDialog(CreatedIssue issue) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: Icon(
            Icons.check_circle,
            color: Theme.of(dialogContext).colorScheme.primary,
            size: 40,
          ),
          title: const Text('תודה על המשוב!'),
          content: Text('הדיווח נפתח בהצלחה (#${issue.number}).'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('סגור'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('עוזר משוב חכם'),
          backgroundColor: colorScheme.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: _configured ? _buildChat(colorScheme) : _buildUnconfigured(),
        ),
      ),
    );
  }

  Widget _buildChat(ColorScheme colorScheme) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _MessageBubble(
              message: _messages[index],
              onCreateIssue: _creatingIssue ? null : _createIssue,
              isCreating: _creatingIssue,
            ),
          ),
        ),
        if (_sending)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _TypingIndicator(),
          ),
        _InputBar(
          controller: _inputController,
          enabled: _aiReady && !_sending,
          onSend: _send,
        ),
      ],
    );
  }

  Widget _buildUnconfigured() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 48,
              color: context.colors.iconMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _initError != null
                  ? 'העוזר החכם אינו זמין כרגע.'
                  : 'העוזר החכם אינו מוגדר בגרסה זו.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMdBold.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'אפשר לפנות אלינו דרך מסך "צור קשר".',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final Future<void> Function(String markdown)? onCreateIssue;
  final bool isCreating;

  const _MessageBubble({
    required this.message,
    required this.onCreateIssue,
    required this.isCreating,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.author == _Author.user;
    final markdown = message.finalMarkdown;

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTypography.bodySm.copyWith(
                color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            if (markdown != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.borderSubtle),
                ),
                child: Text(
                  markdown,
                  style: AppTypography.labelSmRegular.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCreateIssue == null
                      ? null
                      : () => onCreateIssue!(markdown),
                  icon: isCreating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: const Text('צור דיווח'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'העוזר מקליד…',
              style: AppTypography.labelSm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textDirection: TextDirection.rtl,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => enabled ? onSend() : null,
              decoration: InputDecoration(
                hintText: 'כתוב/כתבי הודעה…',
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: context.colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: context.colors.borderSubtle),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
