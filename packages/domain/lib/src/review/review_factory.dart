import '../identifiers.dart';
import '../result.dart';
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
  final parsedTitle = ReviewTitle.parse(title);
  final parsedBody = ReviewBody.parse(body);
  final parsedRating = RatingValue.fromInt(rating);
  final error = parsedTitle.errorOrNull ?? parsedBody.errorOrNull ?? parsedRating.errorOrNull;
  if (error != null) return Failure(error);

  final timestamp = submittedAt.toUtc();
  return Success(
    Review(
      id: id,
      deviceId: deviceId,
      authorId: authorId,
      title: parsedTitle.valueOrNull!,
      body: parsedBody.valueOrNull!,
      rating: parsedRating.valueOrNull!,
      status: ReviewPending(submittedAt: timestamp),
      submittedAt: timestamp,
    ),
  );
}
