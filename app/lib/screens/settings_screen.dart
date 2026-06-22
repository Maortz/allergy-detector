import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../screens/about_screen.dart';
import '../screens/allergen_management_screen.dart';
import '../screens/app_preferences_screen.dart';
import '../screens/contribution_history_screen.dart';
import '../utils/app_dialogs.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/skeleton_box.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;
  final VoidCallback? onContactTap;
  final VoidCallback? onAdminBrandsTap;

  /// Current appearance preference shown as selected in the appearance picker
  /// (issue #168). Defaults to [ThemeMode.system].
  final ThemeMode themeMode;

  /// Invoked when the user picks Light / Dark / System. When null, the
  /// appearance section is hidden (e.g. widget tests that don't wire theming).
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  /// When `true`, the profile block renders shimmer skeletons in place of the
  /// avatar / name / email. Spec ref: `settings-profile.md §5.7`
  /// ("Error / no-profile state"). This is meant to be transient while
  /// SharedPreferences resolves.
  final bool isLoading;

  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.onContactTap,
    this.onAdminBrandsTap,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
    this.isLoading = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile _userProfile;

  // Local mirror of the appearance preference (issue #257). SettingsScreen is
  // pushed as a MaterialPageRoute (not a bottom-nav tab), so when MyApp rebuilds
  // its `home` after a theme change the pushed route keeps a stale `themeMode`
  // prop. Tracking the selection in local state — set optimistically on tap and
  // re-synced from the prop when it does change — keeps the highlight correct
  // regardless of whether the prop refreshes.
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _userProfile = widget.userProfile;
    _themeMode = widget.themeMode;
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      _userProfile = widget.userProfile;
    }
    if (oldWidget.themeMode != widget.themeMode) {
      _themeMode = widget.themeMode;
    }
  }

  Future<void> _openProfileEdit() async {
    final result = await showProfileEditSheet(context, _userProfile);
    if (!mounted) return;
    if (result != null) {
      setState(() => _userProfile = result);
      widget.onProfileUpdated(result);
    }
  }

  void _logout() {
    widget.onProfileUpdated(const UserProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainer,
        appBar: AppBar(
          title: Text(
            'פרופיל',
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              if (widget.isLoading)
                const _ProfileSkeleton()
              else
                _buildProfileSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildFilterSection(),
              if (widget.onThemeModeChanged != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildAppearanceSection(),
              ],
              const SizedBox(height: AppSpacing.lg),
              _buildNavMenu(),
              const SizedBox(height: AppSpacing.lg),
              _buildLogoutButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile-view avatar: renders the saved base64 [UserProfile.avatarData]
  /// when present (issue #260), otherwise a default person-icon placeholder.
  Widget _buildAvatar() {
    final String? data = _userProfile.avatarData;
    if (data != null && data.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(data),
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _personPlaceholder(),
          ),
        );
      } on FormatException {
        // Stored value is not valid base64 (e.g. partial/corrupted write or a
        // future migration with a different encoding) — treat it like no
        // picture and show the placeholder (issue #260 AC3).
      }
    }
    return _personPlaceholder();
  }

  Widget _personPlaceholder() => const CircleAvatar(
        radius: 44,
        backgroundColor: AppColors.primaryFixed,
        child: Icon(Icons.person, size: 48, color: AppColors.onPrimaryFixed),
      );

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildAvatar(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: _openProfileEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _userProfile.displayName ?? 'משתמש',
            style: AppTypography.h1.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _userProfile.email ?? '',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _openProfileEdit,
            icon: const Icon(Icons.edit, size: 14, color: AppColors.primary),
            label: Text(
              'ערוך פרופיל',
              style: AppTypography.labelBold.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'רמת סינון מוצרים',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'סנן מוצרים לפי האלרגיות שלך',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildFilterOption(
                  'לא בטוח מכיל אלרגנים',
                  ProductFilterLevel.showAll,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFilterOption(
                  'בטוח חלקית עשוי להכיל',
                  ProductFilterLevel.cautionAndAbove,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFilterOption(
                  'בטוח לחלוטין ללא חשש עקבות',
                  ProductFilterLevel.safeOnly,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onFilterSelected(ProductFilterLevel level) {
    if (_userProfile.productFilterLevel == level) return;
    final updated = _userProfile.copyWith(productFilterLevel: level);
    setState(() => _userProfile = updated);
    widget.onProfileUpdated(updated);
  }

  Widget _buildFilterOption(String label, ProductFilterLevel level) {
    final isSelected = _userProfile.productFilterLevel == level;
    final (background, foreground) = switch (level) {
      ProductFilterLevel.showAll => (
        AppColors.avoidBackground,
        AppColors.avoidText,
      ),
      ProductFilterLevel.cautionAndAbove => (
        AppColors.cautionBackground,
        AppColors.cautionText,
      ),
      ProductFilterLevel.safeOnly => (
        AppColors.safeBackground,
        AppColors.safeText,
      ),
    };

    return GestureDetector(
      onTap: () => _onFilterSelected(level),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? background : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? foreground : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: AppTypography.labelSm.copyWith(
            color: isSelected ? foreground : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _onAppearanceSelected(ThemeMode mode) {
    final handler = widget.onThemeModeChanged;
    if (handler == null || mode == _themeMode) return;
    // Update the highlight optimistically — the pushed Settings route may not
    // receive a refreshed `themeMode` prop when MyApp rebuilds its home.
    setState(() => _themeMode = mode);
    handler(mode);
  }

  /// Appearance picker (Light / Dark / System) — issue #168. Persistence and
  /// the live [ThemeMode] swap happen up in `MyApp`; this only surfaces the
  /// choice. Hidden entirely when [SettingsScreen.onThemeModeChanged] is null.
  Widget _buildAppearanceSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.brightness_6, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'מראה',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'בהיר, כהה או לפי מערכת ההפעלה',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildAppearanceOption('בהיר', ThemeMode.light)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildAppearanceOption('כהה', ThemeMode.dark)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildAppearanceOption('מערכת', ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceOption(String label, ThemeMode mode) {
    final isSelected = _themeMode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _onAppearanceSelected(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelSm.copyWith(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNavMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNavTile(
            icon: Icons.medical_services,
            label: 'נהל אלרגיות',
            iconBgColor: AppColors.primaryFixed,
            iconColor: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllergenManagementScreen(
                  allergens: widget.allergens,
                  userProfile: widget.userProfile,
                  onProfileUpdated: widget.onProfileUpdated,
                ),
              ),
            ),
          ),
          _buildDivider(),
          _buildNavTile(
            icon: Icons.settings_suggest,
            label: 'העדפות אפליקציה',
            iconBgColor: AppColors.surfaceContainerLow,
            iconColor: AppColors.onSurfaceVariant,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppPreferencesScreen(),
              ),
            ),
          ),
          _buildDivider(),
          _buildNavTile(
            icon: Icons.volunteer_activism,
            label: 'היסטוריית תרומות',
            iconBgColor: AppColors.safeBackground,
            iconColor: AppColors.safeText,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContributionHistoryScreen(),
              ),
            ),
          ),
          _buildDivider(),
          _buildNavTile(
            icon: Icons.help_center,
            label: 'מרכז עזרה',
            iconBgColor: AppColors.cautionBackground,
            iconColor: AppColors.cautionText,
            onTap: widget.onContactTap ?? () {},
          ),
          if (widget.userProfile.isAdmin) ...[
            _buildDivider(),
            _buildNavTile(
              icon: Icons.store,
              label: 'נהל מותגים',
              iconBgColor: AppColors.surfaceContainerLow,
              iconColor: AppColors.onSurfaceVariant,
              onTap: widget.onAdminBrandsTap ?? () {},
            ),
          ],
          _buildDivider(),
          _buildNavTile(
            icon: Icons.info,
            label: 'אודות',
            iconBgColor: AppColors.surfaceContainerLow,
            iconColor: AppColors.onSurfaceVariant,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: AppColors.surfaceContainerHigh,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => showLogoutDialog(context, onConfirmed: _logout),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.avoidBackground,
          foregroundColor: AppColors.avoidText,
          side: const BorderSide(color: AppColors.avoidText, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: Text(
          'התנתק מהחשבון',
          style: AppTypography.labelBold.copyWith(color: AppColors.avoidText),
        ),
      ),
    );
  }
}

/// Transient skeleton for the profile block while `UserProfile` is still
/// resolving from SharedPreferences. Spec ref: `settings-profile.md §5.7`.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: const [
          SkeletonBox(width: 96, height: 96, borderRadius: 48),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: 160, height: 20),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 200, height: 14),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 12),
        ],
      ),
    );
  }
}
