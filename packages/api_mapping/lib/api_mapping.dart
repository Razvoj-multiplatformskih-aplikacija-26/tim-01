import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

const reviewStatusNames = {'pending', 'published', 'hidden', 'rejected', 'archived'};

SessionResponse sessionToDto({
  required UserId userId,
  required String email,
  required UserRole role,
  required DateTime expiresAt,
  String? token,
}) => SessionResponse(id: userId.value, email: email, role: role.name, expiresAt: expiresAt, token: token);

ReviewViewer sessionViewerFromDto(SessionResponse dto) =>
    ReviewViewer(id: UserId(dto.id), role: UserRole.values.byName(dto.role));

ReviewInput reviewCreationToDto(Review review) => ReviewInput(
  deviceId: review.deviceId.value,
  title: review.title.value,
  body: review.body.value,
  rating: review.rating.value,
);

ReviewInput reviewEditToDto({required String title, required String body, required int rating}) =>
    ReviewInput(title: title, body: body, rating: rating);

DeviceId reviewCreationDeviceFromDto(ReviewInput dto) {
  final id = dto.deviceId?.trim();
  if (id == null || id.isEmpty || id.length > 100) throw const FormatException('Invalid device identifier');
  return DeviceId(id);
}

Result<Review> reviewCreationFromDto(
  ReviewInput dto, {
  required ReviewId id,
  required DeviceId deviceId,
  required UserId authorId,
  required DateTime submittedAt,
}) => createPendingReview(
  id: id,
  deviceId: deviceId,
  authorId: authorId,
  title: dto.title,
  body: dto.body,
  rating: dto.rating,
  submittedAt: submittedAt,
);

Result<Review> reviewEditFromDto(Review review, ReviewInput dto, {required UserId actorId, required UserRole role}) =>
    editPendingReview(review, actorId: actorId, role: role, title: dto.title, body: dto.body, rating: dto.rating);

ModerationRequest? moderationToDto(ReviewStatus status) => switch (status) {
  ReviewPublished() => const ModerationRequest('approve'),
  ReviewRejected(:final reason) => ModerationRequest('reject', reason: reason),
  ReviewArchived() => const ModerationRequest('archive'),
  _ => null,
};

ReviewStatus moderationFromDto(ModerationRequest dto, DateTime at) {
  final reason = dto.reason?.trim();
  return switch (dto.action) {
    'approve' || 'republish' => ReviewPublished(publishedAt: at),
    'reject' when reason != null && reason.isNotEmpty => ReviewRejected(rejectedAt: at, reason: reason),
    'archive' => ReviewArchived(archivedAt: at),
    _ => throw const FormatException('Invalid moderation request'),
  };
}

String statusName(ReviewStatus status) => switch (status) {
  ReviewPending() => 'pending',
  ReviewPublished() => 'published',
  ReviewHidden() => 'hidden',
  ReviewRejected() => 'rejected',
  ReviewArchived() => 'archived',
};

DateTime statusTime(ReviewStatus status) => switch (status) {
  ReviewPending(:final submittedAt) => submittedAt,
  ReviewPublished(:final publishedAt) => publishedAt,
  ReviewHidden(:final hiddenAt) => hiddenAt,
  ReviewRejected(:final rejectedAt) => rejectedAt,
  ReviewArchived(:final archivedAt) => archivedAt,
};

ReviewStatus statusFromWire(String status, DateTime time, {String? reason, int? uniqueReportCount}) => switch (status) {
  'pending' => ReviewPending(submittedAt: time),
  'published' => ReviewPublished(publishedAt: time),
  'hidden' => ReviewHidden(hiddenAt: time, uniqueReportCount: uniqueReportCount ?? 0),
  'rejected' => ReviewRejected(rejectedAt: time, reason: reason ?? ''),
  'archived' => ReviewArchived(archivedAt: time),
  _ => throw const FormatException('Unknown review status'),
};

ReviewDto reviewToDto(Review review, {bool includeModeration = true}) => ReviewDto(
  id: review.id.value,
  deviceId: review.deviceId.value,
  authorId: review.authorId.value,
  title: review.title.value,
  body: review.body.value,
  rating: review.rating.value,
  status: statusName(review.status),
  submittedAt: review.submittedAt,
  statusAt: statusTime(review.status),
  reason: switch (review.status) {
    ReviewRejected(:final reason) when includeModeration => reason,
    _ => null,
  },
  uniqueReportCount: switch (review.status) {
    ReviewHidden(:final uniqueReportCount) => uniqueReportCount,
    _ => null,
  },
);

Json reviewToJson(Review review, {bool includeModeration = true}) =>
    reviewToDto(review, includeModeration: includeModeration).toJson();

Review reviewFromDto(ReviewDto dto) => Review(
  id: ReviewId(dto.id),
  deviceId: DeviceId(dto.deviceId),
  authorId: UserId(dto.authorId),
  title: ReviewTitle.fromStored(dto.title),
  body: ReviewBody.fromStored(dto.body),
  rating: RatingValue.fromStored(dto.rating),
  status: statusFromWire(dto.status, dto.statusAt, reason: dto.reason, uniqueReportCount: dto.uniqueReportCount),
  submittedAt: dto.submittedAt,
);

Review reviewFromJson(Json json) => reviewFromDto(ReviewDto.fromJson(json));

Json errorToJson(DomainError error) => (switch (error) {
  ReviewTitleTooShort(:final length, :final minimum) => ApiError('review_title_too_short', {
    'length': length,
    'minimum': minimum,
  }),
  ReviewTitleTooLong(:final length, :final maximum) => ApiError('review_title_too_long', {
    'length': length,
    'maximum': maximum,
  }),
  ReviewBodyTooShort(:final length, :final minimum) => ApiError('review_body_too_short', {
    'length': length,
    'minimum': minimum,
  }),
  ReviewBodyTooLong(:final length, :final maximum) => ApiError('review_body_too_long', {
    'length': length,
    'maximum': maximum,
  }),
  RatingOutOfRange(:final value, :final minimum, :final maximum) => ApiError('rating_out_of_range', {
    'value': value,
    'minimum': minimum,
    'maximum': maximum,
  }),
  InvalidReviewTransition(:final from, :final to) => ApiError('invalid_review_transition', {
    'from': statusName(from),
    'to': statusName(to),
  }),
  ReviewAlreadyReported() => const ApiError('review_already_reported'),
  CannotReportOwnReview() => const ApiError('cannot_report_own_review'),
  ReviewActionNotAllowed() => const ApiError('review_action_not_allowed'),
  ReviewNotFound() => const ApiError('review_not_found'),
  ForbiddenReviewAction() => const ApiError('forbidden_review_action'),
  SessionExpired() => const ApiError('session_expired'),
  ServerUnavailable() => const ApiError('server_unavailable'),
  UnknownServerError() => const ApiError('unknown_server_error'),
}).toJson();

DomainError errorFromJson(Json json) {
  try {
    final error = ApiError.fromJson(json);
    final details = error.details;
    final placeholderTime = DateTime.utc(1970);
    return switch (error.code) {
      'review_title_too_short' => ReviewTitleTooShort(
        length: details['length'] as int,
        minimum: details['minimum'] as int,
      ),
      'review_title_too_long' => ReviewTitleTooLong(
        length: details['length'] as int,
        maximum: details['maximum'] as int,
      ),
      'review_body_too_short' => ReviewBodyTooShort(
        length: details['length'] as int,
        minimum: details['minimum'] as int,
      ),
      'review_body_too_long' => ReviewBodyTooLong(length: details['length'] as int, maximum: details['maximum'] as int),
      'rating_out_of_range' => RatingOutOfRange(
        details['value'] as int,
        minimum: (details['minimum'] as int?) ?? 1,
        maximum: (details['maximum'] as int?) ?? 5,
      ),
      'invalid_review_transition' => InvalidReviewTransition(
        from: statusFromWire(details['from'] as String, placeholderTime),
        to: statusFromWire(details['to'] as String, placeholderTime),
      ),
      'review_already_reported' => const ReviewAlreadyReported(),
      'cannot_report_own_review' => const CannotReportOwnReview(),
      'review_action_not_allowed' => const ReviewActionNotAllowed(),
      'review_not_found' => const ReviewNotFound(),
      'forbidden_review_action' => const ForbiddenReviewAction(),
      'session_expired' => const SessionExpired(),
      'server_unavailable' => const ServerUnavailable(),
      _ => const UnknownServerError(),
    };
  } on Object {
    return const UnknownServerError();
  }
}
