import '../identifiers.dart';
import '../result.dart';
import '../review_permissions.dart';
import 'review.dart';
import 'review_status.dart';
import 'review_values.dart';

Result<Review> createPendingReview({
  required ReviewId id,
  required DeviceId deviceId,
  required UserId authorId,
  required String title,
  required String body,
  required int rating,
  required DateTime submittedAt,
}) {
  final parsed = _parseReviewContents(title, body, rating);
  if (parsed case Failure(:final error)) return Failure(error);
  final values = parsed.valueOrNull!;
  final timestamp = submittedAt.toUtc();
  return Success(
    Review(
      id: id,
      deviceId: deviceId,
      authorId: authorId,
      title: values.title,
      body: values.body,
      rating: values.rating,
      status: ReviewPending(submittedAt: timestamp),
      submittedAt: timestamp,
    ),
  );
}

Result<Review> editPendingReview(
  Review review, {
  required UserId actorId,
  required UserRole role,
  required String title,
  required String body,
  required int rating,
}) {
  final permissionError = reviewEditError(review, actorId, role);
  if (permissionError != null) return Failure(permissionError);
  final parsed = _parseReviewContents(title, body, rating);
  if (parsed case Failure(:final error)) return Failure(error);
  final values = parsed.valueOrNull!;
  return Success(review.copyWith(title: values.title, body: values.body, rating: values.rating));
}

typedef _ReviewContents = ({ReviewTitle title, ReviewBody body, RatingValue rating});

Result<_ReviewContents> _parseReviewContents(String title, String body, int rating) {
  final parsedTitle = ReviewTitle.parse(title);
  final parsedBody = ReviewBody.parse(body);
  final parsedRating = RatingValue.fromInt(rating);
  final error = parsedTitle.errorOrNull ?? parsedBody.errorOrNull ?? parsedRating.errorOrNull;
  if (error != null) return Failure(error);
  return Success((title: parsedTitle.valueOrNull!, body: parsedBody.valueOrNull!, rating: parsedRating.valueOrNull!));
}
