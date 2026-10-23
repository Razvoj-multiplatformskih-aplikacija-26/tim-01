import 'package:meta/meta.dart';

sealed class ReviewStatus {
  const ReviewStatus();

  bool get isPublic => this is ReviewPublished;

  bool get isFinal => this is ReviewArchived;
}

@immutable
final class ReviewPending extends ReviewStatus {
  const ReviewPending({required this.submittedAt});

  final DateTime submittedAt;

  @override
  bool operator ==(Object other) => other is ReviewPending && other.submittedAt == submittedAt;

  @override
  int get hashCode => Object.hash(ReviewPending, submittedAt);
}

@immutable
final class ReviewPublished extends ReviewStatus {
  const ReviewPublished({required this.publishedAt});

  final DateTime publishedAt;

  @override
  bool operator ==(Object other) => other is ReviewPublished && other.publishedAt == publishedAt;

  @override
  int get hashCode => Object.hash(ReviewPublished, publishedAt);
}

@immutable
final class ReviewHidden extends ReviewStatus {
  const ReviewHidden({required this.hiddenAt, required this.uniqueReportCount});

  final DateTime hiddenAt;
  final int uniqueReportCount;

  @override
  bool operator ==(Object other) =>
      other is ReviewHidden && other.hiddenAt == hiddenAt && other.uniqueReportCount == uniqueReportCount;

  @override
  int get hashCode => Object.hash(ReviewHidden, hiddenAt, uniqueReportCount);
}

@immutable
final class ReviewRejected extends ReviewStatus {
  const ReviewRejected({required this.rejectedAt, required this.reason});

  final DateTime rejectedAt;
  final String reason;

  @override
  bool operator ==(Object other) => other is ReviewRejected && other.rejectedAt == rejectedAt && other.reason == reason;

  @override
  int get hashCode => Object.hash(ReviewRejected, rejectedAt, reason);
}

@immutable
final class ReviewArchived extends ReviewStatus {
  const ReviewArchived({required this.archivedAt});

  final DateTime archivedAt;

  @override
  bool operator ==(Object other) => other is ReviewArchived && other.archivedAt == archivedAt;

  @override
  int get hashCode => Object.hash(ReviewArchived, archivedAt);
}
