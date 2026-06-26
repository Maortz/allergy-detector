import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_contribution.dart';
import '../services/my_reviews_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/contribution_status_pill.dart';
import '../widgets/product_thumb.dart';

/// "ביקורות שלי" (`nav-drawer-user.md §3` row 4) — the current user's community
/// reviews, sourced from the Supabase `pending_reviews` table scoped to their
/// `contributor_id` (issue #185).
///
/// Lists each review newest-first with the product it targets, the reviewer's
/// note, its moderation status and a relative-time label. Falls back to the
/// no-reviews empty state until the user has submitted at least one.
class MyReviewsScreen extends StatefulWidget {
  /// Loads the user's reviews. Defaults to a [MyReviewsService] backed by the
  /// live Supabase client; tests inject a fake to avoid a live backend.
  final Future<List<MyReview>> Function()? loadReviews;

  const MyReviewsScreen({super.key, this.loadReviews});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<MyReview>? _reviews;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loader = widget.loadReviews ??
        () => MyReviewsService(Supabase.instance.client).fetchMyReviews();
    try {
      final reviews = await loader();
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _failed = false;
      });
    } catch (e) {
      debugPrint('my-reviews load failed: $e');
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
          title: const Text('ביקורות שלי'),
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
      return _MyReviewsError(onRetry: () {
        setState(() {
          _failed = false;
          _reviews = null;
        });
        _load();
      });
    }
    final reviews = _reviews;
    if (reviews == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reviews.isEmpty) {
      return const _MyReviewsEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) => _MyReviewCard(review: reviews[index]),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final MyReview review;

  const _MyReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumb(
                imageUrl: review.imageUrl,
                fallbackIcon: Icons.rate_review_outlined,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName,
                      style: AppTypography.labelBold
                          .copyWith(color: colorScheme.onSurface),
                    ),
                    if (review.brandName != null &&
                        review.brandName!.isNotEmpty)
                      Text(
                        review.brandName!,
                        style: AppTypography.labelSm
                            .copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              ContributionStatusPill(status: review.status),
            ],
          ),
          if (review.note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.note!,
              style: AppTypography.bodySm.copyWith(color: colorScheme.onSurface),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            relativeTimeHe(review.submittedAt),
            style: AppTypography.labelSm
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MyReviewsEmpty extends StatelessWidget {
  const _MyReviewsEmpty();

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
              Icons.rate_review_outlined,
              size: 72,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'עדיין לא כתבת ביקורות',
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'תרומותיך לבדיקת מוצרים יופיעו כאן',
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

class _MyReviewsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _MyReviewsError({required this.onRetry});

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
              'טעינת הביקורות נכשלה',
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
