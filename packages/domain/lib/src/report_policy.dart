import 'errors.dart';
import 'identifiers.dart';
import 'result.dart';
import 'review/review.dart';
import 'review/review_status.dart';

const reportsRequiredForTemporaryHide = 3;

int uniqueReportCount(Iterable<UserId> reporters) => reporters.toSet().length;

bool shouldTemporarilyHide(Iterable<UserId> reporters) =>
    uniqueReportCount(reporters) >= reportsRequiredForTemporaryHide;

Result<Review> registerReviewReport(Review review, {required UserId reporterId, required DateTime now}) {
  if (review.authorId == reporterId) return const Failure(CannotReportOwnReview());
  if (review.status is! ReviewPublished) return const Failure(ReviewActionNotAllowed());
  if (review.reportedBy.contains(reporterId)) return const Failure(ReviewAlreadyReported());

  final reporters = {...review.reportedBy, reporterId};
  final status = shouldTemporarilyHide(reporters)
      ? ReviewHidden(hiddenAt: now.toUtc(), uniqueReportCount: uniqueReportCount(reporters))
      : review.status;
  return Success(review.copyWith(status: status, reportedBy: reporters));
}
