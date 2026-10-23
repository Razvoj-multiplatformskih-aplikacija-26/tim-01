import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);

  Review publishedReview({Set<UserId> reportedBy = const {}}) {
    return Review(
      id: const ReviewId('review-1'),
      deviceId: const DeviceId('device-1'),
      authorId: const UserId('author'),
      title: ReviewTitle.parse('Odličan uređaj').valueOrNull!,
      body: ReviewBody.parse('Koristim ga svakog dana i veoma sam zadovoljan rezultatima.').valueOrNull!,
      rating: RatingValue.fromInt(5).valueOrNull!,
      status: ReviewPublished(publishedAt: now),
      submittedAt: now,
      reportedBy: reportedBy,
    );
  }

  test('third unique reporter temporarily hides a published review', () {
    final review = publishedReview(reportedBy: const {UserId('u-1'), UserId('u-2')});
    final result = registerReviewReport(review, reporterId: const UserId('u-3'), now: now);

    expect(result.valueOrNull?.status, isA<ReviewHidden>());
    expect(result.valueOrNull?.reportedBy.length, 3);
  });

  test('same user cannot report twice', () {
    final review = publishedReview(reportedBy: const {UserId('u-1')});
    expect(
      registerReviewReport(review, reporterId: const UserId('u-1'), now: now),
      const Failure<Review>(ReviewAlreadyReported()),
    );
  });

  test('author cannot report own review', () {
    expect(
      registerReviewReport(publishedReview(), reporterId: const UserId('author'), now: now),
      const Failure<Review>(CannotReportOwnReview()),
    );
  });
}
