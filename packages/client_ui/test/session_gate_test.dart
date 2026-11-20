import 'dart:async';
import 'dart:convert';

import 'package:client_ui/client_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const token = 'stored-native-token';

  http.Response sessionResponse({String role = 'mobile'}) => http.Response(
    jsonEncode({
      'user': {'id': 'mobile-4', 'email': 'mobile4@example.test', 'role': role},
      'expiresAt': DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String(),
    }),
    200,
  );

  Widget gate(http.Client transport, SessionTokenStore tokens) => ReviewSessionGate(
    mobile: true,
    apiBaseUrl: 'http://localhost:8080',
    theme: ThemeData(),
    transport: transport,
    tokenStore: tokens,
    builder: (repository, viewer) => MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: const [SessionMenuButton()]),
        body: Text('Korisnik: ${viewer.id?.value}'),
      ),
    ),
  );

  testWidgets('restores a session and revokes it before completing logout', (tester) async {
    final tokens = _Tokens(token);
    final requests = <http.Request>[];
    final logout = Completer<http.Response>();
    final transport = MockClient((request) async {
      requests.add(request);
      expect(request.url.path, '/api/session');
      if (!kIsWeb) expect(request.headers['Authorization'], 'Bearer $token');
      if (request.method == 'GET') return sessionResponse();
      expect(request.method, 'DELETE');
      return logout.future;
    });

    await tester.pumpWidget(gate(transport, tokens));
    await tester.pumpAndSettle();
    expect(find.text('Korisnik: mobile-4'), findsOneWidget);

    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pump();
    expect(find.text('Korisnik: mobile-4'), findsOneWidget);
    if (!kIsWeb) expect(tokens.value, token);
    logout.complete(http.Response('', 204));
    await tester.pumpAndSettle();
    expect(requests.map((request) => request.method), ['GET', 'DELETE']);
    if (!kIsWeb) expect(tokens.value, isNull);
    expect(find.text('Prijavi se'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('native offline logout clears the saved token and does not restore it', (tester) async {
    final tokens = _Tokens(token);
    final transport = MockClient((request) async {
      if (request.method == 'GET') return sessionResponse();
      throw http.ClientException('server stopped');
    });

    await tester.pumpWidget(gate(transport, tokens));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();

    expect(tokens.value, isNull);
    expect(find.text('Prijavi se'), findsOneWidget);
    expect(find.textContaining('Server nije potvrdio odjavu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    final nextTransport = MockClient((request) async => throw StateError('No saved session should be restored'));
    await tester.pumpWidget(gate(nextTransport, tokens));
    await tester.pumpAndSettle();
    expect(find.text('Prijavi se'), findsOneWidget);
    expect(find.text('Korisnik: mobile-4'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: kIsWeb);

  testWidgets('failed server logout and token removal retain a retryable session', (tester) async {
    final tokens = _Tokens(token, failClear: true);
    var serverAvailable = false;
    final transport = MockClient((request) async {
      if (request.method == 'GET') return sessionResponse();
      expect(request.headers['Authorization'], 'Bearer $token');
      if (!serverAvailable) throw http.ClientException('server stopped');
      return http.Response('', 204);
    });

    await tester.pumpWidget(gate(transport, tokens));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();
    expect(tokens.value, token);
    expect(find.text('Korisnik: mobile-4'), findsOneWidget);
    expect(find.text('Odjava nije uspela. Pokušajte ponovo.'), findsOneWidget);

    serverAvailable = true;
    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();
    expect(find.text('Prijavi se'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: kIsWeb);

  testWidgets('web keeps the session when server logout cannot clear its cookie', (tester) async {
    final tokens = _Tokens(null);
    final transport = MockClient((request) async {
      if (request.method == 'GET') return sessionResponse();
      throw http.ClientException('server stopped');
    });

    await tester.pumpWidget(gate(transport, tokens));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();

    expect(find.text('Korisnik: mobile-4'), findsOneWidget);
    expect(find.text('Odjava nije uspela. Pokušajte ponovo.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !kIsWeb);

  testWidgets('an unknown server role is refused with a role message', (tester) async {
    final tokens = _Tokens(token);
    final transport = MockClient((request) async => sessionResponse(role: 'future-role'));

    await tester.pumpWidget(gate(transport, tokens));
    await tester.pumpAndSettle();
    expect(find.text('Prijavite se korisničkim nalogom za mobilnu aplikaciju.'), findsOneWidget);
    expect(find.text('Korisnik: mobile-4'), findsNothing);
    if (!kIsWeb) expect(tokens.value, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final class _Tokens implements SessionTokenStore {
  _Tokens(this.value, {this.failClear = false});

  String? value;
  final bool failClear;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> save(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Storage unavailable');
    value = null;
  }
}
