import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class OnboardingStep2Screen extends StatefulWidget {
  final UserProfile userProfile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const OnboardingStep2Screen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  late TextEditingController _nameController;
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userProfile.displayName ?? '',
    );
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    if (status.isGranted) setState(() => _notifGranted = true);
  }

  void _complete() {
    final updated = widget.userProfile.copyWith(
      displayName: _nameController.text.trim(),
      hasCompletedOnboarding: true,
    );
    widget.onProfileUpdated(updated);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 1. Brand header row
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.lg,
                  AppSpacing.margin,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SafeBite',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 2. Headline block
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'כמעט סיימנו!',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'השלם את הפרופיל שלך כדי לקבל חוויה מותאמת אישית.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Step counter row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'שלב 2 מתוך 2',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '100% הושלם',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Name field
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.lg,
                  AppSpacing.margin,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'מה השם שלך?',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        hintText: 'הקלד את שמך',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Notification block
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.lg,
                  AppSpacing.margin,
                  0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'התראות חכמות',
                        style: AppTypography.labelBold.copyWith(
                          color: AppColors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'קבל התראות כשמצאנו מוצר חדש שעלול לסכן אותך.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      if (_notifGranted)
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('אושר'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF15803D),
                            backgroundColor: const Color(0xFFDCFCE7),
                            side: const BorderSide(
                              color: Color(0xFF16A34A),
                              width: 1.5,
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _requestNotifications,
                          icon: const Icon(Icons.notifications_none, size: 18),
                          label: const Text('אפשר התראות'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 6. Spacer
              const SizedBox(height: AppSpacing.lg),

              // 7. "סיים" CTA
              Padding(
                padding: const EdgeInsets.all(AppSpacing.margin),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _complete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      disabledForegroundColor: AppColors.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text('סיים', style: AppTypography.labelBold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
