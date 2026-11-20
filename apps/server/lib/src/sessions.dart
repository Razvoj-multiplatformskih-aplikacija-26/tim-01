import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

typedef Clock = DateTime Function();

const _iterations = 600000;
const _dummyHash = r'pbkdf2-sha256$600000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
final _random = Random.secure();

String randomId() => base64Url.encode(List<int>.generate(24, (_) => _random.nextInt(256), growable: false));

String _tokenHash(String token) => crypto.sha256.convert(utf8.encode(token)).toString();

bool _equal(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var i = 0; i < left.length; i++) {
    difference |= left[i] ^ right[i];
  }
  return difference == 0;
}

Future<bool> verifyPassword(String password, String encoded) async {
  final parts = encoded.split(r'$');
  if (parts.length != 4 || parts.first != 'pbkdf2-sha256' || parts[1] != '600000') return false;
  final salt = base64Decode(parts[2]);
  final expected = base64Decode(parts[3]);
  if (salt.length != 16 || expected.length != 32) return false;
  final key = await Pbkdf2.hmacSha256(
    iterations: _iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);
  return _equal(await key.extractBytes(), expected);
}

final class SessionUser {
  const SessionUser(this.id, this.email, this.role);

  factory SessionUser.fromRow(Map<String, Object?> row) => SessionUser(
    UserId(row['id']! as String),
    row['email']! as String,
    UserRole.values.byName(row['role']! as String),
  );

  final UserId id;
  final String email;
  final UserRole role;
}

final class ActiveSession {
  const ActiveSession(this.user, this.expiresAt);

  final SessionUser user;
  final DateTime expiresAt;

  SessionResponse toResponse({String? token}) =>
      sessionToDto(userId: user.id, email: user.email, role: user.role, expiresAt: expiresAt, token: token);
}

final class SessionsStore {
  const SessionsStore(this.pool, this.now, this.ttl);

  final Pool<void> pool;
  final Clock now;
  final Duration ttl;

  Future<SessionUser?> checkCredentials(String email, String password) async {
    final rows = await pool.execute(
      Sql.named('SELECT id, email, role, password_hash FROM users WHERE email = @email'),
      parameters: {'email': email.trim().toLowerCase()},
    );
    final row = rows.isEmpty ? null : rows.single.toColumnMap();
    final encoded = (row?['password_hash'] as String?) ?? _dummyHash;
    final valid = await Isolate.run(() => verifyPassword(password, encoded));
    return valid && row != null ? SessionUser.fromRow(row) : null;
  }

  Future<(ActiveSession, String)> issue(SessionUser user) async {
    final token = randomId();
    final issuedAt = now();
    final expiresAt = issuedAt.add(ttl);
    await pool.runTx((tx) async {
      await tx.execute(Sql.named('DELETE FROM sessions WHERE expires_at <= @now'), parameters: {'now': issuedAt});
      await tx.execute(
        Sql.named('INSERT INTO sessions (token_hash, user_id, expires_at) VALUES (@token, @user, @expires)'),
        parameters: {'token': _tokenHash(token), 'user': user.id.value, 'expires': expiresAt},
      );
    });
    return (ActiveSession(user, expiresAt), token);
  }

  Future<ActiveSession?> find(String token) async {
    final rows = await pool.execute(
      Sql.named('''
SELECT users.id, users.email, users.role, sessions.expires_at
FROM sessions JOIN users ON users.id = sessions.user_id
WHERE sessions.token_hash = @token AND sessions.expires_at > @now'''),
      parameters: {'token': _tokenHash(token), 'now': now()},
    );
    if (rows.isEmpty) return null;
    final row = rows.single.toColumnMap();
    return ActiveSession(SessionUser.fromRow(row), row['expires_at']! as DateTime);
  }

  Future<void> revoke(String token) async {
    await pool.execute(
      Sql.named('DELETE FROM sessions WHERE token_hash = @token'),
      parameters: {'token': _tokenHash(token)},
    );
  }
}
