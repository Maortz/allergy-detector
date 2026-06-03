import 'package:flutter/material.dart';
import 'community_screen.dart';
import 'product_details.dart';
import 'feedback_screen.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../services/search_cache.dart';
import '../widgets/product_card.dart';
import '../widgets/state_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreenContent extends StatefulWidget {
  final UserProfile userProfile;
  final List<Allergen> allergens;
  final ValueChanged<UserProfile> onProfileUpdated;

  const SearchScreenContent({
    super.key,
    required this.userProfile,
    required this.allergens,
    required this.onProfileUpdated,
  });

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
    if (!_filterByUserAllergens) return _results;
    return _results.where((product) {
      final userIds = widget.userProfile.selectedAllergenIds;
      return !product.allergens.any((a) => userIds.contains(a.allergenId));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('גלאי אלרגנים'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityScreen(
                  currentNavIndex: 2,
                  onNavIndexChanged: (i) {},
                ),
              ),
            );
          },
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
              if (_isStaleData && _filteredResults.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.cloud_off,
                          color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'מצב לא מקוון - מציג תוצאות שמורות',
                          style: TextStyle(fontSize: 12),
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
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: StateView(
                    icon: Icons.wifi_off,
                    title: 'שגיאה בטעינת תוצאות',
                    message: 'בדוק חיבור אינטרנט ונסה שנית',
                    actionLabel: 'נסה שוב',
                    onAction: _retrySearch,
                  ),
                )
              else if (_isStaleData && _filteredResults.isEmpty)
                const Expanded(
                  child: StateView(
                    icon: Icons.cloud_off,
                    title: 'אין מוצרים שמורים תואמים',
                    message: 'נסה שוב כשתחזור למצב מקוון',
                  ),
                )
              else if (_searchController.text.isNotEmpty && _filteredResults.isEmpty)
                const Expanded(
                  child: StateView(
                    icon: Icons.search_off,
                    title: 'לא נמצאו תוצאות',
                    message: 'נסה מילת חיפוש אחרת או סרוק ברקוד',
                  ),
                )
              else if (_searchController.text.isEmpty && _filteredResults.isEmpty)
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
                    itemCount: _filteredResults.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _filteredResults.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final product = _filteredResults[index];
                      return ProductCard(
                        product: product,
                        userProfile: widget.userProfile,
onTap: () async {
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
                                onSubmit: (type, message) async {
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
