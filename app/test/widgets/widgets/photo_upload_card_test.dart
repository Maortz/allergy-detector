import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/photo_upload_card.dart';

void main() {
  group('PhotoUploadCard', () {
    testWidgets('empty state shows the upload prompt, no thumbnail (spec §4)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoUploadCard(label: 'חזית המוצר'),
          ),
        ),
      );

      expect(find.text('חזית המוצר'), findsOneWidget);
      expect(find.text('תמונה של המוצר או המרכיבים'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      // No re-shoot badge in the empty state.
      expect(find.byIcon(Icons.photo_camera), findsNothing);
    });

    testWidgets(
        'thumbnail state fills the tile with the image, hides prompt copy, '
        'and shows the re-shoot badge (spec §4)', (tester) async {
      var tapped = 0;
      const key = Key('thumb');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoUploadCard(
              label: 'חזית המוצר',
              imagePath: '/tmp/front.jpg',
              onTap: () => tapped++,
              thumbnailBuilder: (path) =>
                  ColoredBox(key: key, color: const Color(0xFF123456)),
            ),
          ),
        ),
      );

      // The injected thumbnail renders.
      expect(find.byKey(key), findsOneWidget);
      // The upload-prompt copy is hidden once a thumbnail is shown.
      expect(find.text('חזית המוצר'), findsNothing);
      expect(find.text('תמונה של המוצר או המרכיבים'), findsNothing);
      // The re-shoot / replace badge is present.
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
      expect(
        find.bySemanticsLabel('החלף תמונה'),
        findsOneWidget,
      );

      // Tapping the tile triggers the replace flow (onTap).
      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(tapped, 1);
    });
  });
}
