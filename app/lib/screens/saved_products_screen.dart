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
import '../widgets/product_thumbnail.dart';
import 'product_details.dart';

/// Standalone, read-only view of the user's saved (favorited) products,
/// reachable from the navigation drawer (`nav-drawer-user.md §3`).
///
/// Distinct from the Favorites *tab* (`FavoritesScreen`, tab 3) which supports
/// removal and lives in the `IndexedStack`; this is a pushed route. Both share
/// the same source of truth — [FavoritesService] (SharedPreferences-backed) —
/// so no favorites business logic is duplicated here. Mutations belong to the
/// favorites flow, so this screen never adds or removes.
class SavedProductsScreen extends StatefulWidget {
  /// Profile passed through to [ProductDetailsScreen] for allergen status.
  final UserProfile userProfile;

  /// Resolves a tapped saved product to a full [Product] for the details
  /// screen. Injectable so widget tests can avoid hitting Supabase; defaults to
  /// `ProductService.getById` in [_resolveProduct].
  final Future<Product?> Function(String productId)? productResolver;

  const SavedProductsScreen({
    super.key,
    this.userProfile = const UserProfile(),
    this.productResolver,
  });

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  List<FavoriteProduct>? _saved;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await FavoritesService.favorites();
    if (!mounted) return;
    setState(() => _saved = saved);
  }

  Future<Product?> _resolveProduct(String productId) {
    final resolver = widget.productResolver;
    if (resolver != null) return resolver(productId);
    return ProductService(Supabase.instance.client).getById(productId);
  }

  Future<void> _openProduct(FavoriteProduct favorite) async {
    final product = await _resolveProduct(favorite.productId);
    if (!mounted || product == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          userProfile: widget.userProfile,
        ),
      ),
    );
    // Reloads after returning: the details screen can unfavorite the product,
    // which must drop it from this read-only list.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('מוצרים שמורים'),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: saved == null
            ? const Center(child: CircularProgressIndicator())
            : saved.isEmpty
                ? const _EmptySaved()
                : _SavedList(saved: saved, onTap: _openProduct),
      ),
    );
  }
}

class _SavedList extends StatelessWidget {
  final List<FavoriteProduct> saved;
  final ValueChanged<FavoriteProduct> onTap;

  const _SavedList({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: saved.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final favorite = saved[index];
        return _SavedTile(
          favorite: favorite,
          onTap: () => onTap(favorite),
        );
      },
    );
  }
}

class _SavedTile extends StatelessWidget {
  final FavoriteProduct favorite;
  final VoidCallback onTap;

  const _SavedTile({required this.favorite, required this.onTap});

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
              ProductThumbnail(imageUrl: favorite.imageUrl),
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
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 72,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'אין מוצרים שמורים',
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'שמור מוצרים מועדפים כדי לגשת אליהם במהירות',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
