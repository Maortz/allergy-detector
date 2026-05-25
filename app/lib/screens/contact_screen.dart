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
        child: Form(
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

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('בקרוב — שליחת הודעות תתאפשר בעדכון הבא'),
            ),
          );
        }
      },
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