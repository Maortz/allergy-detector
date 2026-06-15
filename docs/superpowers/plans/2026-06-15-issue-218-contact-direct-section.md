# Implementation Plan: issue #218 — contact-us direct-contact section + hero intro card (CC1/CC2)

**Branch:** `agent/issue-218-contact-direct-section` (already created — execution starts at Task 1)
**Issue:** https://github.com/Maortz/allergy-detector/issues/218
**Spec:** `docs/superpowers/specs/2026-05-19-stitch-screens/contact-us.md` §2.1, §4.1, §4.2, §5.7, §6.5
**Area:** fix(contact-us) — `app/lib/screens/contact_screen.dart`, `app/pubspec.yaml`,
`app/test/widgets/screens/contact_screen_test.dart`.

## Goal

Add the two missing direct-contact elements to `ContactScreen`, above the existing message form:

- **CC1** — a hero intro card (`#EBF4FF` tint, `support_agent` icon 32pt, centred intro copy).
- **CC2** — three `ContactMethodRow`s (Email / Phone / Hours). Email and Phone are tappable,
  launching `mailto:`/`tel:` via `url_launcher`; Hours is read-only.

The existing form (name/email/subject-picker/message/send — CC3–CC7) already matches the art and
must not change. After this lands, the index.md V-Art cell for contact-us flips ⚠→✓.

## Critical context (read before editing)

- **Form is complete and correct** in `app/lib/screens/contact_screen.dart`. The new content goes
  at the **top of the non-submitted `Column`** (build method, the `Form` branch, before
  `_buildNameField()`), so the success view (`_submitted == true`) is unaffected and the direct-
  contact block only shows alongside the form.
- **Existing widget tests** (`contact_screen_test.dart`) locate fields via
  `find.byType(TextFormField)` (expects exactly 3) and tap `find.text('שלח הודעה')`. The new hero
  card and contact rows add **no `TextFormField`** and no duplicate "שלח הודעה" text, so those
  tests keep passing. Verify this holds after the change.
- **Colour tokens already exist** — do not hardcode hex:
  - `AppColors.primaryTint` = `#EBF4FF` (hero card background; §2.1).
  - `AppColors.primaryTintBorder` = `#BFDBFE` (companion border).
  - `AppColors.primary` = `#00478D` (icons), `AppColors.onSurface` / `onSurfaceVariant` for text.
  - `AppColors.surfaceContainer` for the white contact-row background, `AppColors.outlineVariant`
    for its border (the file already uses these tokens).
- **`url_launcher`** is currently a *transitive* dependency at 6.3.2 (confirmed via
  `flutter pub add url_launcher --dry-run`). Promote it to a direct dependency in `pubspec.yaml`
  (`url_launcher: ^6.3.2`). No new package download — it is already resolved. No app exists with
  `launchUrl` usage yet, so this is the first; the spec §6.5 gives the exact pattern.
- **Exact spec values** (do not invent): email `support@allergycare.co.il`, phone display
  `03-1234567` / `tel:` path `031234567`, hours label "שעות פעילות" value "א'-ה' | 09:00-17:00",
  email label "דואר אלקטרוני", phone label "מוקד טלפוני". Hero copy (§4.1):
  "אנחנו כאן כדי לעזור לכם לשמור על ביטחון תזונתי. צרו איתנו קשר בכל שאלה או משוב."
- **MVP scope:** the issue lists only CC1 + CC2 in its acceptance criteria. The spec §4.2 mentions
  an optional "עקבו אחרינו" social row — **out of scope** for this issue (the AC enumerates only
  email/phone/hours; no concrete social handles are specified). Implement the three rows only.
- **Testing the launch:** widget tests will NOT invoke the real platform `launchUrl` (it throws a
  `MissingPluginException` in the test harness). Keep the launch behind a private helper; tests
  assert the rows render with the correct copy and are `InkWell`-tappable, not that the OS opened.

## Design

Add a private launch helper and three small private build methods to `_ContactScreenState`, plus a
top-of-Column insertion. Keep all business strings as `static const` where shared.

Constants (top-level, near `kContactSubjects`):

```dart
/// Direct-contact values shown in the contact-methods section (contact-us.md §4.2).
const String kContactEmail = 'support@allergycare.co.il';
const String kContactPhoneDisplay = '03-1234567';
const String kContactPhoneDial = '031234567';
const String kContactHours = "א'-ה' | 09:00-17:00";
```

Launch helper (uses `url_launcher`):

```dart
Future<void> _launchUri(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
```

Hero card and rows are `const`-friendly where possible; the rows that tap use `InkWell` with
`borderRadius: BorderRadius.circular(12)`.

## Tasks

### Task 1 — Promote url_launcher to a direct dependency

Edit `app/pubspec.yaml`. Under `dependencies:`, after `package_info_plus: ^8.0.0`, add:

```yaml
  url_launcher: ^6.3.2
```

Run `flutter pub get` — succeeds (already resolved transitively, so no version churn).

### Task 2 — TDD: add widget tests for the new section first (red)

Edit `app/test/widgets/screens/contact_screen_test.dart`. Add a new group inside `main()`:

```dart
  group('ContactScreen direct-contact section (CC1/CC2)', () {
    Widget buildSubject() => const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ContactScreen(),
          ),
        );

    testWidgets('renders the hero intro card copy (CC1)', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
        find.text(
          'אנחנו כאן כדי לעזור לכם לשמור על ביטחון תזונתי. '
          'צרו איתנו קשר בכל שאלה או משוב.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.support_agent), findsOneWidget);
    });

    testWidgets('renders the three contact-method rows (CC2)', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('דואר אלקטרוני'), findsOneWidget);
      expect(find.text('support@allergycare.co.il'), findsOneWidget);
      expect(find.text('מוקד טלפוני'), findsOneWidget);
      expect(find.text('03-1234567'), findsOneWidget);
      expect(find.text('שעות פעילות'), findsOneWidget);
      expect(find.text("א'-ה' | 09:00-17:00"), findsOneWidget);
    });

    testWidgets('email and phone rows are tappable (InkWell), hours is not',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      // The email row tap must not throw within the widget tree (the platform
      // launch is guarded by canLaunchUrl, which returns false under test).
      await tester.tap(find.text('support@allergycare.co.il'));
      await tester.pump();
      await tester.tap(find.text('03-1234567'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the existing form still renders below the new section',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      // Form intact: 3 text fields + send button unaffected by the new block.
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('שלח הודעה'), findsOneWidget);
    });
  });
```

Run `flutter test test/widgets/screens/contact_screen_test.dart` — the CC1/CC2 tests fail (copy /
icons not present yet). Expected red.

### Task 3 — Implement CC1 + CC2 (green)

Edit `app/lib/screens/contact_screen.dart`.

1. Add import at top (after the existing imports):

```dart
import 'package:url_launcher/url_launcher.dart';
```

2. Add the contact constants right after `kContactSubjects` (top-level), per Design.

3. Insert the hero card + contact section at the **top of the form Column**. Change:

```dart
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNameField(),
```

to:

```dart
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildContactMethods(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildNameField(),
```

4. Add the launch helper + build methods to `_ContactScreenState` (e.g. after
   `_buildSubmitButton()`):

```dart
  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTintBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, size: 32, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'אנחנו כאן כדי לעזור לכם לשמור על ביטחון תזונתי. '
            'צרו איתנו קשר בכל שאלה או משוב.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildContactRow(
          icon: Icons.email_outlined,
          label: 'דואר אלקטרוני',
          value: kContactEmail,
          onTap: () => _launchUri(Uri(scheme: 'mailto', path: kContactEmail)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildContactRow(
          icon: Icons.phone_outlined,
          label: 'מוקד טלפוני',
          value: kContactPhoneDisplay,
          onTap: () => _launchUri(Uri(scheme: 'tel', path: kContactPhoneDial)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildContactRow(
          icon: Icons.schedule_outlined,
          label: 'שעות פעילות',
          value: kContactHours,
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelBold
                  .copyWith(color: AppColors.onSurface),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
```

(Use `Icons.phone_outlined` / `Icons.schedule_outlined` — the spec names `phone`/`schedule`; the
outlined variants match the form's outlined-icon style. `Icons.email_outlined` is already used by
the email field. If any outlined name does not resolve in analyze, fall back to the non-outlined
`Icons.phone` / `Icons.schedule`.)

Run `flutter test test/widgets/screens/contact_screen_test.dart` — now green.

### Task 4 — Verify

Run from `app/`, one command at a time (no `&&`), flutter on PATH
(`export PATH="$PATH:/sdks/flutter/bin"`):

1. `flutter pub get` — succeeds.
2. `flutter analyze lib test` — **0 issues**.
3. `flutter test` — all green.

### Task 5 — A6 spec-table update

Edit `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`, row 17 (Contact Us). Flip the
**V-Art** cell from ⚠ to ✓ and update its note to record CC1+CC2 done in #218 (hero intro card +
email/phone/hours ContactMethodRows with mailto:/tel: via url_launcher). Leave the V-Spec cell as
is (CC1/CC2 were the V-Art gap). Do not touch other rows.

### Task 6 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Only this branch's commit(s). Foreign commits → STOP.

### Task 7 — A8 commit + PR

```
git add app/lib/screens/contact_screen.dart app/pubspec.yaml app/pubspec.lock app/test/widgets/screens/contact_screen_test.dart docs/superpowers/specs/2026-05-19-stitch-screens/index.md docs/superpowers/plans/2026-06-15-issue-218-contact-direct-section.md
git commit -m "<message>"
```

Commit message:

```
fix(contact-us): add hero intro card + direct-contact rows (#218)

Add the missing CC1 hero intro card (#EBF4FF tint, support_agent icon,
intro copy) and the CC2 direct-contact section (email / phone / hours
ContactMethodRows) above the existing message form, matching contact-us.md
§2.1/§4.1/§4.2. Email and phone rows launch mailto:/tel: via url_launcher
(promoted from a transitive to a direct dependency); the hours row is
read-only. The form (CC3-CC7) is unchanged. Flips the contact-us V-Art
cell to done.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push and open the PR:

```
git push -u origin agent/issue-218-contact-direct-section
gh pr create --repo Maortz/allergy-detector --base master --title "fix(contact-us): add missing direct-contact section + hero intro card (CC1/CC2) (#218)" --body "<body>"
```

PR body: `Closes #218`, summary (CC1 hero card + CC2 three contact rows with mailto:/tel: launch,
form untouched, url_launcher promoted to direct dep, index.md V-Art flipped), exact spec values
used, and `flutter analyze`/`flutter test` results.

### Task 8 — A9 comment + release claim

```
gh issue comment 218 --repo Maortz/allergy-detector --body "Opened PR <url> — <one-line summary>."
gh issue edit 218 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
