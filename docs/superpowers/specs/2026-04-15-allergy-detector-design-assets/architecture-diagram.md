# Allergy Detector App – System Architecture Diagram (MVP)

```
+-------------------+     search/profile/feedback      +------------------+
|                   | <-----------------------------> |                  |
|   Flutter App     |                                 |    Supabase DB   |
| (Android/iOS/Web) |------------+  images fetch/---->| (Postgres,       |
|                   |            |  upload           |  Storage, Auth)  |
+-------------------+            |                   +------------------+
          ^                      |                              ^
          |                      |                              |
          |    admin/moderate    |   scheduled/batch import     |
          |   via browser        v      +   update              |
+-------------------+    +--------------------+        +------------------+
|                   |--->| Data Import/Sync   |<------>|  Admin Web       |
| Community Reports |    | Service (OpenFood  |        |  Dashboard       |
|  (Feedback table) |    | Facts, Scraping)   |        | (Supabase UI)    |
|                   |    +--------------------+        +------------------+
```

**Legend:**
- `Flutter App`: End-user interface for search, onboarding, results, corrections.
- `Supabase DB`: Hosts products, brands, allergens, user feedback and images.
- `Admin Web Dashboard`: Moderator admin/review access via browser.
- `Data Import/Sync`: Scheduled imports from Open Food Facts/other sources, bi-directional sync, resolves updates, removals, new entries, and conflicts (with admin review as needed).
- Arrows: Solid for frequent/user, dashed for scheduled batch, parallel for mod actions.

(See detailed plan section 3 for architectural assumptions and admin/reconciliation flow.)
