import 'package:flutter/material.dart';
import 'product_details.dart';
import 'feedback_screen.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../services/scan_history_service.dart';
import '../services/search_cache.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/state_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreenContent extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;

  /// Invoked by the overlay "+" FAB to start the add-product flow. Supplied by
  /// MainContainer (→ AddProductWizard). Optional so the screen degrades safely
  /// (FAB hidden) when no host wires it.
  final VoidCallback? onAddProductTap;

  const SearchScreenContent({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
    this.onAddProductTap,
  });

  /// Resolves the filter level the result list is shown at.
  ///
  /// The "show only safe" toggle is the strictest filter level: it hides both
  /// "avoid" and "caution" products. Folding it into the level keeps the toggle
  /// and the profile's configured level on identical `statusFor` severity
  /// semantics — a "may_contain" (caution) match is treated consistently rather
  /// than always hidden. Static + public so tests can exercise the real toggle→
  /// level mapping instead of re-implementing it.
  static ProductFilterLevel effectiveFilterLevel({
    required bool showOnlySafe,
    required ProductFilterLevel configuredLevel,
  }) {
    return showOnlySafe ? ProductFilterLevel.safeOnly : configuredLevel;
  }

  @override
  State<SearchScreenContent> createState() => _SearchScreenContentState();
}

class _SearchScreenContentState extends State<SearchScreenContent> {
  final _searchController = TextEditingController();
  final ProductService _productService =
      ProductService(Supabase.instance.client);
  final _scrollController = ScrollController();
  List<Product> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _filterByUserAllergens = false;
  String? _error;
  bool _isStaleData = false;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialProducts());
  }

  Future<void> _loadInitialProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _productService.searchProducts('');
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasMore = results.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _searchController.text.trim().isEmpty) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreResults = await _productService.searchProducts(
        _searchController.text.trim(),
        page: _currentPage + 1,
      );
      if (mounted) {
        setState(() {
          if (moreResults.isEmpty) {
            _hasMore = false;
          } else {
            _results.addAll(moreResults);
            _currentPage++;
          }
          _isLoadingMore = false;
        });
        await SearchCache.save(_searchController.text.trim(), _results);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _error = null;
        _isStaleData = false;
        _currentPage = 0;
        _hasMore = true;
      });
      _loadInitialProducts();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isStaleData = false;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final results = await _productService.searchProducts(query);
      await SearchCache.save(query, results);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasMore = results.length >= 20;
        });
      }
    } catch (e) {
      final cached = await SearchCache.load(query);
      if (mounted) {
        setState(() {
          if (cached != null && cached.isNotEmpty) {
            _results = cached;
            _isStaleData = true;
            _error = null;
          } else {
            _results = [];
            _error = _friendlyErrorMessage(e);
          }
          _isLoading = false;
        });
      }
    }
  }

  /// Explicit retry entry point for the error/stale StateViews. Delegates to
  /// [_onSearchChanged] for now, but gives the retry path its own name so it can
  /// diverge from the keyboard listener (e.g. debounce) without breaking retry.
  void _retrySearch() => _onSearchChanged();

  String _friendlyErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('network')) {
      return 'אין חיבור לאינטרנט. בדוק את החיבור ונסה שוב.';
    }
    if (msg.contains('timeout')) {
      return 'הבקשה ארכה יותר מדי זמן. נסה שוב.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'שגיאת הרשאה. אנא פנה לתמיכה.';
    }
    if (msg.contains('500') || msg.contains('502') || msg.contains('503')) {
      return 'שגיאת שרת. נסה שוב מאוחר יותר.';
    }
    return 'שגיאה לא צפויה. נסה שוב.';
  }

  List<Product> get _filteredResults {
    final level = SearchScreenContent.effectiveFilterLevel(
      showOnlySafe: _filterByUserAllergens,
      configuredLevel: widget.userProfile.productFilterLevel,
    );
    // Fast path: the loosest level admits everything, so skip the per-product
    // status computation entirely.
    if (level == ProductFilterLevel.showAll) {
      return _results;
    }
    return _results
        .where((product) => level.allows(widget.userProfile.statusFor(product)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Compute the filtered list once per frame rather than once per read
    // (the empty-state branches, itemCount and itemBuilder all consume it).
    final filteredResults = _filteredResults;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('גלאי אלרגנים'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        floatingActionButton: widget.onAddProductTap == null
            ? null
            : FloatingActionButton(
                onPressed: widget.onAddProductTap,
                tooltip: 'הוסף מוצר',
                child: const Icon(Icons.add),
              ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'חפש מוצר',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('הצג רק מוצרים בטוחים'),
                value: _filterByUserAllergens,
                onChanged: (val) {
                  setState(() => _filterByUserAllergens = val);
                },
              ),
              // Only show the "showing cached results" banner when there are
              // actually cached rows to show; the stale-empty StateView below
              // covers the contradictory empty case on its own.
              if (_isStaleData && filteredResults.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.cloud_off,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'מצב לא מקוון - מציג תוצאות שמורות',
                          style: AppTypography.labelSm,
                        ),
                      ),
                      TextButton(
                        onPressed: _retrySearch,
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                ),
              if (_isLoading)
                const Expanded(child: SearchLoadingSkeleton())
              else if (_error != null)
                Expanded(
                  child: StateView(
                    icon: Icons.wifi_off,
                    title: 'שגיאה בטעינת תוצאות',
                    // Surface the specific message computed by
                    // _friendlyErrorMessage() (no connection / timeout / auth /
                    // server 5xx) rather than a generic network string.
                    // _error is guaranteed non-null in this branch.
                    message: _error,
                    actionLabel: 'נסה שוב',
                    onAction: _retrySearch,
                  ),
                )
              else if (_isStaleData && filteredResults.isEmpty)
                const Expanded(
                  child: StateView(
                    icon: Icons.cloud_off,
                    title: 'אין מוצרים שמורים תואמים',
                    message: 'נסה שוב כשתחזור למצב מקוון',
                  ),
                )
              else if (_results.isNotEmpty &&
                  filteredResults.isEmpty &&
                  _searchController.text.isNotEmpty)
                const Expanded(
                  child: StateView(
                    icon: Icons.filter_alt_off,
                    title: 'אין מוצרים העונים על המסנן',
                    message: 'נסה מילת חיפוש אחרת או שנה את המסנן',
                  ),
                )
              else if (_results.isNotEmpty && filteredResults.isEmpty)
                const Expanded(
                  child: StateView(
                    icon: Icons.filter_alt_off,
                    title: 'המסנן הנוכחי מסתיר את כל המוצרים',
                    message: 'שנה את המסנן כדי להציג מוצרים',
                  ),
                )
              else if (_searchController.text.isNotEmpty && filteredResults.isEmpty)
                const Expanded(
                  child: StateView(
                    icon: Icons.search_off,
                    title: 'לא נמצאו תוצאות',
                    message: 'נסה מילת חיפוש אחרת או סרוק ברקוד',
                  ),
                )
              else if (_searchController.text.isEmpty && filteredResults.isEmpty)
                const Expanded(
                  child: StateView(
                    icon: Icons.inventory_2_outlined,
                    title: 'אין מוצרים במערכת',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredResults.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredResults.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final product = filteredResults[index];
                      return ProductCard(
                        product: product,
                        userProfile: widget.userProfile,
onTap: () async {
                            // Resolving a search result to its details is a
                            // "scan" event for history purposes (#77).
                            ScanHistoryService.record(
                              product,
                              widget.userProfile,
                            );
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  product: product,
                                  userProfile: widget.userProfile,
                                ),
                              ),
                            );
                            if (result == true && mounted) {
                              _loadInitialProducts();
                            }
                          },
                        onReport: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeedbackScreen(
                                productId: product.id,
                                productName: product.nameHe,
                                productBarcode: product.barcode,
                                productImageUrl: product.imageUrl,
                                onSubmit: (type, message, image) async {
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for the active-search results list
/// (`active-search-results.md §5.1`).
///
/// Renders a fixed [ListView] of 4 [SearchLoadingSkeletonRow]s that mirror the
/// real product-card row layout, so the skeleton visually aligns with the live
/// list when results arrive — replacing the previous centered spinner.
class SearchLoadingSkeleton extends StatelessWidget {
  const SearchLoadingSkeleton({super.key});

  static const int _placeholderRowCount = 4;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Loading placeholders are not scrollable content.
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _placeholderRowCount,
      itemBuilder: (context, _) => const SearchLoadingSkeletonRow(),
    );
  }
}

/// A single 80 pt shimmer row mimicking the [ProductCard] layout: a 48×48
/// thumbnail, two stacked text lines, and a status-pill stub.
class SearchLoadingSkeletonRow extends StatelessWidget {
  const SearchLoadingSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, borderRadius: 8),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          SkeletonBox(width: 56, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}
