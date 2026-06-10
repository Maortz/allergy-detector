import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AboutScreen extends StatefulWidget {
  static const String appName = 'בטוח לאכול';

  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  /// Real app version resolved from [PackageInfo.fromPlatform]; null until the
  /// platform-channel round-trip completes, so the version row is omitted until
  /// then rather than flashing a stale literal (nav-drawer-user.md §4.4).
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('אודות'),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AboutScreen.appName,
              style: AppTypography.h2.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            if (_appVersion != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'גרסה $_appVersion',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'אודות האפליקציה',
              body:
                  'בטוח לאכול עוזרת לאנשים עם אלרגיות לזהות בקלות מוצרים שאינם בטוחים עבורם, באמצעות סריקת ברקודים וקטלוג מוצרים מוקפד שמתוחזק על־ידי הקהילה.',
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: 'הצהרת אחריות',
              body:
                  'המידע באפליקציה ניתן ככלי עזר בלבד ואינו מחליף בדיקת תוויות המוצר או ייעוץ רפואי. ייתכנו שינויים ברכיבי המוצר על־ידי היצרן.',
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: 'קרדיטים',
              body: 'פותח באהבה לקהילת האלרגיים בישראל.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
