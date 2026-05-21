import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class FavoritesScreen extends StatelessWidget {
  final UserProfile userProfile;
  final ValueChanged<int> onNavIndexChanged;

  const FavoritesScreen({
    super.key,
    required this.userProfile,
    required this.onNavIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border, size: 72, color: AppColors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'לא שמרת מוצרים עדיין',
                style: AppTypography.h3.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'סרוק מוצר כדי להוסיף למועדפים',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => onNavIndexChanged(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('סרוק מוצר'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
