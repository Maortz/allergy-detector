import 'package:flutter/material.dart';
import 'product_details.dart';
import 'feedback_screen.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../services/search_cache.dart';
import '../widgets/product_card.dart';
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
  List<Product> _results = [];
  bool _isLoading = false;
  bool _filterByUserAllergens = false;
  String? _error;
  bool _isStaleData = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isStaleData = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isStaleData = false;
    });

    try {
      final results = await _productService.searchProducts(query);
      await SearchCache.save(query, results);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
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
      return product.allergens.any((a) => userIds.contains(a.allergenId));
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
                title: const Text('הצג רק מוצרים עם האלרגיות שלי'),
                value: _filterByUserAllergens,
                onChanged: (val) {
                  setState(() => _filterByUserAllergens = val);
                },
              ),
              if (_isStaleData)
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
                        onPressed: _onSearchChanged,
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                ),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            Text(_error!, style: const TextStyle(fontSize: 13)),
                      ),
                      TextButton(
                        onPressed: _onSearchChanged,
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_searchController.text.isEmpty)
                const Center(child: Text('חפש מוצר לפי שם או ברקוד'))
              else
                Expanded(
                  child: _filteredResults.isEmpty
                      ? const Center(child: Text('לא נמצאו תוצאות'))
                      : ListView.builder(
                          itemCount: _filteredResults.length,
                          itemBuilder: (context, index) {
                            final product = _filteredResults[index];
                            return ProductCard(
                              product: product,
                              userProfile: widget.userProfile,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(
                                      product: product,
                                      userProfile: widget.userProfile,
                                    ),
                                  ),
                                );
                              },
                              onReport: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FeedbackScreen(
                                      productId: product.id,
                                      productName: product.nameHe,
                                      onSubmit: (type, message) async {
                                        // Call FeedbackService to submit
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
