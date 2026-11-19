import 'package:meta/meta.dart';

import 'review/review_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class ReviewTitleTooShort extends DomainError {
  const ReviewTitleTooShort({required this.length, required this.minimum});

  final int length;
  final int minimum;

  @override
  bool operator ==(Object other) => other is ReviewTitleTooShort && other.length == length && other.minimum == minimum;

  @override
  int get hashCode => Object.hash(ReviewTitleTooShort, length, minimum);
}

@immutable
final class ReviewTitleTooLong extends DomainError {
  const ReviewTitleTooLong({required this.length, required this.maximum});

  final int length;
  final int maximum;

  @override
  bool operator ==(Object other) => other is ReviewTitleTooLong && other.length == length && other.maximum == maximum;

  @override
  int get hashCode => Object.hash(ReviewTitleTooLong, length, maximum);
}

@immutable
final class ReviewBodyTooShort extends DomainError {
  const ReviewBodyTooShort({required this.length, required this.minimum});

  final int length;
  final int minimum;

  @override
  bool operator ==(Object other) => other is ReviewBodyTooShort && other.length == length && other.minimum == minimum;

  @override
  int get hashCode => Object.hash(ReviewBodyTooShort, length, minimum);
}

@immutable
final class ReviewBodyTooLong extends DomainError {
  const ReviewBodyTooLong({required this.length, required this.maximum});

  final int length;
  final int maximum;

  @override
  bool operator ==(Object other) => other is ReviewBodyTooLong && other.length == length && other.maximum == maximum;

  @override
  int get hashCode => Object.hash(ReviewBodyTooLong, length, maximum);
}

@immutable
final class RatingOutOfRange extends DomainError {
  const RatingOutOfRange(this.value, {this.minimum = 1, this.maximum = 5});

  final int value;
  final int minimum;
  final int maximum;

  @override
  bool operator ==(Object other) =>
      other is RatingOutOfRange && other.value == value && other.minimum == minimum && other.maximum == maximum;

  @override
  int get hashCode => Object.hash(RatingOutOfRange, value, minimum, maximum);
}

@immutable
final class InvalidReviewTransition extends DomainError {
  const InvalidReviewTransition({required this.from, required this.to});

  final ReviewStatus from;
  final ReviewStatus to;

  @override
  bool operator ==(Object other) =>
      other is InvalidReviewTransition &&
      other.from.runtimeType == from.runtimeType &&
      other.to.runtimeType == to.runtimeType;

  @override
  int get hashCode => Object.hash(InvalidReviewTransition, from.runtimeType, to.runtimeType);
}

final class ReviewAlreadyReported extends DomainError {
  const ReviewAlreadyReported();
}

final class CannotReportOwnReview extends DomainError {
  const CannotReportOwnReview();
}

final class ReviewActionNotAllowed extends DomainError {
  const ReviewActionNotAllowed();
}

final class ReviewNotFound extends DomainError {
  const ReviewNotFound();
}

final class ForbiddenReviewAction extends DomainError {
  const ForbiddenReviewAction();
}

final class SessionExpired extends DomainError {
  const SessionExpired();
}

final class ServerUnavailable extends DomainError {
  const ServerUnavailable();
}

final class UnknownServerError extends DomainError {
  const UnknownServerError();
}
