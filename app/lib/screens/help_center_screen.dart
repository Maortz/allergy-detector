import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class HelpCenterScreen extends StatelessWidget {
  final VoidCallback? onContactTap;

  const HelpCenterScreen({super.key, this.onContactTap});

  static const List<_HelpItem> _faqs = [
    _HelpItem(
      question: 'איך סורקים מוצר?',
      answer:
          'פתח את לשונית הסריקה, יישר את הברקוד בתוך המסגרת והמתן לקריאה אוטומטית.',
    ),
    _HelpItem(
      question: 'איך מעדכנים את רשימת האלרגיות שלי?',
      answer:
          'גש להגדרות ← נהל אלרגיות, ובחר או הסר אלרגנים מהרשימה. השינויים נשמרים מיידית.',
    ),
    _HelpItem(
      question: 'מה המשמעות של צבעי הסטטוס?',
      answer:
          'ירוק = בטוח, כתום = ייתכנו עקבות (זהירות), אדום = מכיל אלרגן שסימנת והאפליקציה ממליצה להימנע.',
    ),
    _HelpItem(
      question: 'המוצר שחיפשתי לא נמצא — מה לעשות?',
      answer:
          'אפשר להוסיף מוצר חדש ממסך הסריקה. תרומתך תעזור לכלל הקהילה.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('מרכז עזרה'),
          backgroundColor: colorScheme.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'שאלות נפוצות',
              style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._faqs.map((item) => _FaqTile(item: item)),
            if (onContactTap != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onContactTap,
                icon: const Icon(Icons.support_agent),
                label: const Text('פנה אלינו'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;

  const _HelpItem({required this.question, required this.answer});
}

class _FaqTile extends StatelessWidget {
  final _HelpItem item;

  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            item.question,
            style: AppTypography.labelBold.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                item.answer,
                style: AppTypography.bodyMd.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
