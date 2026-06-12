import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
