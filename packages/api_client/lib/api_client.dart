import 'dart:async';
import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;

export 'package:api_contract/api_contract.dart' show SessionResponse;

final class ApiProblem implements Exception {
  const ApiProblem(this.error);

  final ApiError error;

  DomainError get domainError => errorFromJson(error.toJson());
}

final class ReviewApi {
  ReviewApi(this.baseUri, {required this.clientName, http.Client? transport, this.timeout = const Duration(seconds: 6)})
    : _transport = transport ?? http.Client();

  final Uri baseUri;
  final String clientName;
  final Duration timeout;
  final http.Client _transport;
  String? bearerToken;
  void Function()? onSessionExpired;

  Future<SessionResponse> login(String email, String password) async {
    final json = await _send(
      'POST',
      '/api/session',
      body: LoginRequest(email: email, password: password, client: clientName).toJson(),
      notifyExpiry: false,
      requestTimeout: const Duration(seconds: 20),
    );
    return SessionResponse.fromJson(json);
  }

  Future<SessionResponse> restoreSession() async {
    final json = await _send('GET', '/api/session', notifyExpiry: false);
    return SessionResponse.fromJson(json);
  }

  Future<void> logout() async {
    await _send('DELETE', '/api/session', notifyExpiry: false);
  }

  Future<ReviewPage> listReviews({required int offset, int limit = 50, String? query}) async {
    final json = await _send(
      'GET',
      '/api/reviews',
      query: {'offset': '$offset', 'limit': '$limit', if (clientName != 'mobile') 'scope': 'staff', 'query': ?query},
    );
    return ReviewPage.fromJson(json);
  }

  Future<Review> createReview(ReviewInput input) async =>
      reviewFromJson(await _send('POST', '/api/reviews', body: input.toJson()));

  Future<Review> editReview(String id, ReviewInput input) async =>
      reviewFromJson(await _send('PATCH', '/api/reviews/${Uri.encodeComponent(id)}', body: input.toJson()));

  Future<Review> reportReview(String id) async =>
      reviewFromJson(await _send('POST', '/api/reviews/${Uri.encodeComponent(id)}/report', body: const {}));

  Future<Review> moderateReview(String id, ModerationRequest request) async =>
      reviewFromJson(await _send('POST', '/api/reviews/${Uri.encodeComponent(id)}/moderation', body: request.toJson()));

  void close() => _transport.close();

  Future<Json> _send(
    String method,
    String path, {
    Json? body,
    Map<String, String>? query,
    bool notifyExpiry = true,
    Duration? requestTimeout,
  }) async {
    final requestUri = baseUri.resolve(path).replace(queryParameters: query);
    final request = http.Request(method, requestUri);
    request.headers['Accept'] = 'application/json';
    final token = bearerToken;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await _transport.send(request).then(http.Response.fromStream).timeout(requestTimeout ?? timeout);
    } on TimeoutException {
      throw const ApiProblem(ApiError('server_unavailable'));
    } on http.ClientException {
      throw const ApiProblem(ApiError('server_unavailable'));
    }

    if (response.statusCode == 204) return {};
    final Json payload;
    try {
      payload = jsonDecode(utf8.decode(response.bodyBytes)) as Json;
    } on Object {
      throw const ApiProblem(ApiError('unknown_server_error'));
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return payload;
    final error = ApiError.fromJson(payload);
    if (notifyExpiry && error.code == 'session_expired') onSessionExpired?.call();
    throw ApiProblem(error);
  }
}

final class HttpReviewRepository implements ReviewRepository, ReviewEditingRepository {
  const HttpReviewRepository(this.api, {this.demoDelay = Duration.zero, this.demoQuery});

  final ReviewApi api;
  final Duration demoDelay;
  final String? demoQuery;

  @override
  Future<List<Review>> loadReviews() async {
    try {
      if (demoDelay > Duration.zero) await Future<void>.delayed(demoDelay);
      final reviews = <Review>[];
      var offset = 0;
      for (;;) {
        final page = await api.listReviews(offset: offset, query: demoQuery);
        reviews.addAll(page.reviews.map(reviewFromDto));
        final next = page.nextOffset;
        if (next == null) return List.unmodifiable(reviews);
        if (next <= offset) throw const UnknownServerError();
        offset = next;
      }
    } on ApiProblem catch (problem) {
      throw problem.domainError;
    }
  }

  @override
  Future<Result<Review>> addReview(Review review) => _mutation(() => api.createReview(reviewCreationToDto(review)));

  @override
  Future<Result<Review>> editReview({
    required ReviewId id,
    required String title,
    required String body,
    required int rating,
  }) => _mutation(() => api.editReview(id.value, reviewEditToDto(title: title, body: body, rating: rating)));

  @override
  Future<Result<Review>> reportReview({required ReviewId id, required UserId reporterId, required DateTime now}) =>
      _mutation(() => api.reportReview(id.value));

  @override
  Future<Result<Review>> changeReviewStatus({required ReviewId id, required ReviewStatus status}) {
    final request = moderationToDto(status);
    if (request == null) return Future.value(const Failure(ReviewActionNotAllowed()));
    return _mutation(() => api.moderateReview(id.value, request));
  }

  Future<Result<Review>> _mutation(Future<Review> Function() request) async {
    try {
      return Success(await request());
    } on ApiProblem catch (problem) {
      return Failure(problem.domainError);
    } on Object {
      return const Failure(UnknownServerError());
    }
  }
}
