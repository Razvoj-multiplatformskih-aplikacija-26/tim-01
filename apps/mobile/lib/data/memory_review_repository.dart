import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

final class MemoryReviewRepository implements ReviewRepository, RequestFailureController {
  MemoryReviewRepository(Iterable<Review> seed, {this.latency = const Duration(milliseconds: 350)})
    : _reviews = List<Review>.of(seed);

  final Duration latency;
  final List<Review> _reviews;
  var _failNext = false;

  @override
  void failNextRequest() => _failNext = true;

  @override
  Future<List<Review>> loadReviews() async {
    await _waitAndMaybeFail();
    final sorted = List<Review>.of(_reviews)..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return List<Review>.unmodifiable(sorted);
  }

  @override
  Future<Result<Review>> addReview(Review review) async {
    await _waitAndMaybeFail();
    _reviews.insert(0, review);
    return Success(review);
  }

  @override
  Future<Result<Review>> reportReview({required ReviewId id, required UserId reporterId, required DateTime now}) async {
    await _waitAndMaybeFail();
    final index = _indexOf(id);
    if (index < 0) return const Failure(ReviewNotFound());
    final result = registerReviewReport(_reviews[index], reporterId: reporterId, now: now);
    final updated = result.valueOrNull;
    if (updated != null) _reviews[index] = updated;
    return result;
  }

  @override
  Future<Result<Review>> changeReviewStatus({required ReviewId id, required ReviewStatus status}) async {
    await _waitAndMaybeFail();
    final index = _indexOf(id);
    if (index < 0) return const Failure(ReviewNotFound());
    final result = applyReviewStatus(_reviews[index], status);
    final updated = result.valueOrNull;
    if (updated != null) _reviews[index] = updated;
    return result;
  }

  int _indexOf(ReviewId id) => _reviews.indexWhere((review) => review.id == id);

  Future<void> _waitAndMaybeFail() async {
    await Future<void>.delayed(latency);
    if (!_failNext) return;
    _failNext = false;
    throw StateError('Namerno izazvana greška sledećeg zahteva.');
  }
}
