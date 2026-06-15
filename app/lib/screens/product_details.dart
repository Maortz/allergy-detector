import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'feedback_screen.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/favorites_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';
import '../widgets/bottom_nav_bar.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final UserProfile userProfile;
  final VoidCallback? onReport;
  final VoidCallback? onDeleted;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.userProfile,
    this.onReport,
    this.onDeleted,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product get product => widget.product;
  UserProfile get userProfile => widget.userProfile;

  /// Whether this product is currently favorited. `null` until the initial
  /// async read from [FavoritesService] resolves — while null the toggle shows
  /// the inactive (outline) affordance and is disabled, so we never flash a
  /// wrong state or let a tap race the load.
  bool? _isFavorite;

  /// Helpfulness feedback selection (AV5). MVP-local — no backend persistence
  /// exists yet (product-details-avoid §6 "future").
  _Feedback _feedback = _Feedback.none;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final fav = await FavoritesService.isFavorite(product.id);
    if (!mounted) return;
    setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    final current = _isFavorite;
    if (current == null) return; // still loading — ignore the tap
    final next = !current;
    // Optimistic UI: flip immediately so the tap feels instant, then persist.
    setState(() => _isFavorite = next);

    if (next) {
      await FavoritesService.add(product);
    } else {
      await FavoritesService.remove(product.id);
    }

    if (!mounted) return;
    AppToast.success(
      context,
      next ? 'נוסף למועדפים' : 'הוסר מהמועדפים',
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _computeStatus(product, userProfile);
    final isFavorite = _isFavorite ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פרטי מוצר'),
          actions: [
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              color: isFavorite ? AppColors.avoid : null,
              tooltip: isFavorite ? 'הסר ממועדפים' : 'הוסף למועדפים',
              onPressed: _isFavorite == null ? null : _toggleFavorite,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusIndicator(status),
              // No-image fallback: when `imageUrl` is null or fails to load,
              // render the same neutral placeholder so the layout stays
              // stable. Spec ref: `product-details-safe.md §7` (image load
              // fallback Tier 2 variant).
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrl == null
                        ? const _ProductImagePlaceholder()
                        : Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) =>
                                const _ProductImagePlaceholder(),
                          ),
                  ),
                  PositionedDirectional(
                    bottom: AppSpacing.sm,
                    start: AppSpacing.sm,
                    child: Material(
                      color: AppColors.surfaceContainerLowest,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.share),
                        color: AppColors.onSurfaceVariant,
                        tooltip: 'שתף',
                        onPressed: () => _shareProduct(context),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.nameHe,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (product.brandNameHe != null)
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            product.brandNameHe!,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (product.brandTrustScore != null &&
                              product.brandTrustScore! >= 0.7) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, size: 16, color: AppColors.primary),
                          ],
                        ],
                      ),
                    if (product.isKosher) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.safeText, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'כשר',
                            style: AppTypography.labelBold.copyWith(color: AppColors.safeText),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildAllergensSection(),
                    if (product.ingredients != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildIngredientsSection(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildFeedbackRow(),
                    const SizedBox(height: AppSpacing.sm),
                    _buildReportRow(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {},
        ),
      ),
    );
  }

  /// Status indicator below the app bar.
  ///
  /// Per glossary `#status-pill` + DD-1: only the **avoid** state uses a
  /// full-width solid-red banner; safe and caution use a compact inline pill
  /// (the fixed verdict label, DD-3) followed by separate adjacent text.
  Widget _buildStatusIndicator(AllergenStatus status) {
    if (status == AllergenStatus.avoid) return _buildAvoidBanner();

    final (label, adjacent) = switch (status) {
      AllergenStatus.caution => ('זהירות', 'עלול להכיל אלרגנים'),
      AllergenStatus.safe => ('בטוח', 'ללא אלרגנים עבורך'),
      AllergenStatus.avoid => ('', ''), // unreachable — handled above
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _StatusPill(status: status, label: label),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              adjacent,
              style: AppTypography.bodyXs.copyWith(
                color: status == AllergenStatus.caution
                    ? AppColors.cautionText
                    : AppColors.safeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width solid-red avoid banner (screen-specific, not a glossary pill).
  /// AV1: solid `#DC2626` background + white text + `cancel` icon (RTL leading)
  /// + decorative `chevron_left` (RTL trailing). Per product-details-avoid §4.
  Widget _buildAvoidBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.avoid,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.cancel, color: AppColors.onAvoid, size: 20),
          Text(
            'הימנע – מכיל אלרגנים',
            style: AppTypography.labelBold.copyWith(color: AppColors.onAvoid),
          ),
          Icon(Icons.chevron_left, color: AppColors.onAvoid, size: 20),
        ],
      ),
    );
  }

  Widget _buildAllergensSection() {
    final userAllergenIds = userProfile.selectedAllergenIds;
    final productAllergens = [
      ...product.containsAllergens,
      ...product.mayContainAllergens,
    ];

    if (productAllergens.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'אלרגנים שזוהו',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          textDirection: TextDirection.rtl,
          children: productAllergens.map((pa) {
            final matchesUser = userAllergenIds.contains(pa.allergenId);
            final variant = !matchesUser
                ? _AllergenChipVariant.display
                : pa.severityLevel == AllergenSeverity.contains
                    ? _AllergenChipVariant.detected
                    : _AllergenChipVariant.caution;
            return _AllergenChip(
              label: pa.allergenNameHe,
              icon: _getAllergenIcon(pa.allergenId),
              variant: variant,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    final status = _computeStatus(product, userProfile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.list_alt, size: 18, color: AppColors.onSurface),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'רשימת רכיבים',
              style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              childrenPadding: const EdgeInsets.all(AppSpacing.md),
              title: Text(
                'רשימת רכיבים',
                style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
              ),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      style: AppTypography.bodyXs
                          .copyWith(color: AppColors.onSurfaceVariant),
                      children: _highlightIngredients(
                        product.ingredients!,
                        status,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Splits [text] into [TextSpan]s, colouring any substring that matches a
  /// monitored allergen's Hebrew name. Avoid → `#DC2626` bold for
  /// `contains ∩ user`; caution → `#CA8A04` bold for `mayContain ∩ user`; safe
  /// → no highlight. Case-insensitive verbatim substring match per
  /// product-details-safe §7.8.
  List<TextSpan> _highlightIngredients(String text, AllergenStatus status) {
    if (status == AllergenStatus.safe) {
      return [TextSpan(text: text)];
    }

    final userAllergenIds = userProfile.selectedAllergenIds;
    final (matched, highlightColor) = status == AllergenStatus.avoid
        ? (
            product.containsAllergens
                .where((a) => userAllergenIds.contains(a.allergenId)),
            const Color(0xFFDC2626),
          )
        : (
            product.mayContainAllergens
                .where((a) => userAllergenIds.contains(a.allergenId)),
            const Color(0xFFCA8A04),
          );

    final keywords = matched
        .map((a) => a.allergenNameHe)
        .where((k) => k.isNotEmpty)
        .toSet();
    if (keywords.isEmpty) return [TextSpan(text: text)];

    // Build a single alternation regex over the keywords, escaping each.
    final pattern = keywords.map(RegExp.escape).join('|');
    final regex = RegExp(pattern, caseSensitive: false);

    final spans = <TextSpan>[];
    var index = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: AppTypography.labelBold.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w700,
        ),
      ));
      index = match.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    return spans;
  }

  Widget _buildFeedbackRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'האם המידע היה מועיל?',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'מועיל',
                icon: Icon(
                  _feedback == _Feedback.helpful
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  color: _feedback == _Feedback.helpful
                      ? AppColors.safeText
                      : AppColors.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _feedback = _Feedback.helpful),
              ),
              IconButton(
                tooltip: 'לא מועיל',
                icon: Icon(
                  _feedback == _Feedback.notHelpful
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  color: _feedback == _Feedback.notHelpful
                      ? AppColors.avoid
                      : AppColors.onSurfaceVariant,
                ),
                onPressed: () =>
                    setState(() => _feedback = _Feedback.notHelpful),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                productId: product.id,
                productName: product.nameHe,
                onSubmit: (type, message) async {},
              ),
            ),
          );
        },
        icon: const Icon(Icons.report_problem),
        label: const Text('דווח על טעות'),
        style: TextButton.styleFrom(foregroundColor: AppColors.avoid),
      ),
    );
  }

  /// Maps an allergen id substring to a Material icon, aligned with
  /// `_components-glossary.md#allergen-chip` "Allergen icon mapping". Where the
  /// glossary names an icon Material does not ship (`nutrition`), the nearest
  /// valid icon is used and noted here. Keyed on the allergen **id** (the data
  /// the screen has) rather than the Hebrew name.
  IconData _getAllergenIcon(String allergenId) {
    final id = allergenId.toLowerCase();
    if (id.contains('milk') || id.contains('dairy')) {
      return Icons.water_drop; // חלב
    } else if (id.contains('egg')) {
      return Icons.egg; // ביצים
    } else if (id.contains('wheat') || id.contains('gluten')) {
      return Icons.grass; // גלוטן
    } else if (id.contains('soy')) {
      return Icons.local_dining; // סויה — glossary "nutrition" (no such icon)
    } else if (id.contains('peanut')) {
      return Icons.park; // בוטנים
    } else if (id.contains('walnut')) {
      return Icons.energy_savings_leaf; // אגוז מלך
    } else if (id.contains('almond')) {
      return Icons.nature; // שקד
    } else if (id.contains('cashew')) {
      return Icons.emoji_nature; // קשיו
    } else if (id.contains('pistachio')) {
      return Icons.grain; // פיסטוק
    } else if (id.contains('pecan')) {
      return Icons.local_florist; // פקאן
    } else if (id.contains('hazelnut')) {
      return Icons.spa; // אגוז לוז
    } else if (id.contains('pine')) {
      return Icons.eco; // צנובר
    } else if (id.contains('nut')) {
      return Icons.spa; // generic nuts fallback
    } else if (id.contains('fish')) {
      return Icons.set_meal;
    } else if (id.contains('shellfish') || id.contains('crustacean')) {
      return Icons.pool;
    } else if (id.contains('sesame')) {
      return Icons.grain; // שומשום (glossary TBD)
    }
    return Icons.warning_amber;
  }

  void _shareProduct(BuildContext context) {
    final text = 'בדוק את המוצר ${product.nameHe} באפליקציית Allergy Detector';
    Clipboard.setData(ClipboardData(text: text));
    AppToast.success(context, 'הקישור הועתק ללוח');
  }

  AllergenStatus _computeStatus(Product product, UserProfile profile) {
    final userAllergenIds = profile.selectedAllergenIds;
    for (final a in product.containsAllergens) {
      if (userAllergenIds.contains(a.allergenId)) {
        return AllergenStatus.avoid;
      }
    }
    for (final a in product.mayContainAllergens) {
      if (userAllergenIds.contains(a.allergenId)) {
        return AllergenStatus.caution;
      }
    }
    return AllergenStatus.safe;
  }
}

/// Neutral placeholder shown in the hero-image slot when the product has no
/// image URL or the network image fails to load. Spec ref:
/// `product-details-safe.md §7` (image load fallback).
class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: AppColors.outline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'אין תמונה זמינה',
            style:
                AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Compact inline status pill — glossary `#status-pill`.
/// Safe/caution variants only (avoid uses the full-width banner). Radius 20,
/// `EdgeInsets.symmetric(horizontal: 12, vertical: 4)` per DD-17, 16 pt icon,
/// 4 pt gap, fixed verdict label (DD-3).
class _StatusPill extends StatelessWidget {
  final AllergenStatus status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      AllergenStatus.safe => (
          AppColors.safeBackground,
          AppColors.safeText,
          Icons.check_circle,
        ),
      AllergenStatus.caution => (
          AppColors.cautionBackground,
          AppColors.cautionText,
          Icons.info,
        ),
      // Avoid never reaches the pill — fall back to caution styling defensively.
      AllergenStatus.avoid => (
          AppColors.cautionBackground,
          AppColors.cautionText,
          Icons.info,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Visual variant for a product-detail allergen chip — glossary
/// `#allergen-chip` Variants A (display), B (detected), D (caution).
enum _AllergenChipVariant { display, detected, caution }

/// Compact rounded-pill allergen chip (radius 20). Read-only.
class _AllergenChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final _AllergenChipVariant variant;

  const _AllergenChip({
    required this.label,
    required this.icon,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    // Glossary palettes (hardcoded hex — these are spec-fixed chip colours that
    // intentionally differ from the AppColors status-tint pair).
    final (bg, border, fg) = switch (variant) {
      _AllergenChipVariant.display => (
          const Color(0xFFEBF4FF),
          const Color(0xFFBFDBFE),
          AppColors.primary, // #00478D
        ),
      _AllergenChipVariant.detected => (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          const Color(0xFF991B1B),
        ),
      _AllergenChipVariant.caution => (
          const Color(0xFFFEF9C3),
          const Color(0xFFCA8A04),
          const Color(0xFFA16207),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 16, color: variant == _AllergenChipVariant.display
              ? AppColors.primary
              : border),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelBold.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Helpfulness feedback selection for the product-detail feedback row (AV5).
enum _Feedback { none, helpful, notHelpful }
