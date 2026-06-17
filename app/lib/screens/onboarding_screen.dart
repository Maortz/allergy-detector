import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/allergen_card.dart';
import 'onboarding_step_2_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final List<Allergen> allergens;
  final UserProfile userProfile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const OnboardingScreen({
    super.key,
    required this.allergens,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.userProfile;
  }

  void _toggleAllergen(Allergen allergen) {
    setState(() {
      _profile = _profile.toggleAllergen(allergen);
    });
  }

  void _complete() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingStep2Screen(
          userProfile: _profile,
          onProfileUpdated: widget.onProfileUpdated,
        ),
      ),
    );
  }

  int get _selectedCount => _profile.selectedAllergenIds.length;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.sm,
                  AppSpacing.margin,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // RTL: children[0] renders at the visual right, children[1]
                  // at the visual left. Spec §4.1 wants ✕ at RTL-leading
                  // (visual right) and SafeBite at RTL-trailing (visual left).
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.onSurfaceVariant,
                      tooltip: 'סגור',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      'SafeBite',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.lg,
                  AppSpacing.margin,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ברוכים הבאים ל-SafeBite',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'בחרו את האלרגנים שאתם רוצים להימנע מהם ואנחנו נוודא שתמיד תדעו מה בטוח לאכול.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'שלב 1 מתוך 2',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'בחרו אלרגנים ($_selectedCount נבחרו)',
                          style: AppTypography.labelSm.copyWith(
                            color: _selectedCount > 0
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 192,
                child: Image.asset(
                  'assets/images/onboarding_hero.jpg',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: AppColors.primaryFixedDim,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.margin,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1,
                  ),
                  itemCount: widget.allergens.length,
                  itemBuilder: (context, index) {
                    final allergen = widget.allergens[index];
                    final isSelected =
                        _profile.isAllergenSelected(allergen.id);
                    return AllergenCard(
                      allergen: allergen,
                      isSelected: isSelected,
                      onTap: () => _toggleAllergen(allergen),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.md,
                  AppSpacing.margin,
                  AppSpacing.sm,
                ),
                child: Text(
                  'בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.margin),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        _selectedCount > 0 ? _complete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      disabledForegroundColor: AppColors.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'המשך',
                      style: AppTypography.labelBold.copyWith(
                        color: _selectedCount > 0
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}