import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_badge.dart';
import '../widgets/allergen_chip.dart';
import '../widgets/skeleton_box.dart';

/// A single past-scan entry shown in the "פעילות אחרונה" section.
///
/// Exported so callers (e.g. `MainContainer` / future `ScanHistory` plumbing)
/// can build the activity list. Spec ref: `home-dashboard.md §5` / §6.
@immutable
class RecentActivity {
  final String name;
  final String brand;
  final String? imageUrl;
  final String time;
  final AllergenStatus status;

  const RecentActivity({
    required this.name,
    required this.brand,
    this.imageUrl,
    required this.time,
    required this.status,
  });
}

class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;
  final VoidCallback onScanTap;
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;
  final VoidCallback? onMenuTap;

  /// Recent scans to render under "פעילות אחרונה", supplied by the host from
  /// real `ScanHistoryService` data. When `null` (still loading) or empty (no
  /// scans yet), the no-scans empty state is rendered — there is no mock
  /// fallback (issue #261). Spec ref: `home-dashboard.md §5` ("Empty activity").
  final List<RecentActivity>? recentActivity;

  /// When `true`, the hero card and activity list render shimmer skeletons.
  /// Spec ref: `home-dashboard.md §5` ("Loading").
  final bool isLoading;

  const HomeScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
    required this.onScanTap,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.onMenuTap,
    this.recentActivity,
    this.isLoading = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'בוקר טוב';
    if (hour < 17) return 'צהריים טובים';
    return 'ערב טוב';
  }

  String get _userName => widget.userProfile.displayName ?? 'משתמש';

  List<Allergen> _selectedAllergens() {
    return widget.allergens
        .where((a) => widget.userProfile.selectedAllergenIds.contains(a.id))
        .toList();
  }

  /// Activity to render before per-status filtering. `null`/absent means no
  /// scans yet → empty list (the no-scans empty state). Spec ref:
  /// `home-dashboard.md §5`.
  List<RecentActivity> get _sourceActivity =>
      widget.recentActivity ?? const <RecentActivity>[];

  /// [_sourceActivity] narrowed to the rows the user's [ProductFilterLevel]
  /// allows (#41).
  List<RecentActivity> get _visibleActivity {
    final level = widget.userProfile.productFilterLevel;
    return _sourceActivity.where((a) => level.allows(a.status)).toList();
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
            _buildWelcomeSection(),
            const SizedBox(height: AppSpacing.lg),
            if (widget.isLoading)
              const _SafetyStatusSkeleton()
            else
              _buildSafetyStatusCard(),
            const SizedBox(height: AppSpacing.md),
            _buildQuickScanCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentActivitySection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting,',
          style:
              AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          _userName,
          style: AppTypography.h1.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }

  Widget _buildSafetyStatusCard() {
    final selected = _selectedAllergens();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.safeBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.safeText.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppColors.safeText),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'הפרופיל שלך פעיל',
                style: AppTypography.h3.copyWith(color: AppColors.safeText),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (selected.isEmpty)
            Text(
              'לא נבחרו אלרגנים',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: selected
                  .map((a) => AllergenChip(
                        label: a.nameHe,
                        isSelected: true,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickScanCard() {
    return InkWell(
      onTap: widget.onScanTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
              child: Icon(
                Icons.qr_code_scanner,
                color: AppColors.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'סריקה מהירה',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.onPrimaryFixed,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'בדוק מוצר חדש עכשיו',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onPrimaryFixedVariant,
                    ),
                  ),
                ],
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

  Widget _buildRecentActivitySection() {
    final source = _sourceActivity;
    final visible = _visibleActivity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פעילות אחרונה',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.isLoading)
          const _RecentActivitySkeleton()
        else if (source.isEmpty)
          // No scans yet — distinct from "filter hid everything".
          const _RecentActivityEmpty()
        else if (visible.isEmpty)
          // There is activity, but the active filter hides all of it (#41).
          const _RecentActivityFilteredEmpty()
        else
          ...visible.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RecentActivityCard(activity: item),
              )),
      ],
    );
  }

}

class _RecentActivityCard extends StatelessWidget {
  final RecentActivity activity;

  const _RecentActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: activity.imageUrl != null
                ? Image.network(
                    activity.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.shopping_basket,
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    Icons.shopping_basket,
                    color: AppColors.onSurfaceVariant,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  activity.brand,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: activity.status),
              const SizedBox(height: AppSpacing.xs),
              Text(
                activity.time,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty state for "פעילות אחרונה" when the user has never scanned anything.
/// Spec: `home-dashboard.md §5`.
class _RecentActivityEmpty extends StatelessWidget {
  const _RecentActivityEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 48,
            color: AppColors.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'טרם סרקת מוצרים',
            textAlign: TextAlign.center,
            style: AppTypography.labelBold
                .copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'הסריקות שתבצע יופיעו כאן',
            textAlign: TextAlign.center,
            style: AppTypography.labelSm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Shown when there is recent activity but the active [ProductFilterLevel]
/// hides every row (#41).
class _RecentActivityFilteredEmpty extends StatelessWidget {
  const _RecentActivityFilteredEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_outlined,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'אין מוצרים העונים על המסנן',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the hero/safety card on initial load.
class _SafetyStatusSkeleton extends StatelessWidget {
  const _SafetyStatusSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 180, height: 18),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SkeletonBox(width: 64, height: 28, borderRadius: 14),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 64, height: 28, borderRadius: 14),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 64, height: 28, borderRadius: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholders for three activity rows during initial load.
class _RecentActivitySkeleton extends StatelessWidget {
  const _RecentActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: _ActivityRowSkeleton(),
        ),
      ),
    );
  }
}

class _ActivityRowSkeleton extends StatelessWidget {
  const _ActivityRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          SkeletonBox(width: 48, height: 48, borderRadius: 8),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 56, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}
