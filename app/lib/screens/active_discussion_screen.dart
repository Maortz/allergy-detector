import 'package:flutter/material.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('דיון פעיל'),
          backgroundColor: colorScheme.surfaceContainer,
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
                color: colorScheme.primaryFixed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'דיון פעיל',
                    style: AppTypography.labelSm.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _title,
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _body,
              style: AppTypography.bodyMd.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'תגובות לדיון יהיו זמינות בגרסה הבאה',
                      style: AppTypography.labelSm.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
