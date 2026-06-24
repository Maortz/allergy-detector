import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class HelpTipsScreen extends StatelessWidget {
  const HelpTipsScreen({super.key});

  static const List<_Tip> _tips = [
    _Tip(
      icon: Icons.fact_check_outlined,
      title: 'בדוק תמיד את רשימת הרכיבים המלאה',
      body:
          'גם כשמוצר מסומן כבטוח, מומלץ לוודא את רשימת הרכיבים המודפסת על האריזה — נוסחאות יצרנים משתנות מעת לעת.',
    ),
    _Tip(
      icon: Icons.warning_amber,
      title: 'שים לב לאזהרות "עשוי להכיל"',
      body:
          'אזהרות אלה מציינות זיהום צולב אפשרי. אם האלרגיה שלך חמורה — מומלץ להימנע גם ממוצרים אלה.',
    ),
    _Tip(
      icon: Icons.translate,
      title: 'מוצרי יבוא — בדוק את המקור',
      body:
          'מוצרים מיובאים עשויים להכיל אלרגנים בשמות שונים. השווה תמיד מול התווית בעברית.',
    ),
    _Tip(
      icon: Icons.update,
      title: 'נסה לסרוק שוב מדי פעם',
      body:
          'מידע המוצר מתעדכן באופן שוטף על־ידי הקהילה — סריקה חוזרת תוודא שאתה רואה את הנתונים העדכניים.',
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
          title: const Text('טיפים לבטיחות'),
          backgroundColor: colorScheme.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: _tips.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _TipCard(tip: _tips[index]),
        ),
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String body;

  const _Tip({required this.icon, required this.title, required this.body});
}

class _TipCard extends StatelessWidget {
  final _Tip tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryFixed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(tip.icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: AppTypography.labelBold.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tip.body,
                  style: AppTypography.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
