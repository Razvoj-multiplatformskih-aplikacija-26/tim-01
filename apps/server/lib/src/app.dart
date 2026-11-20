import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

import 'reviews.dart';
import 'sessions.dart';

const _sessionCookie = 'device_guide_session';
final _sessionTokenPattern = RegExp(r'^[a-zA-Z0-9_-]{32}$');

Handler buildHandler({
  required ReviewsStore reviews,
  required SessionsStore sessions,
  required String webOrigin,
  required bool secureCookie,
}) {
  final routes = _Routes(reviews, sessions, secureCookie);
  final router = RelicRouter()
    ..get('/health', routes.health)
    ..post('/api/session', routes.login)
    ..get('/api/session', routes.currentSession)
    ..delete('/api/session', routes.logout)
    ..get('/api/reviews', routes.listReviews)
    ..post('/api/reviews', routes.createReview)
    ..patch('/api/reviews/:id', routes.editReview)
    ..post('/api/reviews/:id/report', routes.reportReview)
    ..post('/api/reviews/:id/moderation', routes.moderateReview)
    ..fallback = respondWith((_) => _problem(404, 'route_not_found'));

  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_allowOrigin(webOrigin))
      .addMiddleware(_handleErrors)
      .addHandler(router.asHandler);
}

final class _Routes {
  const _Routes(this.reviews, this.sessions, this.secureCookie);

  final ReviewsStore reviews;
  final SessionsStore sessions;
  final bool secureCookie;

  Future<Response> health(Request request) async {
    await reviews.checkDatabase();
    return _json(200, {'status': 'ok'});
  }

  Future<Response> login(Request request) async {
    final input = await _read(request, LoginRequest.fromJson);
    if (!{'mobile', 'backoffice', 'web'}.contains(input.client)) {
      return _problem(400, 'invalid_request');
    }
    if (input.email.length > 254 || input.password.length > 1024) {
      return _problem(400, 'invalid_request');
    }
    final user = await sessions.checkCredentials(input.email, input.password);
    if (user == null) return _problem(401, 'invalid_credentials');

    final correctRole = input.client == 'mobile' ? canSubmitReview(user.role) : canModerateReviews(user.role);
    if (!correctRole) return _problem(403, 'wrong_client_role');

    final (session, token) = await sessions.issue(user);
    final wantsCookie = input.client == 'web';
    return _json(
      201,
      session.toResponse(token: wantsCookie ? null : token).toJson(),
      cookie: wantsCookie ? _cookie(token, sessions.ttl.inSeconds) : null,
    );
  }

  Future<Response> currentSession(Request request) async {
    final session = await _findSession(request, required: true);
    return _json(200, session!.toResponse().toJson());
  }

  Future<Response> logout(Request request) async {
    final token = _presentedToken(request);
    if (token != null && _sessionTokenPattern.hasMatch(token)) await sessions.revoke(token);
    return Response.noContent(headers: Headers.build((headers) => headers['set-cookie'] = [_cookie('', 0)]));
  }

  Future<Response> listReviews(Request request) async {
    final query = request.url.queryParameters;
    final staffView = query['scope'] == 'staff';
    final session = await _findSession(request, required: staffView);
    final viewer = session?.user;
    if (staffView && !canModerateReviews(viewer?.role)) return _domainProblem(const ForbiddenReviewAction());
    final filter = query['status'];
    final search = (query['query'] ?? '').trim();
    if ((filter != null && !reviewStatusNames.contains(filter)) || search.length > 200) {
      return _problem(400, 'invalid_request');
    }

    final page = await reviews.list(
      viewer: viewer,
      limit: _queryInt(query['limit'], defaultValue: 25, min: 1, max: 100),
      offset: _queryInt(query['offset'], defaultValue: 0, min: 0, max: 2147483647),
      status: filter,
      query: search,
    );
    return _json(200, page.toJson());
  }

  Future<Response> createReview(Request request) async {
    final actor = (await _findSession(request, required: true))!.user;
    final (input, deviceId) = await _read(request, (json) {
      final input = ReviewInput.fromJson(json);
      return (input, reviewCreationDeviceFromDto(input));
    });
    return _mutationResponse(await reviews.create(actor, deviceId, input), actor, successCode: 201);
  }

  Future<Response> editReview(Request request) async {
    final actor = (await _findSession(request, required: true))!.user;
    final input = await _read(request, ReviewInput.fromJson);
    return _mutationResponse(await reviews.edit(actor, _id(request), input), actor);
  }

  Future<Response> reportReview(Request request) async {
    final actor = (await _findSession(request, required: true))!.user;
    return _mutationResponse(await reviews.report(actor, _id(request)), actor);
  }

  Future<Response> moderateReview(Request request) async {
    final actor = (await _findSession(request, required: true))!.user;
    if (!canModerateReviews(actor.role)) return _domainProblem(const ForbiddenReviewAction());
    final input = await _read(request, ModerationRequest.fromJson);
    try {
      return _mutationResponse(await reviews.moderate(actor, _id(request), input), actor);
    } on FormatException {
      return _problem(400, 'invalid_request');
    }
  }

  Future<ActiveSession?> _findSession(Request request, {required bool required}) async {
    final token = _presentedToken(request);
    if (token == null && !required) return null;
    if (token == null || !_sessionTokenPattern.hasMatch(token)) throw const _SessionMissing();
    final session = await sessions.find(token);
    if (session == null) throw const _SessionMissing();
    return session;
  }

  String _cookie(String token, int maxAge) =>
      '$_sessionCookie=$token; Path=/api; HttpOnly; SameSite=Lax; Max-Age=$maxAge${secureCookie ? '; Secure' : ''}';
}

Response _mutationResponse(Result<Review> result, SessionUser actor, {int successCode = 200}) => switch (result) {
  Success(:final value) => _json(
    successCode,
    reviewToJson(value, includeModeration: canModerateReviews(actor.role) || actor.id == value.authorId),
  ),
  Failure(:final error) => _domainProblem(error),
};

ReviewId _id(Request request) => ReviewId(request.pathParameters.raw[#id]!);

Future<T> _read<T>(Request request, T Function(Json) fromJson) async {
  try {
    final decoded = jsonDecode(await request.readAsString(maxLength: 16 * 1024));
    if (decoded is! Json) throw const _InvalidRequest();
    return fromJson(decoded);
  } on FormatException {
    throw const _InvalidRequest();
  } on TypeError {
    throw const _InvalidRequest();
  }
}

int _queryInt(String? value, {required int defaultValue, required int min, required int max}) {
  if (value == null) return defaultValue;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < min || parsed > max) throw const _InvalidRequest();
  return parsed;
}

String? _presentedToken(Request request) {
  final authorization = _header(request, 'authorization');
  if (authorization != null) return authorization.startsWith('Bearer ') ? authorization.substring(7) : '';
  for (final value in request.headers['cookie'] ?? const <String>[]) {
    for (final part in value.split(';')) {
      final cookie = part.trim();
      if (cookie.startsWith('$_sessionCookie=')) return cookie.substring(_sessionCookie.length + 1);
    }
  }
  return null;
}

String? _header(Request request, String name) => request.headers[name]?.firstOrNull;

Middleware _allowOrigin(String webOrigin) =>
    (next) => (request) async {
      final origin = _header(request, 'origin');
      if (origin != null && origin != webOrigin) return _problem(403, 'origin_not_allowed');
      final preflight = request.method == Method.options && origin != null;
      final result = preflight ? Response.noContent() : await next(request);
      if (result is! Response || origin == null) return result;
      return result.copyWith(
        headers: result.headers.transform((headers) {
          headers['access-control-allow-origin'] = [webOrigin];
          headers['access-control-allow-credentials'] = ['true'];
          headers['vary'] = ['Origin'];
          if (preflight) {
            headers['access-control-allow-methods'] = ['GET, POST, PATCH, DELETE, OPTIONS'];
            headers['access-control-allow-headers'] = ['Content-Type, Authorization'];
          }
        }),
      );
    };

Handler _handleErrors(Handler next) => (request) async {
  try {
    return await next(request);
  } on _InvalidRequest {
    return _problem(400, 'invalid_request');
  } on _SessionMissing {
    return _domainProblem(const SessionExpired());
  } on MaxBodySizeExceeded {
    return _problem(413, 'invalid_request');
  } on Exception catch (error, stackTrace) {
    stderr.writeln('Request failed (${error.runtimeType})\n$stackTrace');
    return _domainProblem(const ServerUnavailable());
  } on Object catch (error, stackTrace) {
    stderr.writeln('Unexpected error (${error.runtimeType})\n$stackTrace');
    return _domainProblem(const UnknownServerError());
  }
};

Response _domainProblem(DomainError error) {
  final code = switch (error) {
    SessionExpired() => 401,
    ForbiddenReviewAction() || CannotReportOwnReview() => 403,
    ReviewNotFound() => 404,
    InvalidReviewTransition() || ReviewAlreadyReported() || ReviewActionNotAllowed() => 409,
    ServerUnavailable() => 503,
    UnknownServerError() => 500,
    _ => 422,
  };
  return _json(code, errorToJson(error));
}

Response _problem(int status, String code) => _json(status, ApiError(code).toJson());

Response _json(int status, Json json, {String? cookie}) => Response(
  status,
  body: Body.fromString(jsonEncode(json), mimeType: MimeType.json),
  headers: Headers.build((headers) {
    headers['cache-control'] = ['no-store'];
    if (cookie != null) headers['set-cookie'] = [cookie];
  }),
);

final class _InvalidRequest implements Exception {
  const _InvalidRequest();
}

final class _SessionMissing implements Exception {
  const _SessionMissing();
}
