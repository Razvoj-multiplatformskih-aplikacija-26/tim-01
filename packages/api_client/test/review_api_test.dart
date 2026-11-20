import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('older client retains the validation limit from the server rejection', () async {
    final transport = MockClient((request) async {
      expect(request.url.path, '/api/reviews');
      expect(request.body, isNot(contains('authorId')));
      expect(request.body, contains('Dobar'));
      return http.Response('{"code":"review_title_too_short","details":{"length":5,"minimum":8}}', 422);
    });
    final api = ReviewApi(Uri.parse('http://localhost:8080'), clientName: 'mobile', transport: transport);
    addTearDown(api.close);
    final repository = HttpReviewRepository(api);
    final review = createPendingReview(
      id: const ReviewId('local-id'),
      deviceId: const DeviceId('airwrap-id'),
      authorId: const UserId('local-author'),
      title: 'Dobar',
      body: 'Ovaj tekst je dovoljno dug da bi prošao validaciju recenzije.',
      rating: 5,
      submittedAt: DateTime.utc(2026, 11, 16),
    ).valueOrNull!;

    final result = await repository.addReview(review);

    expect(result.errorOrNull, const ReviewTitleTooShort(length: 5, minimum: 8));
  });

  test('expired server session notifies the app and becomes a domain error', () async {
    final api = ReviewApi(
      Uri.parse('http://localhost:8080'),
      clientName: 'web',
      transport: MockClient((request) async {
        expect(request.url.queryParameters['scope'], 'staff');
        return http.Response('{"code":"session_expired","details":{}}', 401);
      }),
    );
    addTearDown(api.close);
    var expired = false;
    api.onSessionExpired = () => expired = true;

    await expectLater(HttpReviewRepository(api).loadReviews(), throwsA(const SessionExpired()));
    expect(expired, isTrue);
  });
}
