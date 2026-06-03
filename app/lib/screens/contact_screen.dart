import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bottom_nav_bar.dart';

class ContactScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;

  const ContactScreen({
    super.key,
    this.onNavTap,
  });

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          'צור קשר',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _submitted
            ? _ContactSuccessView(onReturnHome: _returnHome)
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNameField(),
                    const SizedBox(height: AppSpacing.md),
                    _buildEmailField(),
                    const SizedBox(height: AppSpacing.md),
                    _buildMessageField(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSubmitButton(),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: widget.onNavTap ?? (_) {},
      ),
    );
  }

  void _returnHome() {
    // Reset the form before leaving so the tab-host branch (where this screen
    // stays mounted inside an IndexedStack and `canPop()` is false) shows a
    // fresh form on the next visit instead of the stale success view.
    setState(() {
      _submitted = false;
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    });
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onNavTap?.call(0);
    }
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'שם מלא',
          style: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _nameController,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.right,
          decoration: _buildInputDecoration(
            hint: 'הזן את שמך',
            prefixIcon: Icons.person_outline,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'נא להזין שם';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'דוא"ל',
          style: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _emailController,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.right,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            hint: 'הזן את הדוא"ל שלך',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'נא להזין דוא"ל';
            }
            if (!value.contains('@')) {
              return 'נא להזין דוא"ל תקין';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הודעה',
          style: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _messageController,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.right,
          maxLines: 5,
          decoration: _buildInputDecoration(
            hint: 'כתוב את ההודעה שלך...',
            prefixIcon: Icons.message_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'נא להזין הודעה';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      filled: true,
      fillColor: AppColors.surfaceContainer,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Icon(prefixIcon, color: AppColors.onSurfaceVariant, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    // No backend yet — show the in-place success state per
    // `contact-us.md §5.5`. When a real submit lands this will sit behind a
    // try/finally around `ContactService.submit(...)`.
    setState(() => _submitted = true);
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _onSubmit,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'שלח הודעה',
        style: AppTypography.labelBold.copyWith(
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

/// In-place success state shown after a successful contact submission.
/// Spec ref: `contact-us.md §5.5`.
class _ContactSuccessView extends StatelessWidget {
  final VoidCallback onReturnHome;

  const _ContactSuccessView({required this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: AppColors.safeText,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ההודעה נשלחה בהצלחה!',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'נחזור אליכם בהקדם האפשרי.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onReturnHome,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'חזרה לדף הבית',
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}