import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'db.dart';
import 'models.dart';

class ResumeRepository {
  ResumeRepository(this._db);
  final Db _db;

  static const _cols = 'id::text, title, template, data, created_at, updated_at';

  Resume _row(ResultRow r) {
    final raw = r[3];
    final map = raw is Map ? Map<String, dynamic>.from(raw) : jsonDecode('$raw') as Map<String, dynamic>;
    return Resume(
      id: r[0] as String,
      title: r[1] as String,
      template: CvTemplate.byId(r[2] as String),
      data: ResumeData.fromJson(map),
      createdAt: (r[4] as DateTime).toLocal(),
      updatedAt: (r[5] as DateTime).toLocal(),
    );
  }

  TypedValue _uuid(String id) => TypedValue(Type.uuid, id);

  Future<List<Resume>> list(String userId) async {
    final r = await _db.query('SELECT $_cols FROM resumes WHERE user_id = @u ORDER BY updated_at DESC', {
      'u': _uuid(userId),
    });
    return r.map(_row).toList();
  }

  Future<Resume> create(String userId, {required String title, required CvTemplate template, ResumeData? data}) async {
    final r = await _db.query(
      'INSERT INTO resumes (user_id, title, template, data) VALUES (@u, @t, @tp, @d) RETURNING $_cols',
      {'u': _uuid(userId), 't': title, 'tp': template.id, 'd': TypedValue(Type.jsonb, (data ?? ResumeData()).toJson())},
    );
    return _row(r.first);
  }

  Future<DateTime> save(String userId, Resume resume) async {
    final r = await _db.query(
      'UPDATE resumes SET title = @t, template = @tp, data = @d, updated_at = now() '
      'WHERE id = @id AND user_id = @u RETURNING updated_at',
      {
        't': resume.title,
        'tp': resume.template.id,
        'd': TypedValue(Type.jsonb, resume.data.toJson()),
        'id': _uuid(resume.id),
        'u': _uuid(userId),
      },
    );
    if (r.isEmpty) throw DbException('CV ini tidak ditemukan. Mungkin sudah dihapus.');
    return (r.first[0] as DateTime).toLocal();
  }

  Future<Resume> duplicate(String userId, Resume source) =>
      create(userId, title: '${source.title} (salinan)', template: source.template, data: source.data.clone());

  Future<void> delete(String userId, String id) =>
      _db.query('DELETE FROM resumes WHERE id = @id AND user_id = @u', {'id': _uuid(id), 'u': _uuid(userId)});
}
