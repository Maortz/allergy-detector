import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_contribution.dart';
import '../services/my_reviews_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/contribution_status_pill.dart';
import '../widgets/product_thumb.dart';

/// "היסטוריית תרומות" (`settings-profile.md §4.3`) — the products the current
/// user submitted to the community, sourced from the Supabase `pending_reviews`
/// table scoped to their `contributor_id` (issue #185).
///
/// Lists each contribution newest-first with the product, its brand, the
/// moderation status and a relative-time label. Falls back to the
/// no-contributions empty state until the user has submitted at least one.
class ContributionHistoryScreen extends StatefulWidget {
  /// Loads the user's contributions. Defaults to a [MyReviewsService] backed by
  /// the live Supabase client; tests inject a fake to avoid a live backend.
  final Future<List<ProductContribution>> Function()? loadContributions;

  const ContributionHistoryScreen({super.key, this.loadContributions});

  @override
  State<ContributionHistoryScreen> createState() =>
      _ContributionHistoryScreenState();
}

class _ContributionHistoryScreenState extends State<ContributionHistoryScreen> {
  List<ProductContribution>? _contributions;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loader = widget.loadContributions ??
        () => MyReviewsService(Supabase.instance.client).fetchContributions();
    try {
      final contributions = await loader();
      if (!mounted) return;
      setState(() {
        _contributions = contributions;
        _failed = false;
      });
    } catch (e) {
      debugPrint('contribution-history load failed: $e');
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('היסטוריית תרומות'),
          backgroundColor: colorScheme.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_failed) {
      return _ContributionHistoryError(onRetry: () {
        setState(() {
          _failed = false;
          _contributions = null;
        });
        _load();
      });
    }
    final contributions = _contributions;
    if (contributions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (contributions.isEmpty) {
      return const _ContributionHistoryEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: contributions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) =>
          _ContributionCard(contribution: contributions[index]),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final ProductContribution contribution;

  const _ContributionCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ProductThumb(
            imageUrl: contribution.imageUrl,
            fallbackIcon: Icons.shopping_basket,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contribution.productName,
                  style: AppTypography.labelBold
                      .copyWith(color: colorScheme.onSurface),
                ),
                if (contribution.brandName != null &&
                    contribution.brandName!.isNotEmpty)
                  Text(
                    contribution.brandName!,
                    style: AppTypography.labelSm
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  relativeTimeHe(contribution.submittedAt),
                  style: AppTypography.labelSm
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ContributionStatusPill(status: contribution.status),
        ],
      ),
    );
  }
}

class _ContributionHistoryEmpty extends StatelessWidget {
  const _ContributionHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism,
              size: 72,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'עדיין לא תרמת לקהילה',
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'הוספת מוצרים, בדיקות ותיקונים יופיעו כאן',
              style: AppTypography.bodyMd
                  .copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionHistoryError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ContributionHistoryError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 72,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'טעינת התרומות נכשלה',
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text('נסה שוב'),
            ),
          ],
        ),
      ),
    );
  }
}
