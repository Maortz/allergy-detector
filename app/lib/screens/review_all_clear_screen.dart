import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bento_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'main_container.dart';

/// Terminal celebration screen shown when the community review queue is
/// exhausted. Stats are passed in from the completing review action.
class ReviewAllClearScreen extends StatelessWidget {
  final int totalPointsEarned;
  final int productsScanned;
  final VoidCallback? onReturnHome;

  /// Optional per-tab routing for the bottom nav. Receives the tapped index.
  /// If null, taps pop back to [MainContainer] and select the tapped tab via
  /// [MainContainer.switchToTab].
  final ValueChanged<int>? onNavTap;

  const ReviewAllClearScreen({
    super.key,
    this.totalPointsEarned = 0,
    this.productsScanned = 0,
    this.onReturnHome,
    this.onNavTap,
  });

  void _goHome() => onReturnHome?.call();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Spec §4.1: brand-bar variant — both page surface and bar are
        // the lowest container surface, not the page-grey background token.
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.surfaceContainerLowest,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'בטוח לאכול',
            // Brand-bar variant per spec §4.1 + _components-glossary #app-bar:
            // Inter Medium 16pt in the primary colour, not Public Sans h3 black.
            style: AppTypography.labelBold.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.margin,
              vertical: AppSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Column(
                  children: [
                    _buildHero(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildStats(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildHomeButton(context),
                    const SizedBox(height: AppSpacing.md),
                    _buildSecondaryLine(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildIllustration(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2,
          onTap: onNavTap ?? (i) => MainContainer.switchToTab(context, i),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildHeroBadge(context),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'כל הכבוד!',
          style: AppTypography.h1.copyWith(color: colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'אין מוצרים נוספים להיום. עזרת לקהילה לדעת במה לסמוך בבחירות המזון שלה.',
          style:
              AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Spec §4.2: the 96 pt primary hero circle plus decorative sparkle glints.
  /// The glints are pure-Flutter [Icon]s positioned at the four diagonal
  /// corners (~45°/135°/225°/315°) around the circle, so no asset dependency.
  Widget _buildHeroBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const double circle = 96;
    const double glint = 14;
    // Padding gives the corner glints room to sit outside the circle without
    // being clipped by the Stack bounds.
    const double pad = 12;
    return SizedBox(
      width: circle + pad * 2,
      height: circle + pad * 2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              // Spec §4.2: primary-tinted shadow lifts the medal off the page.
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium,
              color: colorScheme.onPrimary,
              size: 48,
            ),
          ),
          // Four sparkle glints at the diagonal corners.
          const Positioned(top: 0, right: 0, child: _Glint(size: glint)),
          const Positioned(top: 0, left: 0, child: _Glint(size: glint - 4)),
          const Positioned(bottom: 0, right: 0, child: _Glint(size: glint - 4)),
          const Positioned(bottom: 0, left: 0, child: _Glint(size: glint)),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: BentoCard(
            label: 'נקודות קהילה',
            value: '$totalPointsEarned+',
            valueColor: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: BentoCard(
            label: 'מוצרים שנסרקו',
            value: '$productsScanned',
            valueColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _goHome,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'חזרה לבית',
              style:
                  AppTypography.labelBold.copyWith(color: colorScheme.onPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_left, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryLine(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Spec §4.5 + §7.5 (resolved): informational, non-navigating line. Rendered
    // as a disabled [TextButton] (no tap handler) rather than a bare [Text] so
    // it carries the ghost-link affordance the design calls for while remaining
    // inert. Inter Regular 13 pt, AppColors.outline.
    return TextButton(
      onPressed: null,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.outline,
        textStyle: AppTypography.labelSm,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'תוצאות הסקירה נשמרו בפרופיל שלך',
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Spec §4.6 + §7.6: decorative "Safe Food Lab" illustration, ~180 pt tall,
  /// 12 pt rounded corners. Rendered as a hand-built Flutter vector scene
  /// (a lab flask topped with a safety check, framed by sparkle glints) rather
  /// than a raster asset — matching the screen's existing pure-Flutter
  /// decorative idiom (the hero badge + glints carry no asset dependency) and
  /// sidestepping the full-bleed stretched-placeholder bug (#327). Decorative
  /// only — excluded from semantics.
  Widget _buildIllustration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        key: const Key('all_clear_illustration'),
        height: 180,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          key: const Key('safe_food_lab_illustration'),
          painter: _SafeFoodLabPainter(
            outline: colorScheme.onPrimaryContainer,
            liquid: colorScheme.onPrimaryContainer.withValues(alpha: 0.35),
            glint: context.colors.primaryTintBorder,
            badge: context.colors.success,
            onBadge: context.colors.onSuccess,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Pure-Flutter "Safe Food Lab" illustration (spec §4.6): a conical lab flask
/// with liquid and rising bubbles, capped by a success check badge and framed
/// by sparkle glints. Drawn in a fixed 220×140 design box and uniformly scaled
/// to fit, so it stays crisp at any panel width. Decorative only.
class _SafeFoodLabPainter extends CustomPainter {
  _SafeFoodLabPainter({
    required this.outline,
    required this.liquid,
    required this.glint,
    required this.badge,
    required this.onBadge,
  });

  /// Flask outline / linework colour.
  final Color outline;

  /// Flask liquid fill colour (already alpha-blended).
  final Color liquid;

  /// Sparkle-glint colour.
  final Color glint;

  /// Safety check-badge fill colour.
  final Color badge;

  /// Check-mark colour drawn on the badge.
  final Color onBadge;

  // Reference design box. All geometry below is expressed in these units and
  // scaled uniformly in [paint].
  static const double _boxW = 220;
  static const double _boxH = 140;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _boxW, size.height / _boxH);
    canvas.save();
    canvas.translate(
      (size.width - _boxW * scale) / 2,
      (size.height - _boxH * scale) / 2,
    );
    canvas.scale(scale);

    _paintGlints(canvas);
    _paintFlask(canvas);
    _paintBadge(canvas);

    canvas.restore();
  }

  void _paintFlask(Canvas canvas) {
    // Conical flask body: neck (97–123) down to a flared, round-cornered base.
    final body = Path()
      ..moveTo(97, 22)
      ..lineTo(97, 50)
      ..lineTo(60, 114)
      ..quadraticBezierTo(58, 120, 64, 120)
      ..lineTo(156, 120)
      ..quadraticBezierTo(162, 120, 160, 114)
      ..lineTo(123, 50)
      ..lineTo(123, 22)
      ..close();

    // Liquid pooled in the lower body, clipped to the flask interior. The body
    // sides hit x≈76.2 / x≈143.8 at the surface line (y=86).
    final liquidPath = Path()
      ..moveTo(76.2, 86)
      ..lineTo(60, 114)
      ..quadraticBezierTo(58, 120, 64, 120)
      ..lineTo(156, 120)
      ..quadraticBezierTo(162, 120, 160, 114)
      ..lineTo(143.8, 86)
      ..close();
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(liquidPath, Paint()..color = liquid);
    canvas.restore();

    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(body, stroke);

    // Flask rim cap.
    canvas.drawLine(
      const Offset(90, 22),
      const Offset(130, 22),
      Paint()
        ..color = outline
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Rising bubbles.
    final bubble = Paint()..color = outline;
    canvas.drawCircle(const Offset(101, 100), 3, bubble);
    canvas.drawCircle(const Offset(118, 92), 2.5, bubble);
    canvas.drawCircle(const Offset(108, 80), 2, bubble);
  }

  void _paintBadge(Canvas canvas) {
    const center = Offset(150, 104);
    canvas.drawCircle(center, 18, Paint()..color = badge);
    final check = Path()
      ..moveTo(142, 104)
      ..lineTo(148, 111)
      ..lineTo(159, 97);
    canvas.drawPath(
      check,
      Paint()
        ..color = onBadge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintGlints(Canvas canvas) {
    final paint = Paint()..color = glint;
    _drawSparkle(canvas, const Offset(58, 40), 11, paint);
    _drawSparkle(canvas, const Offset(172, 48), 8, paint);
    _drawSparkle(canvas, const Offset(46, 100), 6, paint);
  }

  /// A four-point sparkle centred at [c] reaching [r] in each cardinal
  /// direction; the diagonals are pinched toward the centre (control points
  /// collapse to [c]) for the classic concave glint silhouette.
  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SafeFoodLabPainter oldDelegate) =>
      outline != oldDelegate.outline ||
      liquid != oldDelegate.liquid ||
      glint != oldDelegate.glint ||
      badge != oldDelegate.badge ||
      onBadge != oldDelegate.onBadge;
}

/// A single decorative sparkle glint (spec §4.2). Pure Flutter — no asset.
class _Glint extends StatelessWidget {
  final double size;

  const _Glint({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star,
      size: size,
      color: context.colors.primaryTintBorder,
    );
  }
}
