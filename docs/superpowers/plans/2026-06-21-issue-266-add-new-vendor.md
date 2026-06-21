# Plan: Add new vendor inline on Add Product step 1 (#266)

Branch `agent/issue-266-add-new-vendor` is already created. Execution starts at the first code task.

## Context

`AddProductWizard` step 1 (`app/lib/screens/add_product_screen.dart`) picks a vendor from a
fixed `DropdownButtonFormField<String>` over `widget.brands` (a `List<String>`) — there is no way
to enter a vendor that isn't already listed. The wizard already injects `ProductService?
productService` for tests (subclass-override pattern, see `add_product_submit_test.dart`
`_FakeProductService`).

The real `brands` table (supabase/schema.sql) has columns `name_he`, `trust_score`, … —
`ProductService.addProduct` already inserts `{name_he, trust_score: 0.5}` when a brand name is
new. (Note: `BrandService.saveBrand`/`Brand.toJson` write `name`/`is_verified`/`last_updated`,
which do NOT match this schema — so do NOT use BrandService here. Mirror the proven
`ProductService` insert instead.)

## Approach

1. Add `ProductService.addBrand(String nameHe)` that inserts `{name_he, trust_score: 0.5}` into
   `brands` and returns the stored `name_he` (mirrors the insert already in `addProduct`).
2. In the wizard, keep a local `late List<String> _brands` (seeded from `widget.brands`,
   re-synced in `didUpdateWidget`). The dropdown iterates `_brands`.
3. Add a sentinel dropdown item "➕ הוסף מותג חדש" (a private const sentinel string distinct from
   any real name and from null). Selecting it opens an inline dialog (`showDialog`) with a single
   "שם המותג" text field + cancel/save actions.
4. On save: trim → if empty, show inline dialog validation; else call
   `productService.addBrand(name)`. On success: add to `_brands` (dedup), set `_selectedBrand`,
   close dialog. On failure: keep the dialog/form, show an error (SnackBar) — no data loss.
5. Existing "select from list" path unchanged (sentinel handled separately in `onChanged`).

## Tasks

### Task 1 — `ProductService.addBrand`

In `app/lib/services/product_service.dart` add:
```dart
/// Inserts a new vendor/brand by Hebrew name and returns the stored name.
/// Mirrors the brand auto-create already performed inside [addProduct] so the
/// add-product wizard can create a vendor inline (#266).
Future<String> addBrand(String nameHe) async {
  final row = await _client
      .from('brands')
      .insert({'name_he': nameHe, 'trust_score': 0.5})
      .select('name_he')
      .single();
  return row['name_he'] as String;
}
```

### Task 2 — Local brand list + service handle in the wizard

In `AddProductWizardState`:
- Add `late List<String> _brands;` and `late final ProductService _productService = widget.productService ?? ProductService(Supabase.instance.client);` (the submit path already builds a ProductService inline at L158 — reuse this single field there too to avoid duplication).
- `initState`: `_brands = List<String>.from(widget.brands);`
- `didUpdateWidget`: if `widget.brands` identity changed, re-seed `_brands` (preserving any locally-added names is acceptable to drop on a real prop change; keep it simple — reseed from the prop).

### Task 3 — Sentinel item + dialog

- Add `static const _addVendorSentinel = '__add_new_vendor__';`.
- Dropdown items: placeholder (null) + `_brands` + a trailing
  `DropdownMenuItem(value: _addVendorSentinel, child: Text('➕ הוסף מותג חדש'))`.
- `onChanged`: if `val == _addVendorSentinel` → call `_openAddVendorDialog()` (do NOT set
  `_selectedBrand` to the sentinel); else set `_selectedBrand = val`.
- `_openAddVendorDialog()`: `showDialog` returning the created name or null; uses a local
  `TextEditingController` (disposed in the dialog builder via a StatefulBuilder or a small
  private dialog widget). On confirm with a non-empty trimmed name, await
  `_productService.addBrand(name)`; on success `setState` to add to `_brands` + select; on error
  show `ScaffoldMessenger` SnackBar 'לא ניתן להוסיף מותג, נסו שוב' and keep the form.

### Task 4 — Reuse `_productService` in submit

Update `_submit` (L158) to use the new `_productService` field instead of constructing a fresh
`ProductService` inline (single source).

### Task 5 — Tests

In `app/test/widgets/screens/add_product_submit_test.dart` (or a new
`add_product_vendor_test.dart`) using the `_FakeProductService` pattern (override `addBrand`):
- Selecting "➕ הוסף מותג חדש", typing a name, confirming → the new name becomes the selected
  vendor and `addBrand` was called once with that name.
- Error path: `addBrand` throws → an error SnackBar shows and `_selectedBrand` is not set to the
  new name (form intact).
Extend `_FakeProductService` with `addBrand` override (record name / optional throw).

### Task 6 — Verify (one command at a time)

```
cd app
flutter pub get
flutter analyze lib test
flutter test
```

analyze 0 issues; tests green.

### Task 7 — A6 spec index update

Update the add-product-step-1 row note in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` to record #266 (inline "add new
vendor" via a dropdown sentinel + dialog → `ProductService.addBrand` insert → auto-select; error
keeps the form).

### Task 8 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Foreign commits → STOP.

### Task 9 — A8 commit + PR

Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; push; `gh pr create --base master`,
body `Closes #266`, summary, analyze/test results.

### Task 10 — A9 comment + release

Comment on #266 linking PR; `gh issue edit 266 --repo Maortz/allergy-detector --remove-label agent-in-progress`.
