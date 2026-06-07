import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class WeeklyTipScreen extends StatelessWidget {
  const WeeklyTipScreen({super.key});

  static const String _title =
      'איך לקרוא תוויות של יצרנים בינלאומיים בצורה בטוחה ומדויקת';
  static const String _intro =
      'מוצרים מיובאים נושאים תוויות בשפות שונות וברגולציות שונות. כך תזהו אלרגנים גם כשהשפה לא מוכרת לכם:';

  static const List<String> _bullets = [
    'חפשו את שמות האלרגנים המודגשים — באיחוד האירופי הם חייבים להופיע ב־bold או בקו תחתון.',
    'הכירו את שמות האלרגנים באנגלית: milk, eggs, peanuts, tree nuts, soy, wheat, fish, shellfish, sesame.',
    'אם רשום "may contain" — מדובר באזהרת זיהום צולב, לא בהכרח שהמוצר מכיל את האלרגן.',
    'תוויות ביפנית או בקוריאנית — חפשו את הסימן המסחרי של היצרן ובדקו את אתר היצרן הרשמי.',
    'במקרה של ספק — נסו לסרוק את הברקוד באפליקציה, או דווחו על המוצר לקהילה.',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('טיפ השבוע'),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'טיפ השבוע',
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _title,
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _intro,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._bullets.map((bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BulletRow(text: bullet),
                )),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;

  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
