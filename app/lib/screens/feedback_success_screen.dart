import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bento_card.dart';

class FeedbackSuccessScreen extends StatelessWidget {
  final VoidCallback? onCheckNext;
  final VoidCallback? onHome;

  const FeedbackSuccessScreen({
    super.key,
    this.onCheckNext,
    this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              _buildSuccessIcon(),
              const SizedBox(height: AppSpacing.lg),
              _buildTitle(),
              const SizedBox(height: AppSpacing.xl),
              _buildStats(),
              const SizedBox(height: AppSpacing.xl),
              _buildNextProductCard(),
              const Spacer(),
              _buildHomeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[50],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green[200]!, width: 3),
      ),
      child: Icon(
        Icons.check_circle,
        color: Colors.green[600],
        size: 48,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'תודה על תרומתך!',
      style: AppTypography.h1.copyWith(color: AppColors.onSurface),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: BentoCard(
            label: 'נקודות קהילה',
            value: '+15',
            icon: Icons.star,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: BentoCard(
            label: 'דירוג שבועי',
            value: '#42',
            icon: Icons.leaderboard,
          ),
        ),
      ],
    );
  }

  Widget _buildNextProductCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_basket, color: Colors.grey[400]),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'בדיקה הבאה מחכה לך!',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'חטיף שוקולד חלבי',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onCheckNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: const Text('בדוק עכשיו'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    return OutlinedButton.icon(
      onPressed: onHome,
      icon: const Icon(Icons.home),
      label: const Text('חזרה לדף הבית'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}