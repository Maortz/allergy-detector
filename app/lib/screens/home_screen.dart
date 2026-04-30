import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_badge.dart';
import '../widgets/allergen_chip.dart';
import '../widgets/bento_card.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;
  final VoidCallback onScanTap;
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;
  final VoidCallback? onMenuTap;

  const HomeScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
    required this.onScanTap,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.onMenuTap,
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

  String get _userName => 'משתמש';

  List<Allergen> get _selectedAllergens {
    return widget.allergens
        .where((a) => widget.userProfile.selectedAllergenIds.contains(a.id))
        .toList();
  }

  final List<_RecentActivity> _mockRecentActivity = [
    _RecentActivity(
      name: 'חלב שולו 5%',
      brand: 'שולו',
      imageUrl: null,
      time: 'לפני 2 שעות',
      status: AllergenStatus.safe,
    ),
    _RecentActivity(
      name: 'לחם מחמצת',
      brand: 'לחמייה',
      imageUrl: null,
      time: 'אתמול',
      status: AllergenStatus.caution,
    ),
    _RecentActivity(
      name: 'שוקולד מריר',
      brand: 'פרלינה',
      imageUrl: null,
      time: 'לפני 3 ימים',
      status: AllergenStatus.avoid,
    ),
  ];

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
            _buildSafetyStatusCard(),
            const SizedBox(height: AppSpacing.md),
            _buildQuickScanCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentActivitySection(),
            const SizedBox(height: AppSpacing.lg),
            _buildBentoGrid(),
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
          style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          _userName,
          style: AppTypography.h1.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }

  Widget _buildSafetyStatusCard() {
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
          if (_selectedAllergens.isEmpty)
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
              children: _selectedAllergens
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פעילות אחרונה',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._mockRecentActivity.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RecentActivityCard(activity: activity),
            )),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'סטטיסטיקות',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: BentoCard(
                label: 'סריקות היום',
                value: '12',
                icon: Icons.qr_code_scanner,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: BentoCard(
                label: 'בטוחים',
                value: '8',
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: BentoCard(
                label: 'הימנע',
                value: '2',
                icon: Icons.dangerous,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: BentoCard(
                label: 'זהירות',
                value: '2',
                icon: Icons.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentActivity {
  final String name;
  final String brand;
  final String? imageUrl;
  final String time;
  final AllergenStatus status;

  const _RecentActivity({
    required this.name,
    required this.brand,
    this.imageUrl,
    required this.time,
    required this.status,
  });
}

class _RecentActivityCard extends StatelessWidget {
  final _RecentActivity activity;

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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: activity.imageUrl != null
                ? Image.network(
                    activity.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.shopping_basket,
                      color: Colors.grey[400],
                    ),
                  )
                : Icon(
                    Icons.shopping_basket,
                    color: Colors.grey[400],
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
