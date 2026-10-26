part of 'review_bloc.dart';

enum ReviewAction { submitted, reported, approved, rejected, republished, archived }

sealed class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => const [];
}

final class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

final class ReviewsLoading extends ReviewState {
  const ReviewsLoading();
}

final class ReviewsEmpty extends ReviewState {
  const ReviewsEmpty();
}

final class ReviewsFailure extends ReviewState {
  const ReviewsFailure({required this.debugMessage});

  final String debugMessage;

  @override
  List<Object?> get props => [debugMessage];
}

final class ReviewActionFailure extends ReviewState {
  const ReviewActionFailure({required this.error, required this.revision});

  final DomainError error;
  final int revision;

  @override
  List<Object?> get props => [error, revision];
}

final class ReviewsReady extends ReviewState {
  const ReviewsReady({required this.reviews, required this.revision, this.lastAction, this.actionError});

  final List<Review> reviews;
  final ReviewAction? lastAction;
  final DomainError? actionError;
  final int revision;

  ReviewsReady copyWith({
    List<Review>? reviews,
    ReviewAction? lastAction,
    DomainError? actionError,
    int? revision,
    bool clearLastAction = false,
    bool clearActionError = false,
  }) {
    return ReviewsReady(
      reviews: reviews ?? this.reviews,
      lastAction: clearLastAction ? null : lastAction ?? this.lastAction,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [reviews, lastAction, actionError, revision];
}
