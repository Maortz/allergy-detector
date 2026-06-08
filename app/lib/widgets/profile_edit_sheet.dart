import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/photo_source_picker.dart';
import '../utils/validators.dart';

Future<UserProfile?> showProfileEditSheet(
    BuildContext context, UserProfile current) async {
  return showModalBottomSheet<UserProfile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _ProfileEditSheetContent(current: current),
  );
}

class _ProfileEditSheetContent extends StatefulWidget {
  final UserProfile current;
  const _ProfileEditSheetContent({required this.current});

  @override
  State<_ProfileEditSheetContent> createState() =>
      _ProfileEditSheetContentState();
}

class _ProfileEditSheetContentState extends State<_ProfileEditSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _avatarData; // base64 JPEG

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.current.displayName ?? '');
    _emailController =
        TextEditingController(text: widget.current.email ?? '');
    _avatarData = widget.current.avatarData;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _pickAvatar() async {
    final source = await showPhotoSourcePicker(context);
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 256,
      maxHeight: 256,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _avatarData = base64Encode(bytes));
  }

  void _save() {
    // Email is optional; an empty field passes. A non-empty, malformed
    // address fails validation and surfaces the field error instead of saving.
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final updated = widget.current.copyWith(
      displayName: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      avatarData: _avatarData,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Grabber
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // 2. Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ערוך פרופיל',
                      style: AppTypography.h3
                          .copyWith(color: AppColors.onSurface),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                // 3. Avatar block
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryFixed,
                            border: Border.all(
                                color: AppColors.primaryFixedDim, width: 2),
                          ),
                          child: _avatarData != null
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(_avatarData!),
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _nameController.text.trim().isNotEmpty
                                        ? _nameController.text
                                            .trim()[0]
                                            .toUpperCase()
                                        : '?',
                                    style: AppTypography.h2.copyWith(
                                        color: AppColors.primary),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _pickAvatar,
                        child: Text(
                          'החלף תמונה',
                          style: AppTypography.labelBold
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                // 4. Name field
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'שם מלא',
                    style: AppTypography.labelBold
                        .copyWith(color: AppColors.onSurface),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'הקלד שם מלא',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                  ),
                ),
                // 5. Email field
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'דוא״ל',
                    style: AppTypography.labelBold
                        .copyWith(color: AppColors.onSurface),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    // Email is optional — empty is allowed (saved as null).
                    if (value == null || value.trim().isEmpty) return null;
                    if (!Validators.isValidEmail(value)) {
                      return 'נא להזין כתובת דוא״ל תקינה';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                  ),
                ),
                // 6. Save button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isValid ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      disabledForegroundColor: AppColors.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('שמור', style: AppTypography.labelBold),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
