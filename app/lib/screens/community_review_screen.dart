import 'package:flutter/material.dart';
import '../models/pending_review.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/allergen_icons.dart';
import '../utils/app_toast.dart';
import '../widgets/bottom_nav_bar.dart';

/// Community Review — the moderation surface where a reviewer approves or
/// rejects a community-contributed product's allergen data.
///
/// Wired to an in-memory [queue]; the reviewer advances through it via the
/// approve/reject callbacks. Live Supabase wiring (a `pending_reviews` table)
/// is a follow-up — the table does not exist yet.
class CommunityReviewScreen extends StatefulWidget {
  final List<PendingReview> queue;
  final List<PastContribution> pastContributions;

  /// Called when the reviewer approves [review]. May be async.
  final Future<void> Function(PendingReview review)? onApprove;

  /// Called when the reviewer rejects [review] with a (non-empty) [reason].
  final Future<void> Function(PendingReview review, String reason)? onReject;

  /// Pops back to the Community Hub (app bar back + empty-state button).
  final VoidCallback? onReturnToCommunity;

  /// Fired once the reviewer advances past the last item in the queue, i.e.
  /// the queue is exhausted by a completed review (spec §6.4). The host wires
  /// this to push [ReviewAllClearScreen]. Distinct from the start-empty case
  /// (an initially-empty [queue]), which still renders the inline empty state.
  final VoidCallback? onQueueExhausted;

  final ValueChanged<int>? onNavTap;

  const CommunityReviewScreen({
    super.key,
    required this.queue,
    this.pastContributions = const [],
    this.onApprove,
    this.onReject,
    this.onReturnToCommunity,
    this.onQueueExhausted,
    this.onNavTap,
  });

  @override
  State<CommunityReviewScreen> createState() => _CommunityReviewScreenState();
}

/// Which decision is currently in-flight. Drives the per-button spinner and
/// disables both buttons while either submit is running (CR-2: no body-level
/// spinner, no double-submit race).
enum _InFlight { none, approve, reject }

class _CommunityReviewScreenState extends State<CommunityReviewScreen> {
  final TextEditingController _reasonController = TextEditingController();
  int _index = 0;
  _InFlight _inFlight = _InFlight.none;
  bool _rejectAttempted = false;

  bool get _submitting => _inFlight != _InFlight.none;

  @override
  void didUpdateWidget(covariant CommunityReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent rebuilds may swap in a refreshed queue (pull-to-refresh, realtime
    // append). Reset the cursor so a stale `_index` doesn't drop the reviewer
    // into the empty state with items still pending.
    if (!identical(oldWidget.queue, widget.queue)) {
      _index = 0;
      _rejectAttempted = false;
      _reasonController.clear();
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  PendingReview? get _currentReview =>
      _index < widget.queue.length ? widget.queue[_index] : null;

  int get _remaining => widget.queue.length - _index;

  void _advance() {
    setState(() {
      _index++;
      _inFlight = _InFlight.none;
      _rejectAttempted = false;
      _reasonController.clear();
    });
    // Just consumed the last item → the queue is exhausted by a completed
    // review. Hand off to the host (spec §6.4) so it can route to the terminal
    // celebration screen. Fires after setState so the empty state never flashes
    // when a handler is present.
    if (_index >= widget.queue.length) {
      widget.onQueueExhausted?.call();
    }
  }

  Future<void> _handleApprove() async {
    final current = _currentReview;
    if (current == null || _submitting) return;
    setState(() => _inFlight = _InFlight.approve);
    try {
      await widget.onApprove?.call(current);
      if (!mounted) return;
      _advance();
    } catch (e) {
      if (!mounted) return;
      setState(() => _inFlight = _InFlight.none);
      debugPrint('community-review approve failed: $e');
      _showError('שגיאה באישור המוצר. נסה שוב.');
      // Don't advance on error — keep the same item so the reviewer can retry.
    }
  }

  Future<void> _handleReject() async {
    final current = _currentReview;
    if (current == null || _submitting) return;
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _rejectAttempted = true);
      return;
    }
    setState(() => _inFlight = _InFlight.reject);
    try {
      await widget.onReject?.call(current, reason);
      if (!mounted) return;
      _advance();
    } catch (e) {
      if (!mounted) return;
      setState(() => _inFlight = _InFlight.none);
      debugPrint('community-review reject failed: $e');
      _showError('שגיאה בפסילת המוצר. נסה שוב.');
    }
  }

  void _showError(String message) => AppToast.error(context, message);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final current = _currentReview;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'סקירת מוצר',
            style: AppTypography.labelBold.copyWith(
              color: colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              color: colorScheme.onSurfaceVariant,
              onPressed: widget.onReturnToCommunity ??
                  () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
        body: current == null
            ? _buildEmptyState()
            : _buildReviewBody(current),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2,
          // §7.5 nested under Community Hub: in the absence of an explicit
          // handler, pop back to MainContainer (which owns the tab nav).
          onTap: widget.onNavTap ?? (_) => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  Widget _buildReviewBody(PendingReview review) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCounterRow(),
          const SizedBox(height: AppSpacing.lg),
          _buildProductCard(review),
          const SizedBox(height: AppSpacing.md),
          _buildAllergenCard(review),
          const SizedBox(height: AppSpacing.md),
          _buildDecisionPanel(),
          if (widget.pastContributions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildHistoryStrip(),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'סקירת מוצר חדש',
                style: AppTypography.h2.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'תרומת הקהילה לאימות נתונים',
                style:
                    AppTypography.labelSm.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$_remaining נותרו',
                style: AppTypography.labelBold.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(PendingReview review) {
    final colorScheme = Theme.of(context).colorScheme;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: review.imageUrl != null
                  ? Image.network(
                      review.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              review.categoryLabel,
              style:
                  AppTypography.labelSm.copyWith(color: colorScheme.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            review.productName,
            style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'מותג: ${review.brandName}',
            style: AppTypography.bodyMd.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );

  Widget _buildAllergenCard(PendingReview review) {
    final colorScheme = Theme.of(context).colorScheme;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.warning, color: colorScheme.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'מידע על אלרגנים שהוזן:',
                  style: AppTypography.labelBold
                      .copyWith(color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.surfaceContainer),
          const SizedBox(height: AppSpacing.md),
          ...review.allergenReports.map(_buildAllergenTile),
          if (review.contributorNote != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildContributorNote(review.contributorNote!),
          ],
        ],
      ),
    );
  }

  Widget _buildAllergenTile(AllergenReport report) {
    final colorScheme = Theme.of(context).colorScheme;
    // Spec §4: per-status tints — *-container/10 for the outer tile, full
    // *-container for the inner icon circle (preserves the two-tone hierarchy).
    final (Color border, Color circleBg, Color iconColor, String label,
        Color labelColor, Color tileBg) = switch (report.status) {
      AllergenReportStatus.contains => (
          colorScheme.error,
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
          'מכיל בוודאות',
          colorScheme.error,
          colorScheme.errorContainer.withValues(alpha: 0.1),
        ),
      AllergenReportStatus.mayContain => (
          colorScheme.outlineVariant,
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
          'עשוי להכיל',
          colorScheme.outline,
          colorScheme.surfaceContainerLow,
        ),
      AllergenReportStatus.absent => (
          colorScheme.secondary,
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
          'לא מכיל',
          colorScheme.secondary,
          colorScheme.secondaryContainer.withValues(alpha: 0.1),
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
            ),
            child:
                Icon(allergenIconFor(report.allergen), size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.allergen.nameHe,
                  style: AppTypography.labelBold
                      .copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.labelSm.copyWith(
                    color: labelColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorNote(String note) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border(
          right: BorderSide(color: colorScheme.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'הערת התורם:',
            style: AppTypography.labelSm.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            note,
            style: AppTypography.bodyMd.copyWith(
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'החלטה למוצר זה:',
            style:
                AppTypography.labelBold.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  // Disabled while either action is in-flight (CR-2: prevents the
                  // double-submit race). A null callback greys the button out.
                  onPressed: _submitting ? null : _handleApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _buttonIcon(
                    busy: _inFlight == _InFlight.approve,
                    icon: Icons.check_circle,
                    spinnerColor: colorScheme.onPrimary,
                  ),
                  label: const Text('אישור מוצר'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _handleReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error, width: 2),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _buttonIcon(
                    busy: _inFlight == _InFlight.reject,
                    icon: Icons.cancel,
                    spinnerColor: colorScheme.error,
                  ),
                  label: const Text('פסילת מוצר'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reasonController,
            enabled: !_submitting,
            maxLines: 3,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMd,
            onChanged: (_) {
              if (_rejectAttempted) setState(() => _rejectAttempted = false);
            },
            decoration: InputDecoration(
              labelText: 'סיבת הפסילה (במידה ונפסל)',
              hintText: 'פרט מדוע המידע אינו תקין...',
              errorText: _rejectAttempted ? 'יש להזין סיבת פסילה' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Leading slot for a decision button: a sized spinner while [busy],
  /// otherwise the static [icon]. Fixed 20x20 so the button doesn't reflow
  /// when it flips into its loading state.
  Widget _buttonIcon({
    required bool busy,
    required IconData icon,
    required Color spinnerColor,
  }) {
    if (!busy) return Icon(icon, size: 20);
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
      ),
    );
  }

  Widget _buildHistoryStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'תרומות אחרונות שלך',
          style: AppTypography.h3
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.pastContributions.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) =>
                _buildContributionCard(widget.pastContributions[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildContributionCard(PastContribution contribution) {
    final colorScheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String label) =
        switch (contribution.outcome) {
      ContributionOutcome.approved => (
          Icons.check_circle,
          colorScheme.secondary,
          'אושר',
        ),
      ContributionOutcome.pending => (
          Icons.schedule,
          colorScheme.outline,
          'ממתין',
        ),
      ContributionOutcome.rejected => (
          Icons.cancel,
          colorScheme.error,
          'נפסל',
        ),
    };

    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: contribution.imageUrl != null
                ? Image.network(
                    contribution.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.image_outlined,
                      color: colorScheme.outlineVariant,
                    ),
                  )
                : Icon(Icons.image_outlined,
                    color: colorScheme.outlineVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contribution.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelBold
                      .copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      label,
                      style: AppTypography.labelSm.copyWith(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'אין מוצרים לסקירה כרגע',
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'תודה על תרומתך לקהילה! נשלח לך הודעה כשיהיו מוצרים חדשים לסקירה.',
                textAlign: TextAlign.center,
                style:
                    AppTypography.bodyMd.copyWith(color: colorScheme.outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onReturnToCommunity ??
                  () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('חזרה לקהילה'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.surfaceContainerHigh),
      ),
      child: child,
    );
  }
}
