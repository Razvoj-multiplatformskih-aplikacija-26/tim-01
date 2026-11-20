import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';

Future<void> main(List<String> arguments) async {
  final api = _Api(Uri.parse(arguments.isEmpty ? 'http://localhost:8080' : arguments.single));
  try {
    await _runChecks(api);
    stdout.writeln('KT2 API smoke checks passed');
  } finally {
    api.close();
  }
}

Future<void> _runChecks(_Api api) async {
  final healthy = await api.request('GET', '/health');
  _expect(healthy.status == 200, 'database health');

  final wrongRole = await api.request(
    'POST',
    '/api/session',
    json: const LoginRequest(email: 'mobile1@example.test', password: 'MobileDemo123!', client: 'backoffice').toJson(),
  );
  _expectError(wrongRole, 403, 'wrong_client_role');

  final sessions = [
    for (var i = 1; i <= 5; i++)
      await api.login(LoginRequest(email: 'mobile$i@example.test', password: 'MobileDemo123!', client: 'mobile')),
    await api.login(const LoginRequest(email: 'editor@example.test', password: 'EditorDemo123!', client: 'backoffice')),
  ];
  final editor = sessions.last;
  final owner = sessions[0];
  final other = sessions[1];

  final uniqueTitle = 'KT2 demo ${DateTime.now().toUtc().millisecondsSinceEpoch}';
  const body = 'Detaljan opis iskustva sa uređajem, dodat samo za KT2 proveru.';
  final badTitle = await api.request(
    'POST',
    '/api/reviews',
    token: owner.token,
    json: const ReviewInput(deviceId: 'airwrap-id', title: 'ab', body: body, rating: 4).toJson(),
  );
  _expectError(badTitle, 422, 'review_title_too_short');
  _expect(ApiError.fromJson(badTitle.json).details['minimum'] is int, 'shared validation error has a numeric limit');

  final creation = await api.request(
    'POST',
    '/api/reviews',
    token: owner.token,
    json: ReviewInput(deviceId: 'airwrap-id', title: uniqueTitle, body: body, rating: 4).toJson(),
  );
  _expect(creation.status == 201, 'create review');
  final pending = ReviewDto.fromJson(creation.json);
  _expect(pending.status == 'pending' && pending.authorId == owner.id, 'new review uses authenticated author');
  final reviewPath = '/api/reviews/${pending.id}';
  final staffList = await api.request('GET', '/api/reviews?scope=staff&limit=1', token: editor.token);
  _expect(staffList.status == 200, 'editor lists reviews');
  final list = ReviewPage.fromJson(staffList.json);
  _expect(
    list.reviews.length == 1 && list.reviews.single.id == pending.id && list.nextOffset == 1,
    'server visibility, order and paging',
  );
  await _expectVisible(api, uniqueTitle, expected: false);
  await _expectVisible(api, uniqueTitle, token: other.token, expected: false);
  await _expectVisible(api, uniqueTitle, token: owner.token, expected: true);

  final edit = ReviewInput(title: '$uniqueTitle edited', body: body, rating: 5).toJson();
  final foreignEdit = await api.request('PATCH', reviewPath, token: other.token, json: edit);
  _expectError(foreignEdit, 403, 'forbidden_review_action');
  final ownEdit = await api.request('PATCH', reviewPath, token: owner.token, json: edit);
  _expect(ownEdit.status == 200, 'author can edit own pending review');
  final edited = ReviewDto.fromJson(ownEdit.json);
  _expect(
    edited.id == pending.id && edited.rating == 5 && edited.status == 'pending',
    'edit preserves identity and status',
  );

  final moderationPath = '$reviewPath/moderation';
  for (final action in [
    const ModerationRequest('approve'),
    const ModerationRequest('reject', reason: 'Tekst ne opisuje uređaj.'),
  ]) {
    final forbidden = await api.request('POST', moderationPath, token: other.token, json: action.toJson());
    _expectError(forbidden, 403, 'forbidden_review_action');
  }
  final approved = await api.request(
    'POST',
    moderationPath,
    token: editor.token,
    json: const ModerationRequest('approve').toJson(),
  );
  _expect(approved.status == 200 && ReviewDto.fromJson(approved.json).status == 'published', 'editor approves');
  await _expectVisible(api, uniqueTitle, expected: true);

  final reportPath = '$reviewPath/report';
  final ownReport = await api.request('POST', reportPath, token: owner.token);
  _expectError(ownReport, 403, 'cannot_report_own_review');

  final first = await api.request('POST', reportPath, token: other.token);
  _expect(first.status == 200 && ReviewDto.fromJson(first.json).status == 'published', 'first report');
  final duplicate = await api.request('POST', reportPath, token: other.token);
  _expectError(duplicate, 409, 'review_already_reported');
  final second = await api.request('POST', reportPath, token: sessions[2].token);
  _expect(second.status == 200 && ReviewDto.fromJson(second.json).status == 'published', 'second report');

  final both = await Future.wait([
    api.request('POST', reportPath, token: sessions[3].token),
    api.request('POST', reportPath, token: sessions[4].token),
  ]);
  final accepted = both.where((entry) => entry.status == 200).toList();
  final rejected = both.where((entry) => entry.status == 409).toList();
  _expect(accepted.length == 1 && rejected.length == 1, 'exactly one concurrent final report succeeds');
  _expectError(rejected.single, 409, 'review_action_not_allowed');
  final hidden = ReviewDto.fromJson(accepted.single.json);
  _expect(hidden.status == 'hidden' && hidden.uniqueReportCount == 3, 'stale reporter cannot add a fourth report');
  await _expectVisible(api, uniqueTitle, expected: false);
  await _expectVisible(api, uniqueTitle, token: owner.token, expected: true);
  await _expectVisible(api, uniqueTitle, token: editor.token, expected: true);

  final archived = await api.request(
    'POST',
    moderationPath,
    token: editor.token,
    json: const ModerationRequest('archive').toJson(),
  );
  _expect(
    archived.status == 200 && ReviewDto.fromJson(archived.json).status == 'archived',
    'editor archives smoke-created review',
  );

  final staleApprove = await api.request(
    'POST',
    moderationPath,
    token: editor.token,
    json: const ModerationRequest('approve').toJson(),
  );
  _expectError(staleApprove, 409, 'invalid_review_transition');

  await _checkBrowserSession(api);
}

Future<void> _expectVisible(_Api api, String query, {required bool expected, String? token}) async {
  final encoded = Uri.encodeQueryComponent(query);
  final response = await api.request('GET', '/api/reviews?query=$encoded', token: token);
  _expect(response.status == 200, 'list filtered by search');
  _expect(ReviewPage.fromJson(response.json).reviews.isNotEmpty == expected, 'visibility of smoke review');
}

Future<void> _checkBrowserSession(_Api api) async {
  const origin = 'http://localhost:8081';
  final preflight = await api.request(
    'OPTIONS',
    '/api/session',
    headers: {
      'Origin': origin,
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'content-type',
    },
  );
  _expect(
    preflight.status == 204 && preflight.corsOrigin == origin && preflight.corsCredentials == 'true',
    'credentialed browser preflight',
  );
  final login = await api.request(
    'POST',
    '/api/session',
    headers: {'Origin': origin},
    json: const LoginRequest(email: 'editor@example.test', password: 'EditorDemo123!', client: 'web').toJson(),
  );
  _expect(login.status == 201, 'web editor logs in');
  _expect(SessionResponse.fromJson(login.json).token == null, 'web token delivered only via cookie');
  final setCookie = login.setCookie;
  _expect(
    setCookie != null && setCookie.contains('HttpOnly') && setCookie.contains('Max-Age='),
    'persistent HttpOnly cookie',
  );
  final headers = {'Origin': origin, 'Cookie': setCookie!.split(';').first};
  final resumed = await api.request('GET', '/api/session', headers: headers);
  _expect(resumed.status == 200 && SessionResponse.fromJson(resumed.json).role == 'editor', 'resume browser session');
  final logout = await api.request('DELETE', '/api/session', headers: headers);
  _expect(logout.status == 204 && logout.setCookie?.contains('Max-Age=0') == true, 'web logout deletes cookie');
  _expectError(await api.request('GET', '/api/session', headers: headers), 401, 'session_expired');
}

void _expectError(_Response response, int status, String code) {
  _expect(response.status == status, '$code has HTTP $status, got ${response.status}');
  _expect(ApiError.fromJson(response.json).code == code, 'stable API error $code');
}

void _expect(bool condition, String expectation) {
  if (!condition) throw StateError('KT2 smoke check failed: $expectation');
}

final class _Api {
  _Api(this.baseUrl);

  final Uri baseUrl;
  final HttpClient _client = HttpClient();

  void close() => _client.close(force: true);

  Future<SessionResponse> login(LoginRequest login) async {
    final response = await request('POST', '/api/session', json: login.toJson());
    _expect(response.status == 201, 'demo account ${login.email} can sign in');
    final session = SessionResponse.fromJson(response.json);
    _expect(session.token?.isNotEmpty == true, 'native token issued');
    return session;
  }

  Future<_Response> request(
    String method,
    String path, {
    Json? json,
    String? token,
    Map<String, String> headers = const {},
  }) async {
    final req = await _client.openUrl(method, baseUrl.resolve(path));
    headers.forEach(req.headers.set);
    if (token != null) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    if (json != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(json));
    }
    final response = await req.close().timeout(const Duration(seconds: 25));
    final text = await response.transform(utf8.decoder).join();
    return _Response(
      response.statusCode,
      text.isEmpty ? const {} : jsonDecode(text) as Json,
      response.headers.value(HttpHeaders.setCookieHeader),
      response.headers.value('access-control-allow-origin'),
      response.headers.value('access-control-allow-credentials'),
    );
  }
}

final class _Response {
  const _Response(this.status, this.json, this.setCookie, this.corsOrigin, this.corsCredentials);

  final int status;
  final Json json;
  final String? setCookie;
  final String? corsOrigin;
  final String? corsCredentials;
}
