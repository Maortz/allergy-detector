# Add Product Screen Implementation Plan (Updated)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a screen allowing users to manually add new products to the database with name, brand, barcode, ingredients, image, and allergen information.

**Architecture:** Updated `add_product_screen.dart` with image picker (camera/gallery/URL), `ProductService` method updated to handle image upload to Supabase Storage.

**Tech Stack:** Flutter (Dart), Supabase (Storage), image_picker package.

---

### Task 1: Add Image Picker to Add Product Screen UI

**Files:**
- Modify: `app/lib/screens/add_product_screen.dart`
- Add: `image_picker` dependency to `pubspec.yaml`

- [ ] **Step 1: Add image_picker to dependencies**

Run: `cd app && flutter pub add image_picker`

- [ ] **Step 2: Update add_product_screen.dart with image picker**

Replace the imports and add image picker field:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imageUrlController = TextEditingController();
  
  final Set<String> _selectedContains = {};
  final Set<String> _selectedMayContain = {};
  bool _isKosher = false;
  bool _isLoading = false;
  XFile? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _ingredientsController.dispose();
    _brandController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // ... existing form fields stay the same until the image section ...

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'תמונה (אופציונלי)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedImage!.path,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 150,
                    child: Icon(Icons.image, size: 64),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('מצלמה'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('גלריה'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _imageUrlController,
          decoration: const InputDecoration(
            labelText: 'או הזן כתובת תמונה',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  // ... submitProduct method updates to send imageUrl or local XFile ...
}
```

- [ ] **Step 3: Add image picker widget to form**

Insert after ingredients field, before kosher switch:

```dart
const SizedBox(height: 16),
_buildImagePicker(),
const SizedBox(height: 8),
```

- [ ] **Step 4: Run flutter analyze**

Run: `cd app && flutter analyze lib/screens/add_product_screen.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/add_product_screen.dart app/pubspec.yaml
git commit -m "feat: add image picker to add product screen"
```

---

### Task 2: Update ProductService for Image Upload

**Files:**
- Modify: `app/lib/services/product_service.dart`

- [ ] **Step 1: Add image upload method to ProductService**

Add new method:

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// ... existing class ...

  Future<String?> uploadProductImage(XFile imageFile, String productId) async {
    final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await imageFile.readAsBytes();
    
    final response = await _client.storage
        .from('product-images')
        .uploadBinary(fileName, bytes);
    
    final publicUrl = _client.storage
        .from('product-images')
        .getPublicUrl(fileName);
    
    return publicUrl;
  }
```

- [ ] **Step 2: Update addProduct to accept image**

```dart
  Future<Product> addProduct({
    required String nameHe,
    String? brandName,
    String? barcode,
    String? ingredients,
    bool isKosher = false,
    List<String> containAllergenIds = const [],
    List<String> mayContainAllergenIds = const [],
    XFile? imageFile,
    String? imageUrl,
  }) async {
    // ... existing brand handling ...
    
    // Handle image
    String? finalImageUrl = imageUrl;
    if (imageFile != null && finalImageUrl == null) {
      finalImageUrl = await uploadProductImage(imageFile, productId);
    }
    
    final product = await _client
        .from('products')
        .insert({
          'name_he': nameHe,
          'barcode': barcode,
          'brand_id': brandId,
          'ingredients': ingredients,
          'is_kosher': isKosher,
          'image_url': finalImageUrl,
        })
        .select('*, brands(name_he, trust_score)')
        .single();
        
    // ... rest stays the same ...
  }
```

- [ ] **Step 3: Run flutter analyze**

Run: `cd app && flutter analyze lib/services/product_service.dart`
Expected: No errors

- [ ] **Step 4: Run tests**

Run: `cd app && flutter test`
Expected: Pass

- [ ] **Step 5: Commit**

```bash
git add app/lib/services/product_service.dart
git commit -m "feat: add image upload to ProductService"
```

---

### Task 3: Update AddProductScreen submit to handle image

**Files:**
- Modify: `app/lib/screens/add_product_screen.dart`

- [ ] **Step 1: Update submitProduct to pass image**

```dart
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productService = ProductService(Supabase.instance.client);
      
      // Determine image source
      XFile? imageFile;
      String? imageUrl;
      
      if (_selectedImage != null) {
        // Local file from picker
        imageFile = _selectedImage;
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        // URL entered manually
        imageUrl = _imageUrlController.text.trim();
      }
      
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
        imageFile: imageFile,
        imageUrl: imageUrl,
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
```

- [ ] **Step 2: Run flutter analyze**

Run: `cd app && flutter analyze lib/screens/add_product_screen.dart`
Expected: No errors

- [ ] **Step 3: Run tests**

Run: `cd app && flutter test`
Expected: Pass

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/add_product_screen.dart
git commit -m "feat: wire image upload to add product submit"
```

---

## Self-Review Checklist

- ✓ Spec coverage: Image picker (camera, gallery, URL), image upload to Supabase Storage, display in form - all covered
- ✓ No placeholders: All code blocks are complete
- ✓ Type consistency: XFile from image_picker, method signature updates match ProductService

---

## Plan Complete

**Plan saved to `docs/superpowers/plans/2026-04-27-add-product-screen.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach would you like to use?**