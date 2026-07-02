import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class BrandCard extends StatelessWidget {
  final String name;
  final double? trustScore;
  final int? productCount;
  final VoidCallback? onTap;

  const BrandCard({
    super.key,
    required this.name,
    this.trustScore,
    this.productCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: AppTypography.h3.copyWith(
                      color: colorScheme.onPrimaryFixed,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.labelBold.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (productCount != null) ...[
                          Text(
                            '$productCount מוצרים',
                            style: AppTypography.labelSm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (trustScore != null) ...[
                            const Text(' • '),
                          ],
                        ],
                        if (trustScore != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: trustScore! >= 0.7
                                    ? context.colors.safeText
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(trustScore! * 100).toInt()}%',
                                style: AppTypography.labelSm.copyWith(
                                  color: trustScore! >= 0.7
                                      ? context.colors.safeText
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}