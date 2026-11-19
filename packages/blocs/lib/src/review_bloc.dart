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
    on<ReviewEdited>(_onReviewEdited);
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

  bool get canSimulateFailure => _failureController != null;

  bool get canEditReviews => _repository is ReviewEditingRepository;

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
    await _runMutation(() => _repository.addReview(review.valueOrNull!), ReviewAction.submitted, emit);
  }

  Future<void> _onReviewEdited(ReviewEdited event, Emitter<ReviewState> emit) async {
    final repository = _repository;
    if (repository is! ReviewEditingRepository) {
      _emitActionError(emit, const ReviewActionNotAllowed());
      return;
    }
    final editor = repository as ReviewEditingRepository;
    await _runMutation(
      () => editor.editReview(id: event.id, title: event.title, body: event.body, rating: event.rating),
      ReviewAction.edited,
      emit,
    );
  }

  Future<void> _onReviewReported(ReviewReported event, Emitter<ReviewState> emit) async {
    await _runMutation(
      () => _repository.reportReview(id: event.id, reporterId: event.reporterId, now: _clock()),
      ReviewAction.reported,
      emit,
    );
  }

  Future<void> _onReviewApproved(ReviewApproved event, Emitter<ReviewState> emit) async {
    await _runMutation(
      () => _repository.changeReviewStatus(
        id: event.id,
        status: ReviewPublished(publishedAt: _clock().toUtc()),
      ),
      ReviewAction.approved,
      emit,
    );
  }

  Future<void> _onReviewRejected(ReviewRejectedByEditor event, Emitter<ReviewState> emit) async {
    await _runMutation(
      () => _repository.changeReviewStatus(
        id: event.id,
        status: ReviewRejected(rejectedAt: _clock().toUtc(), reason: event.reason),
      ),
      ReviewAction.rejected,
      emit,
    );
  }

  Future<void> _onReviewRepublished(ReviewRepublished event, Emitter<ReviewState> emit) async {
    await _runMutation(
      () => _repository.changeReviewStatus(
        id: event.id,
        status: ReviewPublished(publishedAt: _clock().toUtc()),
      ),
      ReviewAction.republished,
      emit,
    );
  }

  Future<void> _onReviewArchived(ReviewArchivedByEditor event, Emitter<ReviewState> emit) async {
    await _runMutation(
      () => _repository.changeReviewStatus(
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

  Future<void> _runMutation(
    Future<Result<Review>> Function() operation,
    ReviewAction action,
    Emitter<ReviewState> emit,
  ) async {
    final Result<Review> result;
    try {
      result = await operation();
    } on DomainError catch (error) {
      await _recoverFromActionError(emit, error);
      return;
    } on Object {
      _emitActionError(emit, const ServerUnavailable());
      return;
    }
    if (result case Failure<Review>(:final error)) {
      await _recoverFromActionError(emit, error);
      return;
    }
    await _load(emit, lastAction: action);
  }

  Future<void> _recoverFromActionError(Emitter<ReviewState> emit, DomainError error) async {
    if (error is SessionExpired || error is ServerUnavailable || error is UnknownServerError) {
      _emitActionError(emit, error);
      return;
    }
    await _load(emit, actionError: error);
  }

  void _emitActionError(Emitter<ReviewState> emit, DomainError error) {
    final current = state;
    if (current is ReviewsReady) {
      emit(current.copyWith(actionError: error, clearLastAction: true, revision: ++_revision));
      return;
    }
    emit(ReviewActionFailure(error: error, revision: ++_revision));
  }

  Future<void> _load(Emitter<ReviewState> emit, {ReviewAction? lastAction, DomainError? actionError}) async {
    emit(const ReviewsLoading());
    try {
      final reviews = await _repository.loadReviews();
      if (reviews.isEmpty) {
        emit(ReviewsEmpty(lastAction: lastAction, actionError: actionError));
      } else {
        emit(ReviewsReady(reviews: reviews, lastAction: lastAction, actionError: actionError, revision: ++_revision));
      }
    } on Object catch (error) {
      emit(
        ReviewsFailure(
          debugMessage: error.toString(),
          loadError: error is DomainError ? error : null,
          lastAction: lastAction,
          actionError: actionError,
        ),
      );
    }
  }
}
