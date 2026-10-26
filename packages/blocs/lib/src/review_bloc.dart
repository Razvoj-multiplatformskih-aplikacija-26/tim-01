import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import 'request_failure_controller.dart';

part 'review_event.dart';
part 'review_state.dart';

final class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  factory ReviewBloc({
    required ReviewRepository repository,
    required ReviewId Function() idGenerator,
    required DateTime Function() clock,
    RequestFailureController? failureController,
  }) => ReviewBloc._(repository, idGenerator, clock, failureController);

  ReviewBloc._(this._repository, this._idGenerator, this._clock, this._failureController)
    : super(const ReviewInitial()) {
    on<ReviewsRequested>(_onReviewsRequested);
    on<ReviewSubmitted>(_onReviewSubmitted);
    on<ReviewReported>(_onReviewReported);
    on<ReviewApproved>(_onReviewApproved);
    on<ReviewRejectedByEditor>(_onReviewRejected);
    on<ReviewRepublished>(_onReviewRepublished);
    on<ReviewArchivedByEditor>(_onReviewArchived);
    on<ReviewFailureDemoRequested>(_onFailureDemoRequested);
  }

  final ReviewRepository _repository;
  final ReviewId Function() _idGenerator;
  final DateTime Function() _clock;
  final RequestFailureController? _failureController;
  int _revision = 0;

  Future<void> _onReviewsRequested(ReviewsRequested event, Emitter<ReviewState> emit) async {
    await _load(emit);
  }

  Future<void> _onReviewSubmitted(ReviewSubmitted event, Emitter<ReviewState> emit) async {
    final review = createPendingReview(
      id: _idGenerator(),
      deviceId: event.deviceId,
      authorId: event.authorId,
      title: event.title,
      body: event.body,
      rating: event.rating,
      submittedAt: _clock(),
    );
    if (review case Failure<Review>(:final error)) {
      _emitActionError(emit, error);
      return;
    }
    await _completeMutation(await _repository.addReview(review.valueOrNull!), ReviewAction.submitted, emit);
  }

  Future<void> _onReviewReported(ReviewReported event, Emitter<ReviewState> emit) async {
    await _completeMutation(
      await _repository.reportReview(id: event.id, reporterId: event.reporterId, now: _clock()),
      ReviewAction.reported,
      emit,
    );
  }

  Future<void> _onReviewApproved(ReviewApproved event, Emitter<ReviewState> emit) async {
    await _completeMutation(
      await _repository.changeReviewStatus(
        id: event.id,
        status: ReviewPublished(publishedAt: _clock().toUtc()),
      ),
      ReviewAction.approved,
      emit,
    );
  }

  Future<void> _onReviewRejected(ReviewRejectedByEditor event, Emitter<ReviewState> emit) async {
    await _completeMutation(
      await _repository.changeReviewStatus(
        id: event.id,
        status: ReviewRejected(rejectedAt: _clock().toUtc(), reason: event.reason),
      ),
      ReviewAction.rejected,
      emit,
    );
  }

  Future<void> _onReviewRepublished(ReviewRepublished event, Emitter<ReviewState> emit) async {
    await _completeMutation(
      await _repository.changeReviewStatus(
        id: event.id,
        status: ReviewPublished(publishedAt: _clock().toUtc()),
      ),
      ReviewAction.republished,
      emit,
    );
  }

  Future<void> _onReviewArchived(ReviewArchivedByEditor event, Emitter<ReviewState> emit) async {
    await _completeMutation(
      await _repository.changeReviewStatus(
        id: event.id,
        status: ReviewArchived(archivedAt: _clock().toUtc()),
      ),
      ReviewAction.archived,
      emit,
    );
  }

  Future<void> _onFailureDemoRequested(ReviewFailureDemoRequested event, Emitter<ReviewState> emit) async {
    _failureController?.failNextRequest();
    await _load(emit);
  }

  Future<void> _completeMutation(Result<Review> result, ReviewAction action, Emitter<ReviewState> emit) async {
    if (result case Failure<Review>(:final error)) {
      _emitActionError(emit, error);
      return;
    }
    await _load(emit, lastAction: action);
  }

  void _emitActionError(Emitter<ReviewState> emit, DomainError error) {
    final current = state;
    if (current is ReviewsReady) {
      emit(current.copyWith(actionError: error, clearLastAction: true, revision: ++_revision));
      return;
    }
    emit(ReviewActionFailure(error: error, revision: ++_revision));
  }

  Future<void> _load(Emitter<ReviewState> emit, {ReviewAction? lastAction}) async {
    emit(const ReviewsLoading());
    try {
      final reviews = await _repository.loadReviews();
      if (reviews.isEmpty) {
        emit(const ReviewsEmpty());
      } else {
        emit(ReviewsReady(reviews: reviews, lastAction: lastAction, revision: ++_revision));
      }
    } on Object catch (error) {
      emit(ReviewsFailure(debugMessage: error.toString()));
    }
  }
}
