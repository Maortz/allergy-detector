import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('העדפות אפליקציה'),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            _PreferenceSection(
              title: 'הצגה',
              children: [
                _PreferenceRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'מצב כהה',
                  subtitle: 'יותאם בקרוב',
                ),
                _PreferenceRow(
                  icon: Icons.text_fields,
                  label: 'גודל טקסט',
                  subtitle: 'ברירת מחדל',
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            _PreferenceSection(
              title: 'התראות',
              children: [
                _PreferenceRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'התראות על מוצרים חדשים',
                  subtitle: 'כבוי',
                ),
                _PreferenceRow(
                  icon: Icons.update,
                  label: 'עדכוני אלרגנים',
                  subtitle: 'מופעל',
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            _PreferenceSection(
              title: 'נתונים',
              children: [
                _PreferenceRow(
                  icon: Icons.cached,
                  label: 'נקה מטמון חיפוש',
                  subtitle: 'מתעדכן אוטומטית',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreferenceSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            title,
            style: AppTypography.labelBold.copyWith(color: AppColors.primary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
      ),
      title: Text(
        label,
        style: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left,
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}
