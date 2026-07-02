import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/grid_layout.dart';
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
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: cs.surface,
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
                      color: cs.onSurfaceVariant,
                      tooltip: 'סגור',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      'SafeBite',
                      style: AppTypography.labelMd.copyWith(
                        color: cs.primary,
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
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'בחרו את האלרגנים שאתם רוצים להימנע מהם ואנחנו נוודא שתמיד תדעו מה בטוח לאכול.',
                      style: AppTypography.bodySm.copyWith(
                        color: cs.onSurfaceVariant,
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
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'בחרו אלרגנים ($_selectedCount נבחרו)',
                          style: AppTypography.labelSm.copyWith(
                            color: _selectedCount > 0
                                ? cs.primary
                                : cs.onSurfaceVariant,
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
                        backgroundColor: cs.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
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
                    color: cs.surfaceContainerLow,
                    child: Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: cs.primaryFixed,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.margin,
                      ),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            allergenGridColumns(constraints.maxWidth),
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
                    color: cs.onSurfaceVariant,
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
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      disabledBackgroundColor: cs.surfaceContainerHigh,
                      disabledForegroundColor: cs.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'המשך',
                      style: AppTypography.labelBold.copyWith(
                        color: _selectedCount > 0
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
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
