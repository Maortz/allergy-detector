import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_product.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/favorites_service.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'product_details.dart';

/// Index of the Favorites tab in the bottom navigation bar. Used to reload the
/// persisted list whenever the user switches back to this tab (the screen lives
/// inside an `IndexedStack`, so it is kept alive and would otherwise show a
/// stale snapshot from when it was first built).
const int _favoritesTabIndex = 3;

class FavoritesScreen extends StatefulWidget {
  final UserProfile userProfile;
  final int currentNavIndex;
  final ValueChanged<int> onNavIndexChanged;

  /// Resolves a tapped favorite to a full [Product] for the details screen.
  /// Injectable so widget tests can avoid hitting Supabase; defaults to
  /// `ProductService.getById` in [_resolveProduct].
  final Future<Product?> Function(String productId)? productResolver;

  const FavoritesScreen({
    super.key,
    required this.userProfile,
    required this.currentNavIndex,
    required this.onNavIndexChanged,
    this.productResolver,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteProduct>? _favorites;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when this tab (re)gains focus so toggles made on the product
    // details screen are reflected immediately on return.
    final becameActive = oldWidget.currentNavIndex != _favoritesTabIndex &&
        widget.currentNavIndex == _favoritesTabIndex;
    if (becameActive) _load();
  }

  Future<void> _load() async {
    final favorites = await FavoritesService.favorites();
    if (!mounted) return;
    setState(() => _favorites = favorites);
  }

  Future<void> _openProduct(FavoriteProduct favorite) async {
    final product = await _resolveProduct(favorite.productId);
    if (!mounted) return;
    if (product == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          userProfile: widget.userProfile,
        ),
      ),
    );
    // The product details screen may have un-favorited this product; refresh.
    await _load();
  }

  Future<Product?> _resolveProduct(String productId) {
    final resolver = widget.productResolver;
    if (resolver != null) return resolver(productId);
    return ProductService(Supabase.instance.client).getById(productId);
  }

  Future<void> _removeFavorite(FavoriteProduct favorite) async {
    await FavoritesService.remove(favorite.productId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favorites;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: favorites == null
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? _EmptyFavorites(onScanTap: () => widget.onNavIndexChanged(1))
              : _FavoritesList(
                  favorites: favorites,
                  onTap: _openProduct,
                  onRemove: _removeFavorite,
                ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final List<FavoriteProduct> favorites;
  final ValueChanged<FavoriteProduct> onTap;
  final ValueChanged<FavoriteProduct> onRemove;

  const _FavoritesList({
    required this.favorites,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _FavoriteTile(
          favorite: favorite,
          onTap: () => onTap(favorite),
          onRemove: () => onRemove(favorite),
        );
      },
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final FavoriteProduct favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteTile({
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _Thumbnail(imageUrl: favorite.imageUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.nameHe,
                      style: AppTypography.bodyLg
                          .copyWith(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (favorite.brandNameHe != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        favorite.brandNameHe!,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite),
                color: AppColors.avoid,
                tooltip: 'הסר ממועדפים',
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;

  const _Thumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl == null
            ? const _ThumbnailPlaceholder()
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ThumbnailPlaceholder(),
              ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: AppColors.outline,
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onScanTap;

  const _EmptyFavorites({required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                size: 72, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'לא שמרת מוצרים עדיין',
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'סרוק מוצר כדי להוסיף למועדפים',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onScanTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('סרוק מוצר'),
            ),
          ],
        ),
      ),
    );
  }
}
