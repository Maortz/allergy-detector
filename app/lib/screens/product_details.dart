import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'feedback_screen.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/favorites_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_toast.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
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
              color: isFavorite ? appColors.avoid : null,
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
                      color: colorScheme.surfaceContainerLowest,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.share),
                        color: colorScheme.onSurfaceVariant,
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
                        color: colorScheme.onSurface,
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
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (product.brandTrustScore != null &&
                              product.brandTrustScore! >= 0.7) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified,
                                size: 16, color: colorScheme.primary),
                          ],
                        ],
                      ),
                    if (product.isKosher) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(Icons.check_circle,
                              color: appColors.safeText, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'כשר',
                            style: AppTypography.labelBold
                                .copyWith(color: appColors.safeText),
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

    final appColors = context.colors;
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
                    ? appColors.cautionText
                    : appColors.safeText,
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
    final appColors = context.colors;
    return Container(
      width: double.infinity,
      color: appColors.avoid,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.cancel, color: appColors.onAvoid, size: 20),
          Text(
            'הימנע – מכיל אלרגנים',
            style: AppTypography.labelBold.copyWith(color: appColors.onAvoid),
          ),
          Icon(Icons.chevron_left, color: appColors.onAvoid, size: 20),
        ],
      ),
    );
  }

  Widget _buildAllergensSection() {
    final colorScheme = Theme.of(context).colorScheme;
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
          style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
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
    final colorScheme = Theme.of(context).colorScheme;
    final status = _computeStatus(product, userProfile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.list_alt, size: 18, color: colorScheme.onSurface),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'רשימת רכיבים',
              style:
                  AppTypography.titleMd.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
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
                style: AppTypography.bodyMd.copyWith(color: colorScheme.primary),
              ),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      style: AppTypography.bodyXs
                          .copyWith(color: colorScheme.onSurfaceVariant),
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
  /// monitored allergen's Hebrew name. Avoid → `context.colors.avoid` bold for
  /// `contains ∩ user`; caution → `context.colors.cautionHighlight` bold for
  /// `mayContain ∩ user`; safe → no highlight. Case-insensitive verbatim
  /// substring match per product-details-safe §7.8.
  List<TextSpan> _highlightIngredients(String text, AllergenStatus status) {
    if (status == AllergenStatus.safe) {
      return [TextSpan(text: text)];
    }

    final appColors = context.colors;
    final userAllergenIds = userProfile.selectedAllergenIds;
    final (matched, highlightColor) = status == AllergenStatus.avoid
        ? (
            product.containsAllergens
                .where((a) => userAllergenIds.contains(a.allergenId)),
            appColors.avoid,
          )
        : (
            product.mayContainAllergens
                .where((a) => userAllergenIds.contains(a.allergenId)),
            appColors.cautionHighlight,
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
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'האם המידע היה מועיל?',
            style: AppTypography.bodySm
                .copyWith(color: colorScheme.onSurfaceVariant),
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
                      ? appColors.safeText
                      : colorScheme.onSurfaceVariant,
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
                      ? appColors.avoid
                      : colorScheme.onSurfaceVariant,
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
                productBarcode: product.barcode,
                productImageUrl: product.imageUrl,
                onSubmit: (type, message, image) async {},
              ),
            ),
          );
        },
        icon: const Icon(Icons.report_problem),
        label: const Text('דווח על טעות'),
        style: TextButton.styleFrom(foregroundColor: context.colors.avoid),
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

  /// Builds a friendly Hebrew share summary: product name, brand and barcode.
  String _buildShareText() {
    final buffer = StringBuffer('בדקתי את ${product.nameHe}');
    final brand = product.brandNameHe;
    if (brand != null && brand.isNotEmpty) {
      buffer.write(' מבית $brand');
    }
    buffer.write(' באפליקציית Allergy Detector');
    final barcode = product.barcode;
    if (barcode != null && barcode.isNotEmpty) {
      buffer.write('\nברקוד: $barcode');
    }
    return buffer.toString();
  }

  /// Opens the OS-native share sheet. Falls back to copying the summary to the
  /// clipboard when native sharing is unavailable (e.g. web without the Web
  /// Share API, or in the test environment where the platform channel is
  /// absent). Spec ref: product-details-safe.md §4.4 / D7.
  Future<void> _shareProduct(BuildContext context) async {
    final text = _buildShareText();
    try {
      final result = await SharePlus.instance.share(ShareParams(text: text));
      // `unavailable` is the platform's explicit signal that native sharing is
      // not supported in this environment (e.g. web without the Web Share API,
      // or the test harness). Only then do we silently fall back to clipboard.
      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        await _fallbackToClipboard(context, text);
      }
    } on PlatformException catch (e) {
      // A platform-channel failure (plugin missing on this platform) is also an
      // unavailability case — fall back rather than surface a raw error.
      if (kDebugMode) {
        debugPrint('Native share failed, falling back to clipboard: $e');
      }
      if (context.mounted) {
        await _fallbackToClipboard(context, text);
      }
    }
    // Any other exception (a genuine bug) is intentionally left to propagate so
    // it is not masked by a misleading "copied to clipboard" success toast.
  }

  /// Copies the share summary to the clipboard and notifies the user. Used as
  /// the fallback when the OS-native share sheet is unavailable.
  Future<void> _fallbackToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'אין תמונה זמינה',
            style: AppTypography.labelSm
                .copyWith(color: colorScheme.onSurfaceVariant),
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
    final appColors = context.colors;
    final (bg, fg, icon) = switch (status) {
      AllergenStatus.safe => (
          appColors.safeBackground,
          appColors.safeText,
          Icons.check_circle,
        ),
      AllergenStatus.caution => (
          appColors.cautionBackground,
          appColors.cautionText,
          Icons.info,
        ),
      // Avoid never reaches the pill — fall back to caution styling defensively.
      AllergenStatus.avoid => (
          appColors.cautionBackground,
          appColors.cautionText,
          Icons.info,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pillH,
        vertical: AppSpacing.unit,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: AppSpacing.unit),
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
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.colors;
    final (bg, border, fg) = switch (variant) {
      _AllergenChipVariant.display => (
          appColors.chipDisplayBg,
          appColors.chipDisplayBorder,
          colorScheme.primary,
        ),
      _AllergenChipVariant.detected => (
          appColors.chipDetectedBg,
          appColors.chipDetectedBorder,
          appColors.chipDetectedFg,
        ),
      _AllergenChipVariant.caution => (
          appColors.chipCautionBg,
          appColors.chipCautionBorder,
          appColors.chipCautionFg,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pillH,
        vertical: AppSpacing.chipV,
      ),
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
              ? colorScheme.primary
              : border),
          const SizedBox(width: AppSpacing.unit),
          Text(label, style: AppTypography.labelBold.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Helpfulness feedback selection for the product-detail feedback row (AV5).
enum _Feedback { none, helpful, notHelpful }
