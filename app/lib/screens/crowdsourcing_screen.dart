import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../services/product_service.dart';

enum AllergenState { none, contains, mayContain }

class CrowdsourcingScreen extends StatefulWidget {
  final List<Allergen> allergens;

  const CrowdsourcingScreen({super.key, required this.allergens});

  @override
  State<CrowdsourcingScreen> createState() => _CrowdsourcingScreenState();
}

class _CrowdsourcingScreenState extends State<CrowdsourcingScreen> {
  final _searchController = TextEditingController();
  final _productService = ProductService(Supabase.instance.client);
  
  Product? _foundProduct;
  bool _isSearching = false;
  String? _error;
  bool _showScanner = false;
  
  final Map<String, AllergenState> _allergenStates = {};
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _error = null;
      _foundProduct = null;
    });
    
    try {
      final product = await _productService.searchProduct(query);
      setState(() {
        _foundProduct = product;
        _isSearching = false;
        
        if (product != null) {
          _initAllergenStates(product.allergenIds ?? []);
        }
      });
    } catch (e) {
      setState(() {
        _error = 'שגיאה בחיפוש: $e';
        _isSearching = false;
      });
    }
  }

  void _initAllergenStates(List<String> existingIds) {
    _allergenStates.clear();
    for (final allergen in widget.allergens) {
      if (existingIds.contains(allergen.id)) {
        _allergenStates[allergen.id] = AllergenState.contains;
      } else {
        _allergenStates[allergen.id] = AllergenState.none;
      }
    }
  }

  void _onBarcodeScanned(String barcode) {
    setState(() => _showScanner = false);
    _searchController.text = barcode;
    _searchProduct(barcode);
  }

  Future<void> _submitAllergens() async {
    if (_foundProduct == null) return;
    
    final contains = <String>[];
    final mayContain = <String>[];
    
    for (final entry in _allergenStates.entries) {
      if (entry.value == AllergenState.contains) {
        contains.add(entry.key);
      } else if (entry.value == AllergenState.mayContain) {
        mayContain.add(entry.key);
      }
    }
    
    try {
      await _productService.updateProductAllergens(
        _foundProduct!.id,
        contains,
        mayContain,
      );
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('תודה!'),
          ],
        ),
        content: const Text('הנתונים נשמרו בהצלחה. תורמים לקהילה בטוחה יותר! 🎉'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _foundProduct = null;
                _searchController.clear();
                _allergenStates.clear();
              });
            },
            child: const Text('מוצר נוסף'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('סגירה'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הוסף מוצר למאגר'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: _showScanner ? _buildScanner() : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchSection(),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _foundProduct != null
                  ? _buildProductFound()
                  : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'הזן ברקוד או שם מוצר',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _searchProduct,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => setState(() => _showScanner = true),
                icon: const Icon(Icons.qr_code_scanner),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'חפש מוצר לפי ברקוד',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'סרוק ברקוד או הזן מספר ידנית\nכדי להוסיף מידע על אלרגנים',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductFound() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProductCard(),
          const SizedBox(height: 24),
          _buildAllergenPicker(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _submitAllergens,
            icon: const Icon(Icons.save),
            label: const Text('שמור שינויים'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_foundProduct!.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _foundProduct!.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 32),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _foundProduct!.nameHe,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_foundProduct!.brandNameHe != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _foundProduct!.brandNameHe!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'ברקוד: ${_foundProduct!.barcode}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'בחר אלרגנים',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'לחץ על האלרגן לבחירת מצב',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.allergens.length,
          itemBuilder: (context, index) {
            final allergen = widget.allergens[index];
            final state = _allergenStates[allergen.id] ?? AllergenState.none;
            return _buildAllergenChip(allergen, state);
          },
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(Colors.green, 'מכיל'),
        _buildLegendItem(Colors.orange, 'עשוי להכיל'),
        _buildLegendItem(Colors.grey, 'ללא'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAllergenChip(Allergen allergen, AllergenState state) {
    Color backgroundColor;
    Color textColor;
    String emoji = allergen.emoji ?? '';
    
    switch (state) {
      case AllergenState.contains:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case AllergenState.mayContain:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case AllergenState.none:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        break;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            final current = _allergenStates[allergen.id] ?? AllergenState.none;
            switch (current) {
              case AllergenState.none:
                _allergenStates[allergen.id] = AllergenState.contains;
                break;
              case AllergenState.contains:
                _allergenStates[allergen.id] = AllergenState.mayContain;
                break;
              case AllergenState.mayContain:
                _allergenStates[allergen.id] = AllergenState.none;
                break;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                allergen.nameHe,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              _onBarcodeScanned(barcodes.first.rawValue!);
            }
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton.filled(
            onPressed: () => setState(() => _showScanner = false),
            icon: const Icon(Icons.close),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}