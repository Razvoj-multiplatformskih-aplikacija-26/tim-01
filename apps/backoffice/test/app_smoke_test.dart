import 'package:device_guide_backoffice/app.dart';
import 'package:device_guide_backoffice/data/demo_reviews.dart';
import 'package:device_guide_backoffice/data/memory_review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads reviews into the wide moderation layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = MemoryReviewRepository(createBackofficeDemoReviews(), latency: const Duration(milliseconds: 10));

    await tester.pumpWidget(DeviceGuideBackofficeApp(repository: repository, failureController: repository));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    expect(find.text('Moderacija recenzija'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Naslov'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Prečice: ↑/↓ izbor, Ctrl+A odobri, Ctrl+R odbij'), findsOneWidget);
    expect(find.text('Brzo stilizovanje bez prejake toplote'), findsNWidgets(2));
    expect(find.text('Status: Na proveri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty moderation state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = MemoryReviewRepository([], latency: Duration.zero);
    await tester.pumpWidget(DeviceGuideBackofficeApp(repository: repository, failureController: repository));
    await tester.pumpAndSettle();

    expect(find.text('Nema recenzija za obradu.'), findsOneWidget);
  });
}
