import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'src/transport.dart' if (dart.library.js_interop) 'src/transport_web.dart';

abstract interface class SessionTokenStore {
  Future<String?> read();
  Future<void> save(String token);
  Future<void> clear();
}

final class PlatformSessionTokenStore implements SessionTokenStore {
  const PlatformSessionTokenStore(this.key);

  final String key;
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: key);

  @override
  Future<void> save(String token) => _storage.write(key: key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: key);
}

class ReviewSessionGate extends StatefulWidget {
  const ReviewSessionGate({
    required this.mobile,
    required this.apiBaseUrl,
    required this.theme,
    required this.builder,
    this.transport,
    this.tokenStore,
    super.key,
  });

  final bool mobile;
  final String apiBaseUrl;
  final ThemeData theme;
  final Widget Function(HttpReviewRepository repository, ReviewViewer viewer) builder;

  /// Owned by this gate and closed when the gate is disposed.
  final http.Client? transport;

  /// Native token storage; browser sessions use an HttpOnly cookie.
  final SessionTokenStore? tokenStore;

  @override
  State<ReviewSessionGate> createState() => _ReviewSessionGateState();
}

class _ReviewSessionGateState extends State<ReviewSessionGate> {
  late final ReviewApi _api;
  late final HttpReviewRepository _repository;
  late final SessionTokenStore? _tokens;
  final _email = TextEditingController();
  final _password = TextEditingController();
  SessionResponse? _session;
  Timer? _expiry;
  var _working = true;
  var _guest = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final name = widget.mobile ? 'mobile' : (kIsWeb ? 'web' : 'backoffice');
    _api = ReviewApi(
      Uri.parse(widget.apiBaseUrl),
      clientName: name,
      transport: widget.transport ?? platformHttpClient(),
    )..onSessionExpired = _expireSession;
    const delay = int.fromEnvironment('KT2_DEMO_DELAY_MS');
    const empty = bool.fromEnvironment('KT2_DEMO_EMPTY');
    _repository = HttpReviewRepository(
      _api,
      demoDelay: const Duration(milliseconds: delay),
      demoQuery: empty ? 'kt2-demo-empty-8cf2ad7f' : null,
    );
    _tokens = kIsWeb ? null : widget.tokenStore ?? PlatformSessionTokenStore('device-guide-$name-session');
    unawaited(_restore());
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _api.close();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      _api.bearerToken = await _tokens?.read();
      if (kIsWeb || _api.bearerToken != null) {
        final session = await _api.restoreSession();
        if (_acceptsRole(session)) {
          _setSession(session);
        } else {
          await _clearToken();
          if (mounted) _message = _wrongRoleMessage;
        }
      }
    } on ApiProblem catch (problem) {
      if (problem.domainError is SessionExpired) {
        final hadToken = _api.bearerToken != null || hadBrowserSession();
        await _clearToken();
        if (hadToken && mounted) _message = 'Prijava je istekla. Prijavite se ponovo.';
      } else if (mounted) {
        _message = _messageFor(problem);
      }
    } on Object {
      if (mounted) _message = 'Prijava nije mogla da se učita.';
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _setSession(SessionResponse session) {
    if (!mounted) return;
    _expiry?.cancel();
    rememberBrowserSession(true);
    _expiry = Timer(session.expiresAt.difference(DateTime.now()), _expireSession);
    setState(() {
      _session = session;
      _guest = false;
      _message = null;
    });
  }

  Future<bool> _clearToken() async {
    _api.bearerToken = null;
    rememberBrowserSession(false);
    try {
      await _tokens?.clear();
      return true;
    } on Object {
      // The in-memory credential is already removed and the server enforces expiry.
      return false;
    }
  }

  void _expireSession() {
    if (!mounted || _session == null) return;
    _expiry?.cancel();
    unawaited(_clearToken());
    setState(() {
      _session = null;
      _guest = false;
      _message = 'Prijava je istekla. Prijavite se ponovo.';
    });
  }

  Future<void> _login() async {
    if (_working) return;
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _message = 'Unesite e-adresu i lozinku.');
      return;
    }
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final session = await _api.login(email, _password.text);
      if (!_acceptsRole(session)) {
        if (mounted) _message = _wrongRoleMessage;
        return;
      }
      final token = session.token;
      if (!kIsWeb && token == null) throw const FormatException('Missing session token');
      if (token != null) {
        _api.bearerToken = token;
        await _tokens?.save(token);
      }
      if (!mounted) return;
      _password.clear();
      _setSession(session);
    } on ApiProblem catch (problem) {
      if (mounted) _message = _messageFor(problem);
    } on Object {
      await _clearToken();
      if (mounted) _message = 'Prijava nije mogla da se sačuva.';
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _logout() async {
    String? warning;
    try {
      await _api.logout();
    } on Object catch (error) {
      final alreadyExpired = error is ApiProblem && error.domainError is SessionExpired;
      if (!alreadyExpired) {
        // Only a server response can clear the browser's HttpOnly cookie.
        if (kIsWeb) rethrow;
        warning = 'Odjavljeni ste sa ovog uređaja. Server nije potvrdio odjavu jer zahtev nije uspeo.';
      }
    }
    final token = _api.bearerToken;
    final tokenCleared = await _clearToken();
    if (warning != null && !tokenCleared) {
      _api.bearerToken = token;
      throw StateError('Neither server revocation nor local token removal succeeded');
    }
    _expiry?.cancel();
    if (!mounted) return;
    setState(() {
      _session = null;
      _guest = false;
      _message = warning;
    });
  }

  bool _acceptsRole(SessionResponse session) {
    try {
      final role = sessionViewerFromDto(session).role;
      return widget.mobile ? canSubmitReview(role) : canModerateReviews(role);
    } on ArgumentError {
      return false;
    }
  }

  String get _wrongRoleMessage =>
      widget.mobile ? 'Prijavite se korisničkim nalogom za mobilnu aplikaciju.' : 'Backoffice je namenjen urednicima.';

  String _messageFor(ApiProblem problem) => switch (problem.error.code) {
    'invalid_credentials' => 'E-adresa ili lozinka nisu ispravne.',
    'wrong_client_role' => _wrongRoleMessage,
    'session_expired' => 'Prijava je istekla. Prijavite se ponovo.',
    'server_unavailable' => 'Server nije dostupan. Pokušajte ponovo.',
    _ => 'Prijava trenutno nije moguća. Pokušajte ponovo.',
  };

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session != null || _guest) {
      return _SessionControls(
        signedIn: session != null,
        onLogin: () => setState(() => _guest = false),
        onLogout: _logout,
        child: widget.builder(_repository, session == null ? const ReviewViewer() : sessionViewerFromDto(session)),
      );
    }

    return MaterialApp(
      title: widget.mobile ? 'Vodič za uređaje' : 'Vodič za uređaje Backoffice',
      debugShowCheckedModeBanner: false,
      theme: widget.theme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.mobile ? 'Vodič za uređaje' : 'Moderacija recenzija',
                        style: widget.theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _email,
                        enabled: !_working,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'E-adresa'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        enabled: !_working,
                        autofillHints: null,
                        obscureText: true,
                        onSubmitted: (_) => unawaited(_login()),
                        decoration: const InputDecoration(labelText: 'Lozinka'),
                      ),
                      if (_message case final message?) ...[
                        const SizedBox(height: 12),
                        Semantics(liveRegion: true, child: Text(message)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(onPressed: _working ? null : _login, child: const Text('Prijavi se')),
                      if (widget.mobile)
                        TextButton(
                          onPressed: !_working ? () => setState(() => _guest = true) : null,
                          child: const Text('Nastavi bez prijave'),
                        ),
                      if (_working) const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionControls extends InheritedWidget {
  const _SessionControls({required this.signedIn, required this.onLogin, required this.onLogout, required super.child});

  final bool signedIn;
  final VoidCallback onLogin;
  final Future<void> Function() onLogout;

  @override
  bool updateShouldNotify(_SessionControls oldWidget) => signedIn != oldWidget.signedIn;
}

class SessionMenuButton extends StatelessWidget {
  const SessionMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controls = context.dependOnInheritedWidgetOfExactType<_SessionControls>();
    if (controls == null) return const SizedBox.shrink();
    if (!controls.signedIn) {
      return IconButton(onPressed: controls.onLogin, tooltip: 'Prijavi se', icon: const Icon(Icons.login));
    }
    return IconButton(
      onPressed: () async {
        try {
          await controls.onLogout();
        } on Object {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Odjava nije uspela. Pokušajte ponovo.')));
          }
        }
      },
      tooltip: 'Odjavi se',
      icon: const Icon(Icons.logout),
    );
  }
}
