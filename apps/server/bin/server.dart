import 'dart:async';
import 'dart:io';

import 'package:device_guide_server/src/app.dart';
import 'package:device_guide_server/src/reviews.dart';
import 'package:device_guide_server/src/sessions.dart';
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';

Future<void> main() async {
  final config = Platform.environment;
  final port = int.parse(config['PORT'] ?? '8080');
  final sessionTtl = Duration(seconds: int.parse(config['SESSION_TTL_SECONDS'] ?? '28800'));
  if (sessionTtl <= Duration.zero) throw ArgumentError('SESSION_TTL_SECONDS must be positive');

  final pool = Pool<void>.withEndpoints([
    Endpoint(
      host: config['DB_HOST'] ?? 'localhost',
      port: int.parse(config['DB_PORT'] ?? '5432'),
      database: _required(config, 'POSTGRES_DB'),
      username: _required(config, 'POSTGRES_USER'),
      password: _required(config, 'POSTGRES_PASSWORD'),
    ),
  ], settings: const PoolSettings(sslMode: SslMode.disable, maxConnectionCount: 8));

  DateTime now() => DateTime.now().toUtc();
  final handler = buildHandler(
    reviews: ReviewsStore(pool, now),
    sessions: SessionsStore(pool, now, sessionTtl),
    webOrigin: config['BACKOFFICE_WEB_ORIGIN'] ?? 'http://localhost:8081',
    secureCookie: config['SESSION_COOKIE_SECURE'] == 'true',
  );
  final bindHost = InternetAddress(config['BIND_HOST'] ?? '0.0.0.0');
  final server = RelicServer(() => IOAdapter.bind(bindHost, port: port));
  await server.mountAndStart(handler);
  stdout.writeln('Device guide API listening on port $port');
  final shutdown = Completer<void>();
  final signals = [
    ProcessSignal.sigint.watch().listen((_) {
      if (!shutdown.isCompleted) shutdown.complete();
    }),
    if (!Platform.isWindows)
      ProcessSignal.sigterm.watch().listen((_) {
        if (!shutdown.isCompleted) shutdown.complete();
      }),
  ];
  await shutdown.future;
  for (final listener in signals) {
    await listener.cancel();
  }
  await server.close();
  await pool.close();
}

String _required(Map<String, String> config, String name) {
  final value = config[name];
  if (value == null || value.isEmpty) throw ArgumentError('Missing environment variable $name');
  return value;
}
