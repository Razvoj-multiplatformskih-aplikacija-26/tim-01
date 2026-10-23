import '../identifiers.dart';
import '../result.dart';
import '../review/review.dart';
import '../review/review_status.dart';

abstract interface class ReviewRepository {
  Future<List<Review>> loadReviews();

  Future<Result<Review>> addReview(Review review);

  Future<Result<Review>> reportReview({required ReviewId id, required UserId reporterId, required DateTime now});

  Future<Result<Review>> changeReviewStatus({required ReviewId id, required ReviewStatus status});
}
