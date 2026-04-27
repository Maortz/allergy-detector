import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductScreen extends StatefulWidget {
  final List<Allergen> allergens;

  const AddProductScreen({super.key, required this.allergens});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _brandController = TextEditingController();
  
  final Set<String> _selectedContains = {};
  final Set<String> _selectedMayContain = {};
  bool _isKosher = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _ingredientsController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הוסף מוצר'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם המוצר *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'נא להזין שם מוצר';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'מותג (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'ברקוד (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ingredientsController,
                  decoration: const InputDecoration(
                    labelText: 'רכיבים (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('כשר'),
                  value: _isKosher,
                  onChanged: (val) => setState(() => _isKosher = val),
                ),
                const SizedBox(height: 16),
                _buildAllergenSection('מכיל:', _selectedContains, true),
                const SizedBox(height: 16),
                _buildAllergenSection('עשוי להכיל:', _selectedMayContain, false),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submitProduct,
                    child: const Text('שמור מוצר'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllergenSection(String title, Set<String> selected, bool isContains) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.allergens.map((allergen) {
            final isSelected = selected.contains(allergen.id);
            return FilterChip(
              label: Text(allergen.nameHe),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    selected.add(allergen.id);
                  } else {
                    selected.remove(allergen.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productService = ProductService(Supabase.instance.client);
      
      await productService.addProduct(
        nameHe: _nameController.text.trim(),
        brandName: _brandController.text.trim().isEmpty 
            ? null 
            : _brandController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty 
            ? null 
            : _barcodeController.text.trim(),
        ingredients: _ingredientsController.text.trim().isEmpty 
            ? null 
            : _ingredientsController.text.trim(),
        isKosher: _isKosher,
        containAllergenIds: _selectedContains.toList(),
        mayContainAllergenIds: _selectedMayContain.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המוצר נוסף בהצלחה!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}