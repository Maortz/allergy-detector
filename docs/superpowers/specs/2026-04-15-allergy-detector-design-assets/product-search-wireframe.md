# Allergy Detector App – Product Search Result Screen (Wireframe)

```
+---------------------------------------------------------------+
| [חפש מוצר...]    [🔎]    (Typeahead Search Bar)              |
+---------------------------------------------------------------+
| [סנן: הצג רק מוצרים עם האלרגיות שלי]   (Filter Toggle)         |
+---------------------------------------------------------------+
|   🖼️ | מוצר: חטיף בוטנים                  | TRUST: מהימן   |
|      | מותג: סניקרס    🔵                 |                |
|      +---------------------+-------------+------------------+
|      | מכיל:               | עשוי להכיל:                        |
|      | [🍫 בוטנים]         | [🥜 אגוזי מלך]                      |
|      +---------------------+-------------+------------------+
|      |  [⚠️ הימנע] (אדום)  |  [⚠️ זהירות] (צהוב)                |
|      |  [דווח בעיה]  (כפתור)                                    |
+---------------------------------------------------------------+
|   🖼️ | מוצר: רוגלך שוקולד               | TRUST: פחות מהימן|
|      | מותג: מאפיית א.א.   🟠                |                |
|      +---------------------+-------------+------------------+
|      | מכיל:               | עשוי להכיל:                        |
|      | [🥚 ביצים]         |                                        |
|      +---------------------+-------------+------------------+
|      |  [✔️ בטוח] (ירוק)                                   |
|      |  [דווח בעיה]  (כפתור)                                    |
+---------------------------------------------------------------+
| צבעים/סמלים: ירוק = בטוח | אדום = הימנע | צהוב = זהירות (עשוי להכיל)
```

**Explanation:**
- Each card shows: product image, product/brand name, trust badge, two allergen sections (“מכיל:”/Contains and “עשוי להכיל:”/May Contain), status indication based on user’s profile (green = safe, red = avoid, yellow = caution), and feedback button.
- RTL alignment, sample Hebrew values, and clear color/icon use for accessibility.
- Typing in search bar live-filters cards (typeahead), toggle filters by user allergens.
- All controls are large-touch optimized (mobile-first), with high-contrast for status and icons.
- At the bottom: legend for all status colors/icons.

(Typography/layout can be adapted for high-fidelity visual as needed later.)
