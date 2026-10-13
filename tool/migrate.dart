// Creates/updates the CV Ready schema on Neon.
// Run: dart run tool/migrate.dart
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> main() async {
  final env = jsonDecode(File('.env.json').readAsStringSync()) as Map;
  final conn = await Connection.open(
    Endpoint(host: env['DB_HOST'], database: env['DB_NAME'], username: env['DB_USER'], password: env['DB_PASSWORD']),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  await conn.execute('CREATE EXTENSION IF NOT EXISTS pgcrypto');
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS app_users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email TEXT NOT NULL UNIQUE,
      full_name TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      password_salt TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )''');
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS resumes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      template TEXT NOT NULL DEFAULT 'harvard',
      data JSONB NOT NULL DEFAULT '{}'::jsonb,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )''');
  await conn.execute('CREATE INDEX IF NOT EXISTS resumes_user_updated_idx ON resumes (user_id, updated_at DESC)');

  final r = await conn.execute(
    "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY 1",
  );
  stdout.writeln('Tables: ${r.map((row) => row[0]).join(', ')}');
  await conn.close();
}
