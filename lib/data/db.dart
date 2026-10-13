import 'dart:async';

import 'package:postgres/postgres.dart';

import '../core/env.dart';

class DbException implements Exception {
  DbException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One lazily opened connection to Neon, reopened when it drops
/// (Neon closes idle connections, and phones change networks).
class Db {
  Db._();
  static final instance = Db._();

  Connection? _conn;
  Future<Connection>? _opening;

  Future<Connection> _connection() async {
    final c = _conn;
    if (c != null && c.isOpen) return c;
    return _opening ??= _open().whenComplete(() => _opening = null);
  }

  Future<Connection> _open() async {
    if (!Env.hasDatabase) {
      throw DbException('Database belum dikonfigurasi. Jalankan app dengan --dart-define-from-file=.env.json');
    }
    final conn = await Connection.open(
      Endpoint(host: Env.dbHost, database: Env.dbName, username: Env.dbUser, password: Env.dbPassword),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
        connectTimeout: Duration(seconds: 15),
        queryTimeout: Duration(seconds: 20),
      ),
    );
    _conn = conn;
    return conn;
  }

  /// Runs a named-parameter query, retrying once on a dropped connection.
  Future<Result> query(String sql, [Map<String, dynamic>? params]) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final conn = await _connection();
        return await conn.execute(Sql.named(sql), parameters: params);
      } on ServerException catch (e) {
        throw DbException(e.message);
      } on DbException {
        rethrow;
      } catch (e) {
        await _conn?.close().catchError((_) {});
        _conn = null;
        if (attempt == 1) {
          throw DbException('Tidak bisa terhubung ke server. Cek koneksi internet lalu coba lagi.');
        }
      }
    }
    throw DbException('Koneksi gagal.');
  }
}
