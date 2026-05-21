import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../screens/allergen_management_screen.dart';
import '../utils/app_dialogs.dart';
import '../widgets/profile_edit_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;
  final VoidCallback? onContactTap;
  final VoidCallback? onAdminBrandsTap;

  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.onContactTap,
    this.onAdminBrandsTap,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _openProfileEdit() async {
    final result = await showProfileEditSheet(context, widget.userProfile);
    if (result != null) widget.onProfileUpdated(result);
  }

  void _logout() {
    widget.onProfileUpdated(const UserProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildFilterSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildNavMenu(),
            const SizedBox(height: AppSpacing.lg),
            _buildLogoutButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

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
                child: const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryFixed,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.onPrimaryFixed,
                  ),
                ),
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
            widget.userProfile.displayName ?? 'משתמש',
            style: AppTypography.h1.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.userProfile.email ?? '',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '24',
                        style: AppTypography.labelBold.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'סריקות השבוע',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      'הצג רק מוצרים בטוחים',
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterOption('לא בטוח', 'מכיל אלרגנים', false),
                ),
                Expanded(
                  child: _buildFilterOption('בטוח חלקית', 'עשוי להכיל', false),
                ),
                Expanded(
                  child: _buildFilterOption('בטוח לחלוטין', 'ללא חשש עקבות', true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, String subtitle, bool isSelected) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTypography.labelBold.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
            onTap: () {},
          ),
          _buildDivider(),
          _buildNavTile(
            icon: Icons.volunteer_activism,
            label: 'היסטוריית תרומות',
            iconBgColor: AppColors.surfaceContainerLow,
            iconColor: AppColors.onSurfaceVariant,
            onTap: () {},
          ),
          _buildDivider(),
          _buildNavTile(
            icon: Icons.help_center,
            label: 'מרכז עזרה',
            iconBgColor: AppColors.surfaceContainerLow,
            iconColor: AppColors.onSurfaceVariant,
            onTap: widget.onContactTap ?? () {},
          ),
          _buildDivider(),
          _buildNavTile(
            icon: Icons.store,
            label: 'נהל מותגים',
            iconBgColor: AppColors.surfaceContainerLow,
            iconColor: AppColors.onSurfaceVariant,
            onTap: widget.onAdminBrandsTap ?? () {},
          ),
          _buildDivider(),
          _buildNavTile(
            icon: Icons.info,
            label: 'אודות',
            iconBgColor: AppColors.surfaceContainerLow,
            iconColor: AppColors.onSurfaceVariant,
            onTap: () {},
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
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
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
      child: OutlinedButton.icon(
        onPressed: () => showLogoutDialog(context, onConfirmed: _logout),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: Text(
          'התנתק מהחשבון',
          style: AppTypography.labelBold,
        ),
      ),
    );
  }
}