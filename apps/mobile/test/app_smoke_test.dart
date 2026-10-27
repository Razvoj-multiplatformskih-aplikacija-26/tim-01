import 'package:device_guide_mobile/app.dart';
import 'package:device_guide_mobile/data/demo_reviews.dart';
import 'package:device_guide_mobile/data/memory_review_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens the catalog and loads the reviews flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = MemoryReviewRepository(createDemoReviews(), latency: Duration.zero);

    await tester.pumpWidget(DeviceGuideMobileApp(repository: repository, failureController: repository));
    await tester.pumpAndSettle();

    expect(find.text('Vodič za uređaje'), findsOneWidget);
    expect(find.text('Pronađite odgovarajući uređaj'), findsOneWidget);

    await tester.tap(find.text('Pogledaj recenzije'));
    await tester.pumpAndSettle();

    expect(find.text('Demo sadrži najmanje deset zapisa i svako stanje recenzije.'), findsOneWidget);
    expect(find.text('Prijatniji je za svakodnevno sušenje'), findsOneWidget);
    expect(find.text('Nova recenzija'), findsOneWidget);
  });
}
