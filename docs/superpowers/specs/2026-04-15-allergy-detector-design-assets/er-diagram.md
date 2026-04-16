# Allergy Detector App – Entity Relationship Diagram (MVP)

```
+-----------+        +------------+
|  Product  |        |   Brand    |
+-----------+        +------------+
| id        |<>----+-| id         |<------+
| name_he   |      | | name_he    |       |
| barcode   |      | | trust_score|       |
| brand_id  |------+ | logo_url   |       |
| image_url |      | | external_id|       |
| external_ |      | | created_at |       |
| source_id |      | +------------+       |
| last_synced_at   |                      |
| is_archived      |                      |
| created_at       |                      |
+-----------+        +------------+       |
       |                                   |
       |    +-------------------+          |
       +--->| product_allergens |          |
            +-------------------+          |
            | product_id (PK,FK)|          |
            | allergen_id(PK,FK)|          |
            | severity (PK)     |          |
            +-------------------+          |
                  |                        |
                  v                        |
            +--------------+              |
            | Allergen     |<-------------+
            +--------------+
            | id           |
            | name_he (UNI)|
            | icon_url     |
            | created_at   |
            +--------------+

            +----------------+
            | FeedbackReport |
            +----------------+
            | id             |
            | product_id (FK)|
            | type (ENUM)    |
            | message        |
            | submitted_at   |
            | resolved       |
            +----------------+
```

**Legend:**
- `Product` has FK `brand_id` to `Brand`.
- `product_allergens` is a junction table replacing the former `allergens uuid[]` / `might_be_allergens uuid[]` arrays. It provides referential integrity via FK constraints on both `product_id` and `allergen_id`.
- `product_allergens.severity` is a check-constrained text field: `'contains'` (explicit/in-label) or `'may_contain'` (possible/cross-contamination). This replaces the two separate array columns.
- `FeedbackReport` references `Product` via `product_id` (many reports per product). `type` is a Postgres enum: `allergen_missing`, `allergen_wrong`, `product_info_wrong`, `other`.
- `Brand.trust_score` defaults to 0.5; manually set for MVP, computed from feedback/data freshness post-MVP.
- `is_archived`, `external_source_id`, and sync fields are used for admin/backoffice updates and to avoid user data confusion.
- Unique constraints: `products.barcode`, `allergens.name_he`.
- Indexes on `products.barcode`, `products.name_he`, `products.brand_id`, `product_allergens.product_id`, `product_allergens.allergen_id`, `feedback_reports.product_id`.

All text fields with `_he` suffix are expected to be Hebrew/RTL first for MVP. All tables include `created_at` timestamps.
