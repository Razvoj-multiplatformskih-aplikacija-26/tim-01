import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);

  Review seedReview() {
    return createPendingReview(
      id: const ReviewId('seed'),
      deviceId: const DeviceId('device-1'),
      authorId: const UserId('user-1'),
      title: 'Početna recenzija',
      body: 'Tekst početne recenzije ima dovoljno znakova za pravilo domena.',
      rating: 4,
      submittedAt: now,
    ).valueOrNull!;
  }

  ReviewBloc createBloc(_FakeRepository repository) {
    var next = 1;
    return ReviewBloc(
      repository: repository,
      failureController: repository,
      idGenerator: () => ReviewId('new-${next++}'),
      clock: () => now,
    );
  }

  test('loads data through loading and ready states', () async {
    final bloc = createBloc(_FakeRepository([seedReview()]));
    final states = bloc.stream.take(2).toList();

    bloc.add(const ReviewsRequested());

    expect(await states, [const ReviewsLoading(), isA<ReviewsReady>()]);
    await bloc.close();
  });

  test('failure demo exposes retry state', () async {
    final bloc = createBloc(_FakeRepository([seedReview()]));
    final states = bloc.stream.take(2).toList();

    bloc.add(const ReviewFailureDemoRequested());

    expect(await states, [const ReviewsLoading(), isA<ReviewsFailure>()]);
    await bloc.close();
  });

  test('submission creates a pending review and reloads the list', () async {
    final bloc = createBloc(_FakeRepository([seedReview()]));
    final states = bloc.stream.take(2).toList();

    bloc.add(
      const ReviewSubmitted(
        deviceId: DeviceId('device-2'),
        authorId: UserId('user-2'),
        title: 'Nova recenzija',
        body: 'Nova recenzija takođe ima dovoljno znakova da prođe pravilo domena.',
        rating: 5,
      ),
    );

    final emitted = await states;
    expect(emitted.first, const ReviewsLoading());
    expect((emitted.last as ReviewsReady).reviews, hasLength(2));
    await bloc.close();
  });
}

final class _FakeRepository implements ReviewRepository, RequestFailureController {
  _FakeRepository(Iterable<Review> seed) : reviews = List<Review>.of(seed);

  final List<Review> reviews;
  var fail = false;

  @override
  void failNextRequest() => fail = true;

  @override
  Future<List<Review>> loadReviews() async {
    if (fail) {
      fail = false;
      throw StateError('demo');
    }
    return List<Review>.unmodifiable(reviews);
  }

  @override
  Future<Result<Review>> addReview(Review review) async {
    reviews.add(review);
    return Success(review);
  }

  @override
  Future<Result<Review>> reportReview({required ReviewId id, required UserId reporterId, required DateTime now}) async {
    final index = reviews.indexWhere((review) => review.id == id);
    if (index < 0) return const Failure(ReviewNotFound());
    final result = registerReviewReport(reviews[index], reporterId: reporterId, now: now);
    final updated = result.valueOrNull;
    if (updated != null) reviews[index] = updated;
    return result;
  }

  @override
  Future<Result<Review>> changeReviewStatus({required ReviewId id, required ReviewStatus status}) async {
    final index = reviews.indexWhere((review) => review.id == id);
    if (index < 0) return const Failure(ReviewNotFound());
    final result = applyReviewStatus(reviews[index], status);
    final updated = result.valueOrNull;
    if (updated != null) reviews[index] = updated;
    return result;
  }
}
