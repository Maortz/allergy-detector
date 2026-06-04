import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ActiveDiscussionScreen extends StatelessWidget {
  const ActiveDiscussionScreen({super.key});

  static const String _title =
      'תחליפי חלב חדשים בשוק - האם הם בטוחים לאלרגיים לחלבון חלב?';
  static const String _body =
      'בשנים האחרונות הצטרפו לשוק תחליפי חלב רבים על בסיס שיבולת שועל, סויה, אורז ושקדים. '
      'עבור אנשים עם אלרגיה לחלבון חלב, חשוב לבדוק לא רק שהמוצר אינו מכיל חלב, אלא גם '
      'שלא קיים זיהום צולב בקו הייצור. שתפו אותנו בניסיון שלכם — אילו תחליפים עברו אצלכם בשלום?';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('דיון פעיל'),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'דיון פעיל',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _title,
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _body,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'תגובות לדיון יהיו זמינות בגרסה הבאה',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
