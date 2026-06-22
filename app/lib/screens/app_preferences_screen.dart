import 'package:flutter/material.dart';
import '../services/search_cache.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// App-level preferences (settings-profile §4.3, issue #188).
///
/// Surfaces the user's notification preferences and a data-management action.
/// Push notifications are not implemented yet (issue #259), so the notification
/// toggles are rendered disabled with a "coming soon" caption rather than
/// exposing no-op controls. Clearing the search cache routes through
/// [SearchCache.clear]. Appearance / dark-mode lives in `SettingsScreen`
/// (issue #168) and is intentionally not duplicated here.
class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  Future<void> _onClearCache() async {
    try {
      await SearchCache.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('מטמון החיפוש נוקה'),
            duration: Duration(seconds: 2),
          ),
        );
    } catch (e) {
      debugPrint('clear-cache failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('לא ניתן לנקות את המטמון')),
        );
    }
  }

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
          children: [
            _PreferenceSection(
              title: 'התראות',
              children: const [
                _SwitchRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'התראות על מוצרים חדשים',
                  value: true,
                  onChanged: null,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.outlineVariant,
                ),
                _SwitchRow(
                  icon: Icons.update,
                  label: 'עדכוני אלרגנים',
                  value: true,
                  onChanged: null,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _ComingSoonCaption(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PreferenceSection(
              title: 'נתונים',
              children: [
                _ActionRow(
                  icon: Icons.cached,
                  label: 'נקה מטמון חיפוש',
                  onTap: _onClearCache,
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
        Material(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _PreferenceLeading extends StatelessWidget {
  final IconData icon;

  const _PreferenceLeading({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;

  /// `null` renders the switch disabled (greyed out / non-interactive).
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      secondary: _PreferenceLeading(icon: icon),
      title: Text(
        label,
        style: AppTypography.labelBold.copyWith(
          color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Caption shown under the disabled notification toggles explaining that push
/// notifications are not available yet (issue #259).
class _ComingSoonCaption extends StatelessWidget {
  const _ComingSoonCaption();

  @override
  Widget build(BuildContext context) {
    return Text(
      'הודעות יהיו זמינות בקרוב',
      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _PreferenceLeading(icon: icon),
      title: Text(
        label,
        style: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
      ),
      trailing: const Icon(
        Icons.chevron_left,
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}
