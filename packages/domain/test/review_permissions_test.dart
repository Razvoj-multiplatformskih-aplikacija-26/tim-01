import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const author = UserId('author');
  const other = UserId('other');
  final now = DateTime.utc(2026, 11, 16);
  final pending = createPendingReview(
    id: const ReviewId('review-1'),
    deviceId: const DeviceId('device-1'),
    authorId: author,
    title: 'Početna recenzija',
    body: 'Ovaj tekst opisuje korišćenje uređaja duže od nedelju dana.',
    rating: 3,
    submittedAt: now,
  ).valueOrNull!;
  final published = pending.copyWith(status: ReviewPublished(publishedAt: now));

  Result<Review> edit(Review review, UserId actor, {String title = 'Ažuriran naslov'}) => editPendingReview(
    review,
    actorId: actor,
    role: UserRole.mobile,
    title: title,
    body: 'Ovaj tekst opisuje iskustvo nakon još mesec dana korišćenja.',
    rating: 5,
  );

  test('guests see published reviews and mobile users can also see their own', () {
    expect(canViewReview(published, null, null), isTrue);
    expect(canViewReview(pending, null, null), isFalse);
    expect(canViewReview(pending, other, UserRole.mobile), isFalse);
    expect(canViewReview(pending, author, UserRole.mobile), isTrue);
    expect(canViewReview(pending, other, UserRole.editor), isTrue);
  });

  test('only editors may moderate and only mobile users may submit or report', () {
    expect(canModerateReviews(UserRole.editor), isTrue);
    expect(canModerateReviews(UserRole.mobile), isFalse);
    expect(canModerateReviews(null), isFalse);
    expect(canSubmitReview(UserRole.mobile), isTrue);
    expect(canSubmitReview(null), isFalse);
    expect(canReportReviews(UserRole.mobile), isTrue);
    expect(canReportReviews(UserRole.editor), isFalse);
  });

  test('a mobile author can edit only their own pending content', () {
    final edited = edit(pending, author).valueOrNull!;
    expect(edited.id, pending.id);
    expect(edited.authorId, author);
    expect(edited.status, pending.status);
    expect(edited.submittedAt, pending.submittedAt);
    expect(edited.title.value, 'Ažuriran naslov');
    expect(edited.rating.value, 5);
    expect(edit(pending, other).errorOrNull, const ForbiddenReviewAction());
    expect(edit(published, author).errorOrNull, const ReviewActionNotAllowed());
  });

  test('edit of own pending review uses the same content validation as submission', () {
    expect(edit(pending, author, title: 'ok').errorOrNull, isA<ReviewTitleTooShort>());
  });
}
