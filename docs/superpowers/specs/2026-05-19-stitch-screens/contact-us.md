# Contact Us / צור קשר
Stitch screen: projects/16588854804615693446/screens/5a9bc40c2d8a46c7b760d2725cde2cf4
Maps to: app/lib/screens/contact_screen.dart

---

## 1. Purpose & context

The Contact Us screen gives users a single destination to reach the SafeScan support team — by email, phone, or an in-app message form. It is reached from the **navigation drawer** (`nav-drawer-user`), not from the bottom nav bar. There is no authentication requirement; any visitor can send a message.

Goals:
- Surface direct contact details (email, phone, operating hours) without requiring the user to open a form.
- Provide an in-app message form as a low-friction alternative to composing an external email.
- Maintain the app's Medical-Blue Clinical Clarity RTL aesthetic and Hebrew-first copy.

Screen height is taller than a single viewport (Stitch canvas: 2954 px @ 780 px wide), so the body scrolls.

---

## 2. Visual layout breakdown

Layout is a single `Scaffold` with:

```
Scaffold
├── AppBar (Detail bar variant)           — see _components-glossary.md#app-bar
├── Scrollable body (SingleChildScrollView)
│   ├── Hero intro card
│   ├── Contact methods section
│   │     ├── Contact method row — Email
│   │     ├── Contact method row — Phone
│   │     └── Contact method row — Hours
│   ├── Divider / vertical gap
│   └── Message form section
│         ├── Section heading
│         ├── TextField — Full name
│         ├── TextField — Email
│         ├── DropdownButtonFormField — Subject
│         ├── TextField (multiline) — Message
│         └── PrimaryButton — "שלח הודעה"
└── NavigationBar                         — see _components-glossary.md#bottom-nav
```

**Horizontal margins:** 16 pt on both sides throughout the body.
**Vertical rhythm:** 16 pt between major sections; 12 pt between form fields; 8 pt between a label and its input.

### 2.1 Hero intro card

Full-width card below the app bar.
- Background: `#EBF4FF` (light Medical-Blue tint, same as allergen-chip Variant A).
- Corner radius: 12 pt.
- Padding: 16 pt all sides.
- Content: optional icon (e.g. `support_agent` or `mail_outline`, 32 pt, `#00478D`) centred or leading, followed by body copy (see §4.1).

### 2.2 Contact methods section

Heading "פרטי יצירת קשר" (or implied by grouping) above three rows. Each row is a horizontal card:
- Background: `#FFFFFF`, corner radius 12 pt, padding 14 pt horizontal / 12 pt vertical.
- `BoxShadow`: `0 1 3 0 rgba(0,0,0,0.08)` (subtle elevation).
- Rows are separated by an 8 pt gap (not a full divider).

### 2.3 Message form section

Section heading above a white card containing all fields:
- Card: `#FFFFFF`, corner radius 12 pt, padding 16 pt, `BoxShadow` same as contact rows.
- Fields are listed vertically with 12 pt spacing.
- The submit button sits **outside** the card, full-width with 16 pt top margin.

---

## 3. Component inventory

| # | Component | Variant / notes | Reference |
|---|---|---|---|
| 1 | AppBar | Detail bar — screen title "צור קשר", no back arrow (accessed from drawer, not a push route); hamburger `menu` icon on RTL-left | see _components-glossary.md#app-bar |
| 2 | NavigationBar | Canonical 4-tab bar; no tab is "active" in drawer-origin context (or "בית" may stay active as default) | see _components-glossary.md#bottom-nav |
| 3 | Hero intro card | Screen-specific card (§4.1) | — |
| 4 | ContactMethodRow × 3 | Email / Phone / Hours (§4.2) | — |
| 5 | TextField — Full name | Single-line, Hebrew placeholder | §4.3 |
| 6 | TextField — Email | Single-line, keyboard type email | §4.3 |
| 7 | DropdownButtonFormField — Subject | 4 options (§4.3) | §4.3 |
| 8 | TextField — Message | Multiline (minLines 4), Hebrew placeholder | §4.3 |
| 9 | PrimaryButton — Send | Standard `#00478D` fill, label "שלח הודעה" | see _components-glossary.md#primary-button |

No `status-pill`, `allergen-chip`, or `wizard-chrome` appear on this screen.

---

## 4. Sub-components / element design

### 4.1 Hero intro card

```
╔══════════════════════════════════════════╗
║  [icon: support_agent 32pt #00478D]     ║
║                                          ║
║  אנחנו כאן כדי לעזור לכם לשמור         ║
║  על ביטחון תזונתי. צרו איתנו קשר       ║
║  בכל שאלה או משוב.                      ║
╚══════════════════════════════════════════╝
```

- Icon: `support_agent` (or `headset_mic`), 32 pt, `#00478D`, centred horizontally above text, 8 pt gap to text.
- Body text: Inter Regular 14 pt, `#374151` (AppColors.onSurface / token TBD), text-align centre, line-height 1.5.
- Exact copy: **"אנחנו כאן כדי לעזור לכם לשמור על ביטחון תזונתי. צרו איתנו קשר בכל שאלה או משוב."**

### 4.2 ContactMethodRow

Three rows, same structure, different icon/label/value:

```
╔══════════════════════════════════════════╗
║  [icon 24pt]  label         value-text  ║
╚══════════════════════════════════════════╝
```

RTL layout (right-to-left reading order):
- **Icon** (rightmost, RTL leading): Material icon, 24 pt, `#00478D`.
- **Label** (Inter Medium 13 pt, `#1F2937`): immediately left of icon, 8 pt gap.
- **Value** (Inter Regular 13 pt, `#6B7280`): pushed to trailing (leftmost) end of row, or placed on a second line below the label if space is tight.

Alternatively the label sits above the value in a Column, with the icon to the right — either layout is acceptable as long as the three rows are visually consistent.

| Row | Icon | Label | Value |
|---|---|---|---|
| Email | `email` | **"דואר אלקטרוני"** | `support@allergycare.co.il` |
| Phone | `phone` | **"מוקד טלפוני"** | `03-1234567` |
| Hours | `schedule` | **"שעות פעילות"** | **"א'-ה' | 09:00-17:00"** |

The email value should be a `mailto:` tappable link (`InkWell` → `url_launcher`). The phone value should be a `tel:` tappable link. Hours row is read-only.

Tappable rows get `InkWell` with `borderRadius: BorderRadius.circular(12)` and a subtle highlight on tap.

### 4.3 Message form fields

All text fields use the shared `InputDecoration` style:
- `OutlineInputBorder`, corner radius 8 pt, border color `#E5E7EB` (1 pt), focused border `#00478D` (1.5 pt).
- Background fill: `#F9FAFB` (token TBD).
- Label / floating label: Inter Medium 13 pt, `#374151` unfocused, `#00478D` focused.
- Placeholder / hint: Inter Regular 13 pt, `#9CA3AF`.

| Field | Type | Placeholder (Hebrew) | Validation |
|---|---|---|---|
| שם מלא | `TextFormField` single-line | **"שם מלא"** | Required; non-empty |
| דואר אלקטרוני | `TextFormField` `keyboardType: email` | **"דואר אלקטרוני"** | Required; valid email format |
| נושא | `DropdownButtonFormField` | **"בחר נושא"** | Required; one of four options |
| הודעה | `TextFormField` `minLines: 4, maxLines: 8` | **"הודעה"** | Required; non-empty |

**Subject dropdown options** (exact Hebrew, in display order):
1. "תמיכה טכנית"
2. "דיווח על טעות במוצר"
3. "הצעת שיתוף פעולה"
4. "אחר"

The dropdown uses the same `OutlineInputBorder` decoration as the text fields.

### 4.4 Send button

see _components-glossary.md#primary-button (Standard variant).

- Label: **"שלח הודעה"**
- Width: full-width within 16 pt horizontal margins.
- Height: 48 pt, `BorderRadius.circular(12)`.
- Leading icon: `send` (optional, mirrored for RTL), or no icon.
- Disabled state: when any required field is empty or the form has not been touched.
- Loading state: `CircularProgressIndicator(color: Colors.white, strokeWidth: 2)` replaces label text while the submit request is in flight.

---

## 5. States & interactions

### 5.1 Default / idle

All form fields empty. Send button is **enabled** (Stitch does not show a disabled pre-touch state, so eager-enable is acceptable; validation fires on submit). Contact method rows display static content with tappable email/phone rows.

### 5.2 Field focus

Tapping a `TextFormField` raises the keyboard (mobile) or activates caret (web).
- Border transitions to `#00478D` (1.5 pt).
- Floating label lifts and turns `#00478D`.
- No other layout change.

### 5.3 Inline validation (on submit or on-leave)

If a required field is empty or email is malformed:
- Border: `#DC2626` (1 pt).
- Error text below field: Inter Regular 12 pt, `#DC2626`.
- Copy examples:
  - שם מלא: **"נא למלא שם מלא"**
  - דואר אלקטרוני: **"נא להזין כתובת דוא"ל תקינה"**
  - נושא: **"נא לבחור נושא"**
  - הודעה: **"נא לכתוב הודעה"**

### 5.4 Loading / submitting

After the user taps "שלח הודעה" with all fields valid:
- Button enters Loading state (spinner replaces label, button remains full-width, non-tappable).
- Form fields become `enabled: false` (visually dimmed, `#F3F4F6` background).
- A `CircularProgressIndicator` or loading overlay is optional — the button state alone is sufficient for perceived responsiveness.

### 5.5 Success state

On successful submission the screen shows a **success message** replacing or overlaying the form:
- A centered `Icon(Icons.check_circle, size: 64, color: #16A34A)`.
- Heading: Inter SemiBold 18 pt, `#1F2937` — **"ההודעה נשלחה בהצלחה!"**
- Body: Inter Regular 14 pt, `#6B7280` — **"נחזור אליכם בהקדם האפשרי."**
- A "חזרה לדף הבית" text button or `PrimaryButton` navigating back (pop to home).

Implementation choice: replace form `Column` with success `Column` in place (no push navigation), or use a `showDialog`/`SnackBar`. The in-place replacement is the Stitch intent.

### 5.6 Error / network failure state

If the backend returns an error:
- Button exits Loading state, label restored.
- `SnackBar` (bottom): **"שליחת ההודעה נכשלה. אנא נסה שנית."** with a "נסה שנית" action.
- Form fields re-enabled; values preserved.

### 5.7 Email / phone taps (ContactMethodRow)

- Email row tap → `url_launcher` opens `mailto:support@allergycare.co.il`.
- Phone row tap → `url_launcher` opens `tel:03-1234567`.
- Hours row: no tap action; `InkWell` not applied.

---

## 6. Data & controller contract

### 6.1 State fields

```dart
class ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController    = TextEditingController();
  final _emailController   = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedSubject;   // one of the four Hebrew option strings
  bool _isSubmitting = false;
  bool _submitted    = false; // true → show success state
}
```

### 6.2 Subject options constant

```dart
const List<String> kContactSubjects = [
  'תמיכה טכנית',
  'דיווח על טעות במוצר',
  'הצעת שיתוף פעולה',
  'אחר',
];
```

### 6.3 Submit handler

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isSubmitting = true);
  try {
    // POST to Supabase edge function or direct email service
    await ContactService.send(
      name:    _nameController.text.trim(),
      email:   _emailController.text.trim(),
      subject: _selectedSubject!,
      message: _messageController.text.trim(),
    );
    setState(() { _isSubmitting = false; _submitted = true; });
  } catch (e) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('שליחת ההודעה נכשלה. אנא נסה שנית.')),
    );
  }
}
```

### 6.4 ContactService

A new thin service class, `app/lib/services/contact_service.dart`, following the existing pattern (receives no `SupabaseClient` if contacting an external email relay, or receives one if posting to a Supabase function).

```dart
class ContactService {
  static Future<void> send({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    // Implementation TBD: Supabase Edge Function, EmailJS, or similar.
    // Throws on network/server error.
  }
}
```

### 6.5 External URL launching

Uses `url_launcher` package (already a dependency in the Flutter app):

```dart
Future<void> _launchEmail() async {
  final uri = Uri(scheme: 'mailto', path: 'support@allergycare.co.il');
  if (await canLaunchUrl(uri)) launchUrl(uri);
}

Future<void> _launchPhone() async {
  final uri = Uri(scheme: 'tel', path: '031234567');
  if (await canLaunchUrl(uri)) launchUrl(uri);
}
```

### 6.6 Navigation

Reached via `Navigator.push` (or `pushNamed`) from `nav-drawer-user`. The AppBar does **not** show a back arrow in the Stitch design (drawer-origin context), but a back arrow (`Icons.arrow_back_ios`) should be added in the Flutter implementation for accessibility (the drawer closes and returns to the previous main tab on pop). This is a design-vs-app delta (see §7.3).

---

## 7. Open questions / design-vs-app deltas

### 7.1 Back navigation in AppBar

**Delta:** The Stitch design shows the screen title "צור קשר" in the AppBar with a hamburger `menu` icon on the trailing side. In the app implementation, since the screen is pushed onto the navigator stack from the drawer, a leading back-arrow should be added for standard Android/web back-navigation behaviour. The menu icon may be omitted on this sub-screen.
**Recommended resolution:** Use a standard `IconButton(icon: Icon(Icons.arrow_back_ios))` as the leading action (auto-provided by `AppBar` with `automaticallyImplyLeading: true`), and omit the hamburger. Record during implementation review.

### 7.2 Bottom nav active-tab state

**Delta:** The bottom nav is present in the Stitch HTML (canonical 4-tab set, consistent with DD-2/DD-4). When Contact Us is reached from the drawer, no bottom tab strictly "owns" this screen. The app should leave the previously active tab highlighted (e.g. "בית" if launched from home).
**No new decision needed** — this is an implementation detail consistent with the canonical bottom nav (see _components-glossary.md#bottom-nav).

### 7.3 Submit endpoint not specified in Stitch

**Delta:** The Stitch design is purely visual — it specifies no backend. The `ContactService.send()` implementation (§6.4) is left as TBD. Options: Supabase Edge Function forwarding to SendGrid/Resend, EmailJS client-side relay, or a simple Supabase table insert for admin review. This is an architecture decision, not a design inconsistency.

### 7.4 Success state modality

**Delta:** Stitch shows no explicit success state screen/overlay. The spec (§5.5) proposes an in-place form replacement. If a dedicated `contact-us-success` Stitch screen is created later, this section should be updated.

### 7.5 Bottom nav tab set observed in HTML

The HTML extraction confirms: **בית / סריקה / קהילה / מועדפים** — this matches the DD-2/DD-4 canonical set exactly. No divergence delta to record here.

### 7.6 Stitch title says "Contact Us (Updated)" — "(Updated)" suffix

The Stitch screen title is "Contact Us (Updated)". This suffix is a Stitch project artefact (likely a revision of an earlier draft). It has no mapping to any in-app copy. The in-app screen title remains **"צור קשר"**.
