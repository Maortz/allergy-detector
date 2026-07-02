import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app/screens/add_product_screen.dart';
import 'package:app/services/photo_upload_service.dart';
import 'package:app/widgets/photo_upload_card.dart';
import '../../helpers/test_fixtures.dart';

/// Upload stub that fails [failCount] times before succeeding — lets the test
/// drive the error → retry → success path deterministically (spec §5).
class _FlakyUploadService extends PhotoUploadService {
  _FlakyUploadService({this.failCount = 1});

  int failCount;
  int attempts = 0;

  @override
  Future<String> upload(String localPath) async {
    attempts++;
    if (failCount > 0) {
      failCount--;
      throw Exception('simulated upload failure');
    }
    return localPath;
  }
}

/// Upload stub whose [upload] future stays pending until the test resolves it,
/// so a callback can be made to land *after* the slot is cleared (#351 race).
class _DeferredUploadService extends PhotoUploadService {
  final Completer<String> completer = Completer<String>();
  int attempts = 0;

  @override
  Future<String> upload(String localPath) {
    attempts++;
    return completer.future;
  }
}

void main() {
  group('PhotoUploadCard upload-error state (spec §5)', () {
    testWidgets('renders error icon, Hebrew copy, and a retry button',
        (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploadCard(
              label: 'חזית המוצר',
              imagePath: '/tmp/front.jpg',
              isError: true,
              onRetry: () => retried++,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('העלאת התמונה נכשלה'), findsOneWidget);

      final retry = find.widgetWithText(TextButton, 'נסה שוב');
      expect(retry, findsOneWidget);
      // Error state hides the thumbnail/prompt copy.
      expect(find.text('חזית המוצר'), findsNothing);

      await tester.tap(retry);
      await tester.pump();
      expect(retried, 1);
    });

    // Issue #351 (Option C): a set error flag with no image present must fall
    // through to the empty/prompt state, not the error/retry tile.
    testWidgets('error flag with no imagePath renders the empty state',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoUploadCard(
              label: 'חזית המוצר',
              imagePath: null,
              isError: true,
            ),
          ),
        ),
      );

      // No error UI — the stale flag is ignored without an image.
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('העלאת התמונה נכשלה'), findsNothing);
      expect(find.widgetWithText(TextButton, 'נסה שוב'), findsNothing);
      // The empty upload prompt is shown instead.
      expect(find.text('חזית המוצר'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });

  group('AddProductWizard step-2 upload error → retry → success', () {
    testWidgets(
        'a failed upload shows the error tile; retry re-attempts and a '
        'successful upload clears the error back to the thumbnail state',
        (tester) async {
      final upload = _FlakyUploadService(failCount: 1);
      await tester.pumpWidget(
        MaterialApp(
          home: AddProductWizard(
            allergens: TestFixtures.sampleAllergens,
            photoUploadService: upload,
          ),
        ),
      );

      final state =
          tester.state<AddProductWizardState>(find.byType(AddProductWizard));

      // Simulate a front-photo pick whose upload fails the first time.
      await state.selectFrontPhotoForTest('/tmp/front.jpg');
      await tester.pump();

      expect(upload.attempts, 1);
      expect(state.frontUploadFailed, isTrue);

      // Move to step 2 so the tile (and its retry affordance) renders.
      state.goToStepForTest(2);
      await tester.pump();
      expect(find.text('העלאת התמונה נכשלה'), findsOneWidget);

      // Tap retry — the second attempt succeeds and the error clears.
      await tester.tap(find.widgetWithText(TextButton, 'נסה שוב'));
      await tester.pump();

      expect(upload.attempts, 2);
      expect(state.frontUploadFailed, isFalse);
      expect(find.text('העלאת התמונה נכשלה'), findsNothing);
      // The tile is back to the captured/thumbnail state (re-shoot badge shown).
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    });

    // Issue #351 (Option A): an in-flight upload that fails *after* the user
    // taps Skip (clearing the slot) must not flip the now-empty tile into the
    // error state. Returning to step 2 shows the empty/initial state.
    testWidgets(
        'upload failing after Skip does not resurrect the error state on Back',
        (tester) async {
      final upload = _DeferredUploadService();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: AddProductWizard(
            allergens: TestFixtures.sampleAllergens,
            photoUploadService: upload,
          ),
        ),
      );

      final state =
          tester.state<AddProductWizardState>(find.byType(AddProductWizard));
      state.goToStepForTest(2);
      await tester.pump();

      // Select a front photo; the upload stays in flight (completer pending).
      // Do NOT await — the future only resolves when the test decides.
      unawaited(state.selectFrontPhotoForTest('/tmp/front.jpg'));
      await tester.pump();
      expect(state.frontImagePathForTest, '/tmp/front.jpg');
      expect(upload.attempts, 1);

      // Tap Skip before the upload completes: clears the slot, advances to 3.
      await tester.ensureVisible(find.text('דילוג והזנה ידנית'));
      await tester.tap(find.text('דילוג והזנה ידנית'));
      await tester.pump();
      expect(state.frontImagePathForTest, isNull);

      // The in-flight upload now fails — its stale callback must self-discard.
      upload.completer.completeError(Exception('late failure'));
      await tester.pump();
      expect(state.frontUploadFailed, isFalse);

      // Back to step 2: both tiles render the empty state, no error tile.
      state.goToStepForTest(2);
      await tester.pump();
      expect(find.text('העלאת התמונה נכשלה'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}
