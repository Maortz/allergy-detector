import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class ScanInstructionsScreen extends StatelessWidget {
  const ScanInstructionsScreen({super.key});

  static const List<_Step> _steps = [
    _Step(
      number: '1',
      title: 'פתח את לשונית הסריקה',
      body: 'הקש על כפתור הסריקה במרכז סרגל הניווט התחתון.',
    ),
    _Step(
      number: '2',
      title: 'מקם את הברקוד במסגרת',
      body: 'החזק את הטלפון במרחק של כ־15 ס״מ מהמוצר, ויישר את הברקוד בתוך המסגרת הכחולה.',
    ),
    _Step(
      number: '3',
      title: 'המתן לקריאה אוטומטית',
      body: 'הסריקה מתבצעת אוטומטית — אין צורך ללחוץ. תוצאות החיפוש יוצגו מיד.',
    ),
    _Step(
      number: '4',
      title: 'תאורה לא טובה?',
      body: 'הפעל את הפנס באמצעות הכפתור בתחתית מסך הסריקה.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('הוראות סריקה'),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'איך לסרוק מוצר',
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'סריקה מדויקת מבטיחה זיהוי מהיר של אלרגנים. בצע את השלבים הבאים:',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _StepCard(step: step),
                )),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final String number;
  final String title;
  final String body;

  const _Step({
    required this.number,
    required this.title,
    required this.body,
  });
}

class _StepCard extends StatelessWidget {
  final _Step step;

  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              step.number,
              style: AppTypography.labelBold.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  step.body,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
