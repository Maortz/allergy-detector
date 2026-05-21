import 'package:flutter/material.dart';

const _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);
const _titlePadding = EdgeInsets.fromLTRB(24, 24, 24, 8);
const _contentPadding = EdgeInsets.fromLTRB(24, 0, 24, 16);
const _actionsPadding = EdgeInsets.fromLTRB(8, 0, 8, 8);

Future<bool> showWizardExitDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: _shape,
        backgroundColor: Colors.white,
        titlePadding: _titlePadding,
        contentPadding: _contentPadding,
        actionsPadding: _actionsPadding,
        title: const Text('לצאת מהוספת מוצר?'),
        content: const Text('הנתונים שהזנת לא יישמרו.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('המשך עריכה'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('צא'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

Future<void> showLogoutDialog(
  BuildContext context, {
  required VoidCallback onConfirmed,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: _shape,
        backgroundColor: Colors.white,
        titlePadding: _titlePadding,
        contentPadding: _contentPadding,
        actionsPadding: _actionsPadding,
        title: const Text('התנתק מהחשבון?'),
        content: const Text(
          'כל הגדרות הפרופיל ישמרו במכשיר. תוכל להתחבר שוב בכל עת.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmed();
            },
            child: const Text('התנתק'),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showBrandDeleteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: _shape,
        backgroundColor: Colors.white,
        titlePadding: _titlePadding,
        contentPadding: _contentPadding,
        actionsPadding: _actionsPadding,
        title: const Text('האם למחוק את המותג?'),
        content: const Text(
          'פעולה זו אינה ניתנת לביטול. מוצרים המקושרים למותג יישארו במאגר אך יסומנו ללא מותג.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF374151)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('מחק'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
