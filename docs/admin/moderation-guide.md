# Admin Moderation Guide

## Overview
All admin moderation for the MVP is done through the Supabase Dashboard at:
https://app.supabase.com/project/fxtdpzdzdiseabxteokd

## Feedback Triage

### Viewing Feedback Reports
1. Navigate to **Table Editor** > `feedback_reports`
2. Filter by `resolved = false` to see open reports
3. Sort by `submitted_at` to see newest first

### Resolving a Report
1. Open the report row
2. Review the `type`, `message`, and associated `product_id`
3. If the report is valid:
   - Update the product data as needed (allergens, name, brand, etc.) in `products` or `product_allergens`
   - Set `resolved = true` on the report
4. If the report is invalid/spam:
   - Set `resolved = true` without making data changes

### Report Types
| Type | Hebrew | Action |
|------|--------|--------|
| `allergen_missing` | אלרגן חסר | Add missing allergen to `product_allergens` |
| `allergen_wrong` | אלרגן שגוי | Remove/replace incorrect allergen in `product_allergens` |
| `product_info_wrong` | מידע מוצר שגוי | Update product name, barcode, brand, etc. |
| `other` | אחר | Review manually |

## Product Management

### Archiving a Product
Set `is_archived = true` on the product row. Archived products are hidden from user search but never deleted.

### Adding a New Product
1. Insert into `brands` first if the brand does not exist
2. Insert into `products` with required fields (`name_he`)
3. Insert into `product_allergens` for each allergen with `severity` = `contains` or `may_contain`

### Updating Trust Score
`brand.trust_score` is a 0.0-1.0 value. For MVP, set manually:
- 0.9+ = highly trusted (verified brand with consistent data)
- 0.5-0.9 = moderate trust
- Below 0.5 = low trust (many unresolved reports, new brand)

## Data Sync

### Import from Open Food Facts
Run the import script:
```bash
dart run scripts/import-openfoodfacts.dart
```
This will:
1. Fetch products from OFF API
2. Match by barcode or create new products
3. Update `last_synced_at` on synced products
4. Flag conflicts where community data differs from OFF data

### Conflict Resolution
When a sync overwrites community-edited data:
1. Check `feedback_reports` for any open reports on the affected product
2. If community data was more accurate, revert the sync changes
3. Consider increasing the brand's `trust_score` if community edits are consistently better
