import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);

  test('review workflow allows the intended eight transitions', () {
    final statuses = <ReviewStatus>[
      ReviewPending(submittedAt: now),
      ReviewPublished(publishedAt: now),
      ReviewHidden(hiddenAt: now, uniqueReportCount: 3),
      ReviewRejected(rejectedAt: now, reason: 'Dupliran sadržaj'),
      ReviewArchived(archivedAt: now),
    ];
    final allowed = <(Type, Type)>[];
    for (final from in statuses) {
      for (final to in statuses) {
        if (canTransition(from, to)) allowed.add((from.runtimeType, to.runtimeType));
      }
    }

    expect(allowed, [
      (ReviewPending, ReviewPublished),
      (ReviewPending, ReviewRejected),
      (ReviewPublished, ReviewHidden),
      (ReviewPublished, ReviewArchived),
      (ReviewHidden, ReviewPublished),
      (ReviewHidden, ReviewRejected),
      (ReviewHidden, ReviewArchived),
      (ReviewRejected, ReviewArchived),
    ]);
  });
}
