import 'package:flutter/material.dart';
import '../models/pending_review.dart';
import '../theme/app_colors.dart';
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

  final ValueChanged<int>? onNavTap;

  const CommunityReviewScreen({
    super.key,
    required this.queue,
    this.pastContributions = const [],
    this.onApprove,
    this.onReject,
    this.onReturnToCommunity,
    this.onNavTap,
  });

  @override
  State<CommunityReviewScreen> createState() => _CommunityReviewScreenState();
}

class _CommunityReviewScreenState extends State<CommunityReviewScreen> {
  final TextEditingController _reasonController = TextEditingController();
  int _index = 0;
  bool _submitting = false;
  bool _rejectAttempted = false;

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
      _submitting = false;
      _rejectAttempted = false;
      _reasonController.clear();
    });
  }

  Future<void> _handleApprove() async {
    final current = _currentReview;
    if (current == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onApprove?.call(current);
      if (!mounted) return;
      _advance();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
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
    setState(() => _submitting = true);
    try {
      await widget.onReject?.call(current, reason);
      if (!mounted) return;
      _advance();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      debugPrint('community-review reject failed: $e');
      _showError('שגיאה בפסילת המוצר. נסה שוב.');
    }
  }

  void _showError(String message) => AppToast.error(context, message);

  @override
  Widget build(BuildContext context) {
    final current = _currentReview;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'סקירת מוצר',
            style: AppTypography.labelBold.copyWith(
              color: AppColors.onSurface,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              color: AppColors.onSurfaceVariant,
              onPressed: widget.onReturnToCommunity ??
                  () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
        body: _submitting
            ? const Center(child: CircularProgressIndicator())
            : current == null
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'סקירת מוצר חדש',
                style: AppTypography.h2.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'תרומת הקהילה לאימות נתונים',
                style: AppTypography.labelSm.copyWith(color: AppColors.outline),
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
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pending_actions,
                size: 20,
                color: AppColors.onPrimaryFixed,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$_remaining נותרו',
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.onPrimaryFixed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(PendingReview review) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
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
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              review.categoryLabel,
              style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            review.productName,
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'מותג: ${review.brandName}',
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => const Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: AppColors.outlineVariant,
        ),
      );

  Widget _buildAllergenCard(PendingReview review) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.warning, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'מידע על אלרגנים שהוזן:',
                  style: AppTypography.labelBold
                      .copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainer),
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
    // Spec §4: per-status tints — *-container/10 for the outer tile, full
    // *-container for the inner icon circle (preserves the two-tone hierarchy).
    final (Color border, Color circleBg, Color iconColor, String label,
        Color labelColor, Color tileBg) = switch (report.status) {
      AllergenReportStatus.contains => (
          AppColors.error,
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          'מכיל בוודאות',
          AppColors.error,
          AppColors.errorContainer.withValues(alpha: 0.1),
        ),
      AllergenReportStatus.mayContain => (
          AppColors.outlineVariant,
          AppColors.surfaceVariant,
          AppColors.onSurfaceVariant,
          'עשוי להכיל',
          AppColors.outline,
          AppColors.surfaceContainerLow,
        ),
      AllergenReportStatus.absent => (
          AppColors.secondary,
          AppColors.secondaryContainer,
          AppColors.onSecondaryContainer,
          'לא מכיל',
          AppColors.secondary,
          AppColors.secondaryContainer.withValues(alpha: 0.1),
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
                      .copyWith(color: AppColors.onSurface),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border(
          right: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'הערת התורם:',
            style: AppTypography.labelSm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            note,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionPanel() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'החלטה למוצר זה:',
            style:
                AppTypography.labelBold.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _handleApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text('אישור מוצר'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 2),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text('פסילת מוצר'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reasonController,
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
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'תרומות אחרונות שלך',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
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
    final (IconData icon, Color color, String label) =
        switch (contribution.outcome) {
      ContributionOutcome.approved => (
          Icons.check_circle,
          AppColors.secondary,
          'אושר',
        ),
      ContributionOutcome.pending => (
          Icons.schedule,
          AppColors.outline,
          'ממתין',
        ),
      ContributionOutcome.rejected => (
          Icons.cancel,
          AppColors.error,
          'נפסל',
        ),
    };

    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: contribution.imageUrl != null
                ? Image.network(
                    contribution.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image_outlined,
                      color: AppColors.outlineVariant,
                    ),
                  )
                : const Icon(Icons.image_outlined,
                    color: AppColors.outlineVariant),
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
                      .copyWith(color: AppColors.onSurface),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 64, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'אין מוצרים לסקירה כרגע',
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'תודה על תרומתך לקהילה! נשלח לך הודעה כשיהיו מוצרים חדשים לסקירה.',
                textAlign: TextAlign.center,
                style:
                    AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onReturnToCommunity ??
                  () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: child,
    );
  }
}
