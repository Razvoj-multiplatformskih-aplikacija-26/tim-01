import 'errors.dart';
import 'identifiers.dart';
import 'review/review.dart';
import 'review/review_status.dart';

enum UserRole { mobile, editor }

enum ReviewVisibility { published, publishedAndOwn, all }

final class ReviewViewer {
  const ReviewViewer({this.id, this.role});

  final UserId? id;
  final UserRole? role;
}

bool canSubmitReview(UserRole? role) => role == UserRole.mobile;

bool canReportReviews(UserRole? role) => role == UserRole.mobile;

bool canReportReview(Review review, UserId? userId, UserRole? role) =>
    canReportReviews(role) && userId != null && review.status.isPublic && userId != review.authorId;

bool canModerateReviews(UserRole? role) => role == UserRole.editor;

ReviewVisibility reviewVisibility(UserRole? role) => switch (role) {
  UserRole.mobile => ReviewVisibility.publishedAndOwn,
  UserRole.editor => ReviewVisibility.all,
  null => ReviewVisibility.published,
};

bool canViewReview(Review review, UserId? userId, UserRole? role) => switch (reviewVisibility(role)) {
  ReviewVisibility.published => review.status.isPublic,
  ReviewVisibility.publishedAndOwn => review.status.isPublic || userId == review.authorId,
  ReviewVisibility.all => true,
};

bool canEditOwnPendingReview(Review review, UserId? userId, UserRole? role) =>
    reviewEditError(review, userId, role) == null;

DomainError? reviewEditError(Review review, UserId? userId, UserRole? role) {
  if (role != UserRole.mobile || userId != review.authorId) return const ForbiddenReviewAction();
  if (review.status is! ReviewPending) return const ReviewActionNotAllowed();
  return null;
}
