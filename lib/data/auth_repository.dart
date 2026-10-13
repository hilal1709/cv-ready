import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

import 'db.dart';
import 'models.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// PBKDF2-HMAC-SHA256. Runs in a background isolate so the UI keeps animating.
Uint8List _pbkdf2(({String password, Uint8List salt, int iterations}) a) {
  final hmac = Hmac(sha256, utf8.encode(a.password));
  final block = Uint8List.fromList([...a.salt, 0, 0, 0, 1]);
  var u = Uint8List.fromList(hmac.convert(block).bytes);
  final out = Uint8List.fromList(u);
  for (var i = 1; i < a.iterations; i++) {
    u = Uint8List.fromList(hmac.convert(u).bytes);
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}

class AuthRepository {
  AuthRepository(this._db);
  final Db _db;
  static const _iterations = 60000;

  Future<String> _hash(String password, Uint8List salt) async {
    final bytes = await compute(_pbkdf2, (password: password, salt: salt, iterations: _iterations));
    return base64Encode(bytes);
  }

  Future<AppUser> register({required String fullName, required String email, required String password}) async {
    final normalized = email.trim().toLowerCase();
    final exists = await _db.query('SELECT 1 FROM app_users WHERE email = @e', {'e': normalized});
    if (exists.isNotEmpty) throw AuthException('Email ini sudah terdaftar. Coba masuk.');
    final rnd = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
    final hash = await _hash(password, salt);
    final r = await _db.query(
      'INSERT INTO app_users (email, full_name, password_hash, password_salt) '
      'VALUES (@e, @n, @h, @s) RETURNING id::text, email, full_name',
      {'e': normalized, 'n': fullName.trim(), 'h': hash, 's': base64Encode(salt)},
    );
    final row = r.first;
    return AppUser(id: row[0] as String, email: row[1] as String, fullName: row[2] as String);
  }

  Future<AppUser> login({required String email, required String password}) async {
    final r = await _db.query(
      'SELECT id::text, email, full_name, password_hash, password_salt FROM app_users WHERE email = @e',
      {'e': email.trim().toLowerCase()},
    );
    if (r.isEmpty) throw AuthException('Email atau kata sandi salah.');
    final row = r.first;
    final hash = await _hash(password, base64Decode(row[4] as String));
    if (hash != row[3]) throw AuthException('Email atau kata sandi salah.');
    return AppUser(id: row[0] as String, email: row[1] as String, fullName: row[2] as String);
  }

  Future<void> updateName(String userId, String fullName) => _db.query(
    'UPDATE app_users SET full_name = @n WHERE id = @id',
    {'n': fullName.trim(), 'id': TypedValue(Type.uuid, userId)},
  );
}
