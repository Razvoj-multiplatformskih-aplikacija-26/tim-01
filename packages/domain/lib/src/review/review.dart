import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'review_status.dart';
import 'review_values.dart';

@immutable
final class Review {
  Review({
    required this.id,
    required this.deviceId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.rating,
    required this.status,
    required this.submittedAt,
    Set<UserId> reportedBy = const {},
  }) : reportedBy = Set<UserId>.unmodifiable(reportedBy);

  final ReviewId id;
  final DeviceId deviceId;
  final UserId authorId;
  final ReviewTitle title;
  final ReviewBody body;
  final RatingValue rating;
  final ReviewStatus status;
  final DateTime submittedAt;
  final Set<UserId> reportedBy;

  Review copyWith({ReviewStatus? status, Set<UserId>? reportedBy}) {
    return Review(
      id: id,
      deviceId: deviceId,
      authorId: authorId,
      title: title,
      body: body,
      rating: rating,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reportedBy: reportedBy ?? this.reportedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Review &&
      other.id == id &&
      other.deviceId == deviceId &&
      other.authorId == authorId &&
      other.title == title &&
      other.body == body &&
      other.rating == rating &&
      other.status == status &&
      other.submittedAt == submittedAt &&
      const SetEquality<UserId>().equals(other.reportedBy, reportedBy);

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    authorId,
    title,
    body,
    rating,
    status,
    submittedAt,
    const SetEquality<UserId>().hash(reportedBy),
  );
}
