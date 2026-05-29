import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/pending_review.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/bento_card.dart';
import 'community_review_screen.dart';

class CommunityScreen extends StatefulWidget {
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;

  /// Overrides the default "התחל בבדיקה" handler. When null the screen
  /// pushes [CommunityReviewScreen] itself (with a debug-only stub queue —
  /// release builds get an empty queue and land on the §7.3 empty state until
  /// the live controller from #54 is wired in).
  final VoidCallback? onStartReview;

  const CommunityScreen({
    super.key,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.onStartReview,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  void _onStartReview() {
    final override = widget.onStartReview;
    if (override != null) {
      override();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityReviewScreen(
          queue: kDebugMode ? _debugStubQueue : const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(),
            const SizedBox(height: AppSpacing.lg),
            _buildStatsBento(),
            const SizedBox(height: AppSpacing.lg),
            _buildHelpCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildPeerReviewCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildTipsSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הכוח שלנו הוא בידע',
          style: AppTypography.h1.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'יחד אנחנו בונים מאגר מזון בטוח לכולם',
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBento() {
    return Row(
      children: [
        Expanded(
          child: BentoCard(
            label: 'אומתו בהצלחה',
            value: '5',
            icon: Icons.verified,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: BentoCard(
            label: 'מוצרים נוספו',
            value: '2',
            icon: Icons.add_shopping_cart,
          ),
        ),
      ],
    );
  }

  Widget _buildHelpCard() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add, color: AppColors.onPrimary, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'הוספת מוצר חדש',
                style: AppTypography.h3.copyWith(
                  color: AppColors.onPrimaryFixed,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.onPrimaryFixedVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerReviewCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // Hardcoded "12 …" promised data the empty state doesn't
                  // have — drop the count until #54 (live `pending_reviews`
                  // controller) lands. CH8 spec also flags the literal as a
                  // divergence; live count replacement stays with #54.
                  'מוצרים ממתינים לבדיקה',
                  style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                ),
              ),
              FilledButton(
                onPressed: _onStartReview,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text('התחל בבדיקה', style: AppTypography.labelBold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'טיפ השבוע',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'בדוק את הרכיבים הפעילים',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'לפעמים אלרגנים מסתתרים בשמות לא צפויים',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.forum, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'דיון פעיל',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'האם "סירופ תירס" מכיל גלוטן?',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }
}

// Sample queue used only in `kDebugMode` so contributors can exercise the
// Community Review flow end-to-end without #54 (controller + `pending_reviews`
// table) in place. Release builds skip this and land on the §7.3 empty state.
const List<PendingReview> _debugStubQueue = [
  PendingReview(
    id: 'stub-1',
    productId: 'stub-product-1',
    productName: 'משקה שיבולת שועל אורגני',
    brandName: 'EcoNature',
    categoryLabel: 'חלב ומשקאות',
    allergenReports: [
      AllergenReport(
        allergen: Allergen(id: 'gluten', nameHe: 'גלוטן'),
        status: AllergenReportStatus.contains,
      ),
      AllergenReport(
        allergen: Allergen(id: 'nuts', nameHe: 'אגוזים'),
        status: AllergenReportStatus.mayContain,
      ),
      AllergenReport(
        allergen: Allergen(id: 'milk', nameHe: 'חלב'),
        status: AllergenReportStatus.absent,
      ),
    ],
    contributorNote: 'הסריקה בוצעה במכולת השכונתית, התווית בעברית בלבד.',
  ),
];
