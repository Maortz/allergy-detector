import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
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

/// Direct-contact values shown in the contact-methods section (contact-us.md §4.2).
const String kContactEmail = 'support@allergycare.co.il';
const String kContactPhoneDisplay = '03-1234567';
const String kContactPhoneDial = '031234567';
const String kContactHours = "א'-ה' | 09:00-17:00";

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          'צור קשר',
          style: AppTypography.h3.copyWith(color: cs.onSurface),
        ),
        backgroundColor: cs.surfaceContainer,
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
                    _buildHeroCard(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildContactMethods(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildNameField(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildEmailField(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildSubjectField(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildMessageField(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSubmitButton(context),
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

  Widget _buildNameField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'שם מלא',
          style: AppTypography.labelBold.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _nameController,
          style: AppTypography.bodyMd.copyWith(color: cs.onSurface),
          textAlign: TextAlign.right,
          decoration: _buildInputDecoration(
            context,
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

  Widget _buildEmailField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'דוא"ל',
          style: AppTypography.labelBold.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _emailController,
          style: AppTypography.bodyMd.copyWith(color: cs.onSurface),
          textAlign: TextAlign.right,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(
            context,
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

  Widget _buildSubjectField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'נושא',
          style: AppTypography.labelBold.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedSubject,
          isExpanded: true,
          style: AppTypography.bodyMd.copyWith(color: cs.onSurface),
          icon: Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
          decoration: _buildInputDecoration(
            context,
            prefixIcon: Icons.topic_outlined,
          ),
          hint: Text(
            'בחר נושא',
            style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant),
          ),
          items: [
            for (final subject in kContactSubjects)
              DropdownMenuItem<String>(
                value: subject,
                child: Text(
                  subject,
                  textAlign: TextAlign.start,
                  style: AppTypography.bodyMd.copyWith(color: cs.onSurface),
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

  Widget _buildMessageField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הודעה',
          style: AppTypography.labelBold.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _messageController,
          style: AppTypography.bodyMd.copyWith(color: cs.onSurface),
          textAlign: TextAlign.right,
          maxLines: 5,
          decoration: _buildInputDecoration(
            context,
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

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    String? hint,
    required IconData prefixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant),
      filled: true,
      fillColor: cs.surfaceContainer,
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
        child: Icon(prefixIcon, color: cs.onSurfaceVariant, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
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
    // No backend yet — show the in-place success state per `contact-us.md §5.5`
    // (supersedes the prior info toast). When a real submit lands this will sit
    // behind a try/finally around `ContactService.submit(...)`.
    setState(() => _submitted = true);
  }

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildHeroCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primaryTintBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: 32, color: cs.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'אנחנו כאן כדי לעזור לכם לשמור על ביטחון תזונתי. '
            'צרו איתנו קשר בכל שאלה או משוב.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethods(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section heading above the three contact rows (contact-us.md §2.2/§4.2).
        Text(
          'פרטי יצירת קשר',
          style: AppTypography.labelBold
              .copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildContactRow(
          context,
          icon: Icons.email_outlined,
          label: 'דואר אלקטרוני',
          value: kContactEmail,
          onTap: () => _launchUri(Uri(scheme: 'mailto', path: kContactEmail)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildContactRow(
          context,
          icon: Icons.phone_outlined,
          label: 'מוקד טלפוני',
          value: kContactPhoneDisplay,
          onTap: () => _launchUri(Uri(scheme: 'tel', path: kContactPhoneDial)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildContactRow(
          context,
          icon: Icons.schedule_outlined,
          label: 'שעות פעילות',
          value: kContactHours,
        ),
      ],
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: cs.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelBold
                  .copyWith(color: cs.onSurface),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMd
                .copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );

    // Outer DecoratedBox: white card (#FFFFFF) with border and the subtle
    // spec §2.2 shadow (rgba(0,0,0,0.08), blur 3, offset 0,1).
    // Inner Material+InkWell owns the antialiased corner clip so the ink
    // ripple never overflows the rounded corners on older renderers.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // rgba(0,0,0,0.08)
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: _onSubmit,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'שלח הודעה',
        style: AppTypography.labelBold.copyWith(
          color: cs.onPrimary,
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: context.colors.safeText,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ההודעה נשלחה בהצלחה!',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'נחזור אליכם בהקדם האפשרי.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd
                .copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onReturnHome,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'חזרה לדף הבית',
                style: AppTypography.labelBold.copyWith(
                  color: cs.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
