import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/allergen_card.dart';
import '../widgets/state_view.dart';

class AllergenManagementScreen extends StatefulWidget {
  final List<Allergen> allergens;
  final UserProfile userProfile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const AllergenManagementScreen({
    super.key,
    required this.allergens,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<AllergenManagementScreen> createState() =>
      _AllergenManagementScreenState();
}

class _AllergenManagementScreenState extends State<AllergenManagementScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.userProfile;
  }

  void _toggle(Allergen allergen) {
    setState(() => _profile = _profile.toggleAllergen(allergen));
    widget.onProfileUpdated(_profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'נהל אלרגיות',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // An empty injected catalog means the Supabase fetch returned nothing or
      // failed upstream (see main.dart — a post-onboarding load error is
      // swallowed). Render an explicit error/empty state instead of a blank
      // grid (issue #256).
      body: widget.allergens.isEmpty ? _buildEmptyState() : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return const StateView(
      icon: Icons.error_outline,
      title: 'לא ניתן לטעון את רשימת האלרגנים',
      message: 'בדקו את החיבור לאינטרנט ונסו שוב מאוחר יותר.',
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin, 12, AppSpacing.margin, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'אלרגנים פעילים: ${_profile.selectedAllergenIds.length}',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            itemCount: widget.allergens.length,
            itemBuilder: (context, index) {
              final allergen = widget.allergens[index];
              return AllergenCard(
                allergen: allergen,
                isSelected: _profile.isAllergenSelected(allergen.id),
                onTap: () => _toggle(allergen),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.margin, 0, AppSpacing.margin, 12),
            child: Text(
              'השינויים נשמרים אוטומטית',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
