import '../errors.dart';
import '../result.dart';
import 'review.dart';
import 'review_status.dart';

bool canTransition(ReviewStatus from, ReviewStatus to) => switch ((from, to)) {
  (ReviewPending(), ReviewPublished()) => true,
  (ReviewPending(), ReviewRejected()) => true,
  (ReviewPublished(), ReviewHidden()) => true,
  (ReviewPublished(), ReviewArchived()) => true,
  (ReviewHidden(), ReviewPublished()) => true,
  (ReviewHidden(), ReviewRejected()) => true,
  (ReviewHidden(), ReviewArchived()) => true,
  (ReviewRejected(), ReviewArchived()) => true,
  _ => false,
};

Result<Review> applyReviewStatus(Review review, ReviewStatus next) {
  if (!canTransition(review.status, next)) {
    return Failure(InvalidReviewTransition(from: review.status, to: next));
  }
  return Success(review.copyWith(status: next));
}
