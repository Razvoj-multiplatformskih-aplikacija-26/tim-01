part of 'review_bloc.dart';

sealed class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => const [];
}

final class ReviewsRequested extends ReviewEvent {
  const ReviewsRequested();
}

final class ReviewSubmitted extends ReviewEvent {
  const ReviewSubmitted({
    required this.deviceId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.rating,
  });

  final DeviceId deviceId;
  final UserId authorId;
  final String title;
  final String body;
  final int rating;

  @override
  List<Object?> get props => [deviceId, authorId, title, body, rating];
}

final class ReviewReported extends ReviewEvent {
  const ReviewReported({required this.id, required this.reporterId});

  final ReviewId id;
  final UserId reporterId;

  @override
  List<Object?> get props => [id, reporterId];
}

final class ReviewApproved extends ReviewEvent {
  const ReviewApproved(this.id);

  final ReviewId id;

  @override
  List<Object?> get props => [id];
}

final class ReviewRejectedByEditor extends ReviewEvent {
  const ReviewRejectedByEditor({required this.id, required this.reason});

  final ReviewId id;
  final String reason;

  @override
  List<Object?> get props => [id, reason];
}

final class ReviewRepublished extends ReviewEvent {
  const ReviewRepublished(this.id);

  final ReviewId id;

  @override
  List<Object?> get props => [id];
}

final class ReviewArchivedByEditor extends ReviewEvent {
  const ReviewArchivedByEditor(this.id);

  final ReviewId id;

  @override
  List<Object?> get props => [id];
}

final class ReviewFailureDemoRequested extends ReviewEvent {
  const ReviewFailureDemoRequested();
}
