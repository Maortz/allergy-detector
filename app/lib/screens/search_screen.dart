import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
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
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _productService.searchProducts(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text('שגיאה: $_error',
                    style: const TextStyle(color: Colors.red))
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
