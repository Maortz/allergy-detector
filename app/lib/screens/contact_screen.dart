import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';
import '../utils/validators.dart';
import '../widgets/bottom_nav_bar.dart';

/// Subject options for the contact form's subject picker (spec §6.2).
/// Top-level so it can be shared with tests and a future `ContactService`.
const List<String> kContactSubjects = [
  'תמיכה טכנית',
  'דיווח על טעות במוצר',
  'הצעת שיתוף פעולה',
  'אחר',
];

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
  String? _selectedSubject;

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
              _buildSubjectField(),
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
            if (!Validators.isValidEmail(value)) {
              return 'נא להזין כתובת דוא"ל תקינה';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubjectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'נושא',
          style: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedSubject,
          isExpanded: true,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.onSurfaceVariant),
          decoration: _buildInputDecoration(
            prefixIcon: Icons.topic_outlined,
          ),
          hint: Text(
            'בחר נושא',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          items: [
            for (final subject in kContactSubjects)
              DropdownMenuItem<String>(
                value: subject,
                child: Text(
                  subject,
                  textAlign: TextAlign.start,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selectedSubject = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'נא לבחור נושא';
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
    String? hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      filled: true,
      fillColor: AppColors.surfaceContainer,
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
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
    // Normalise the address before use: the validator trims internally, so
    // trim here too to keep the submitted value consistent with what was
    // validated (once backend wiring lands this is the value that gets sent).
    final email = _emailController.text.trim();
    if (email != _emailController.text) {
      _emailController.text = email;
    }
    // Payload carries the selected subject; backend routing is out of scope (#84).
    final payload = <String, String>{
      'name': _nameController.text.trim(),
      'email': email,
      'subject': _selectedSubject!,
      'message': _messageController.text.trim(),
    };
    debugPrint('Contact form submitted: $payload');
    AppToast.info(context, 'בקרוב — שליחת הודעות תתאפשר בעדכון הבא');
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