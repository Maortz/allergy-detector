# Allergy Detector App – MVP Full Design Specification

## 1. Introduction and Goals
- Challenge: Supermarket shoppers must instantly know if a product is safe, dangerous, or uncertain for their allergies.
- Solution: Mobile-first app (Flutter: Android/iOS/Web, Hebrew-first RTL) powered by user allergen profiles and live product search with community/brand trust.
- Data: Open Food Facts as core source, regular sync, product images, community edits, real-time moderation.

## 2. User Flows
- **Onboarding:** User selects allergens (multi-select, no login).
- **Product Search:** Instant typeahead, fast results; toggle to show only products matching user allergens (confirmed + might be).
- **Result Card:** Product image, brand/trust badge, "מכיל" (confirmed allergens) and "עשוי להכיל" (might-be allergens)—clear status (avoid/caution/safe).
- **Feedback:** "Report problem" immediately available per result; unlimited (device cooldown anti-spam).
- **Admin/Mod:** All reports/data in Supabase dashboard; archiving/updates on sync (products are never purged, only hidden from user search when obsolete/archived).

## 3. System Architecture
(See `2026-04-15-allergy-detector-design-assets/architecture-diagram.md`)
- Flutter App (Android/iOS/Web, RTL/Hebrew): search, onboarding, reporting, images—all via Supabase.
- Supabase: Postgres for data (products, brands, allergens, feedback), Storage for images/logos/icons, Auth (mod only for now).
- Data Import/Sync: Nightly or triggered import/sync of Open Food Facts (products, brands, images), plus potential scraping in future.
- Admin Dashboard: Moderation via Supabase UI; all updates, archivals, and report resolution tracked.
- All data flows two-way for updates/corrections; community changes flagged for admin attention if overwritten by sync.

## 4. Data Model (see `2026-04-15-allergy-detector-design-assets/er-diagram.md`)
### Product
- id, name_he, barcode (unique), brand_id (FK), image_url, external_source_id, last_synced_at, is_archived, created_at
### ProductAllergens (junction table)
- product_id (PK,FK), allergen_id (PK,FK), severity (PK: 'contains' | 'may_contain')
- Replaces former `allergens uuid[]` / `might_be_allergens uuid[]` arrays for referential integrity
### Brand
- id, name_he, trust_score (default 0.5), logo_url, external_source_id, created_at
### Allergen
- id, name_he (unique), icon_url, created_at
### FeedbackReport
- id, product_id (FK), type (enum: allergen_missing | allergen_wrong | product_info_wrong | other), message, submitted_at, resolved

## 5. UI Screens
- **Search/Results Screen (see product-search-wireframe.md):**
   - RTL, color/icon legend
   - Image, brand/trust, explicit and "may contain" allergens, status (green/red/yellow), feedback
   - Accessible, mobile-optimized.
- **Filter toggle:** Show only products with user allergens (future: multi-filter)

## 6. Moderation & Feedback Flows
- All feedback visible in admin; client-side anti-spam via SharedPreferences rate-limit (1 per product per device per 60s)
- Admins resolve/archive/correct data; archived = hidden, not deleted
- Sync jobs import/correct/archive from Open Food Facts, with flag-on-overwrite of community updates
- MVP: community interaction limited to feedback reports only (bug reports on allergen/product data). Direct editing of product/allergen data by community members is post-MVP

## 7. Internationalization
- Hebrew/RTL only for MVP; all data model fields prepared for i18n (name_he, icon_url)

## 8. Roadmap
- Barcode scan (Flutter plugin); advanced filter/search, cloud sync/login, batch moderation/scraping more sources, full offline, expand to new locales, community direct editing of allergen data, automatic trust_score computation

---
# Visual Assets
- System architecture, ER, and wireframe diagrams: See `2026-04-15-allergy-detector-design-assets/`

---
_Approve or edit this spec to begin implementation (“writing-plans”)—your feedback is always welcome!_
