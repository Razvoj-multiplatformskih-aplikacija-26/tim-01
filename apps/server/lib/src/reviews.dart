import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Result;

import 'sessions.dart';

final class ReviewsStore {
  const ReviewsStore(this.pool, this.now);

  final Pool<void> pool;
  final Clock now;

  Future<void> checkDatabase() async {
    await pool.execute('SELECT 1');
  }

  Future<ReviewPage> list({
    required SessionUser? viewer,
    required int limit,
    required int offset,
    required String? status,
    required String query,
  }) async {
    final where = <String>[];
    final parameters = <String, Object?>{'limit': limit + 1, 'offset': offset};
    // Domain policy selects the scope. PostgreSQL filters before paginating.
    switch (reviewVisibility(viewer?.role)) {
      case ReviewVisibility.published:
        where.add("r.status = 'published'");
      case ReviewVisibility.publishedAndOwn:
        where.add("(r.status = 'published' OR r.author_id = @viewer)");
        parameters['viewer'] = viewer!.id.value;
      case ReviewVisibility.all:
        break;
    }
    if (status != null) {
      where.add('r.status = @status');
      parameters['status'] = status;
    }
    if (query.isNotEmpty) {
      where.add('''
(strpos(lower(r.title), lower(@query)) > 0
 OR strpos(lower(r.body), lower(@query)) > 0
 OR strpos(lower(r.device_id), lower(@query)) > 0)''');
      parameters['query'] = query;
    }
    final rows = await pool.execute(
      Sql.named('''
SELECT r.*,
  CASE WHEN r.status = 'hidden' THEN
    (SELECT count(*) FROM review_reports rr WHERE rr.review_id = r.id)
  END AS report_count
FROM reviews r
${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
ORDER BY r.submitted_at DESC, r.id DESC
LIMIT @limit OFFSET @offset'''),
      parameters: parameters,
    );
    return ReviewPage(
      rows.take(limit).map((row) {
        final review = _fromRow(row.toColumnMap());
        return reviewToDto(
          review,
          includeModeration: canModerateReviews(viewer?.role) || viewer?.id == review.authorId,
        );
      }).toList(),
      rows.length > limit ? offset + limit : null,
    );
  }

  Future<Result<Review>> create(SessionUser actor, DeviceId device, ReviewInput input) async {
    if (!canSubmitReview(actor.role)) return const Failure(ForbiddenReviewAction());
    final result = reviewCreationFromDto(
      input,
      id: ReviewId(randomId()),
      deviceId: device,
      authorId: actor.id,
      submittedAt: now(),
    );
    if (result case Success<Review>(:final value)) {
      await pool.execute(
        Sql.named('''
INSERT INTO reviews (id, device_id, author_id, title, body, rating, status, submitted_at, status_at)
VALUES (@id, @device, @author, @title, @body, @rating, @status, @submitted, @statusAt)'''),
        parameters: {
          'id': value.id.value,
          'device': value.deviceId.value,
          'author': value.authorId.value,
          'title': value.title.value,
          'body': value.body.value,
          'rating': value.rating.value,
          'status': statusName(value.status),
          'submitted': value.submittedAt,
          'statusAt': statusTime(value.status),
        },
      );
    }
    return result;
  }

  Future<Result<Review>> edit(SessionUser actor, ReviewId id, ReviewInput input) =>
      _modify(id, (review) => reviewEditFromDto(review, input, actorId: actor.id, role: actor.role));

  Future<Result<Review>> report(SessionUser actor, ReviewId id) async {
    if (!canReportReviews(actor.role)) return const Failure(ForbiddenReviewAction());
    return _modify(
      id,
      (review) => registerReviewReport(review, reporterId: actor.id, now: now()),
      reportedBy: actor.id,
    );
  }

  Future<Result<Review>> moderate(SessionUser actor, ReviewId id, ModerationRequest request) async {
    if (!canModerateReviews(actor.role)) return const Failure(ForbiddenReviewAction());
    final next = moderationFromDto(request, now());
    return _modify(id, (review) => applyReviewStatus(review, next));
  }

  Future<Result<Review>> _modify(ReviewId id, Result<Review> Function(Review) change, {UserId? reportedBy}) =>
      pool.runTx((tx) async {
        // All review writes lock the same row before reading status and reports.
        // Competing requests wait, then check the freshly committed data.
        final rows = await tx.execute(
          Sql.named('SELECT * FROM reviews WHERE id = @id FOR UPDATE'),
          parameters: {'id': id.value},
        );
        if (rows.isEmpty) return const Failure(ReviewNotFound());

        final reports = await tx.execute(
          Sql.named('SELECT reporter_id FROM review_reports WHERE review_id = @id'),
          parameters: {'id': id.value},
        );
        final review = _fromRow(rows.single.toColumnMap(), {for (final row in reports) UserId(row[0]! as String)});
        final result = change(review);
        if (result case Success<Review>(:final value)) {
          if (reportedBy != null) {
            final inserted = await tx.execute(
              Sql.named('''
INSERT INTO review_reports (review_id, reporter_id) VALUES (@id, @reporter)
ON CONFLICT (review_id, reporter_id) DO NOTHING RETURNING reporter_id'''),
              parameters: {'id': id.value, 'reporter': reportedBy.value},
            );
            if (inserted.isEmpty) return const Failure(ReviewAlreadyReported());
          }
          await tx.execute(
            Sql.named('''
UPDATE reviews
SET title = @title, body = @body, rating = @rating,
    status = @status, status_at = @statusAt, rejection_reason = @reason
WHERE id = @id'''),
            parameters: {
              'id': id.value,
              'title': value.title.value,
              'body': value.body.value,
              'rating': value.rating.value,
              'status': statusName(value.status),
              'statusAt': statusTime(value.status),
              'reason': switch (value.status) {
                ReviewRejected(:final reason) => reason,
                _ => null,
              },
            },
          );
        }
        return result;
      });

  Review _fromRow(Map<String, Object?> row, [Set<UserId>? reporters]) => Review(
    id: ReviewId(row['id']! as String),
    deviceId: DeviceId(row['device_id']! as String),
    authorId: UserId(row['author_id']! as String),
    title: ReviewTitle.fromStored(row['title']! as String),
    body: ReviewBody.fromStored(row['body']! as String),
    rating: RatingValue.fromStored(row['rating']! as int),
    status: statusFromWire(
      row['status']! as String,
      row['status_at']! as DateTime,
      reason: row['rejection_reason'] as String?,
      uniqueReportCount: reporters?.length ?? row['report_count'] as int?,
    ),
    submittedAt: row['submitted_at']! as DateTime,
    reportedBy: reporters ?? const {},
  );
}
