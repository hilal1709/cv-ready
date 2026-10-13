import 'api_client.dart';
import 'models.dart';

/// CV storage on the backend. The signed-in user comes from the token, so
/// the `userId` arguments are only there to keep callers unchanged.
class ResumeRepository {
  ResumeRepository(this._api);
  final ApiClient _api;

  Resume _row(Map<String, dynamic> j) => Resume(
    id: j['id'] as String,
    title: j['title'] as String,
    template: CvTemplate.byId(j['template'] as String),
    data: ResumeData.fromJson(Map<String, dynamic>.from(j['data'] as Map)),
    createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
    updatedAt: DateTime.parse(j['updatedAt'] as String).toLocal(),
  );

  Map<String, dynamic> _body(String title, CvTemplate template, ResumeData data) => {
    'title': title,
    'template': template.id,
    'data': data.toJson(),
  };

  Future<List<Resume>> list(String userId) async {
    final j = await _api.request('GET', '/resumes');
    return (j['resumes'] as List).map((e) => _row(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Resume> create(String userId, {required String title, required CvTemplate template, ResumeData? data}) async {
    final j = await _api.request('POST', '/resumes', body: _body(title, template, data ?? ResumeData()));
    return _row(Map<String, dynamic>.from(j['resume'] as Map));
  }

  Future<DateTime> save(String userId, Resume resume) async {
    final j = await _api.request(
      'PUT',
      '/resumes/${resume.id}',
      body: _body(resume.title, resume.template, resume.data),
    );
    return _row(Map<String, dynamic>.from(j['resume'] as Map)).updatedAt;
  }

  Future<Resume> duplicate(String userId, Resume source) =>
      create(userId, title: '${source.title} (salinan)', template: source.template, data: source.data.clone());

  Future<void> delete(String userId, String id) => _api.request('DELETE', '/resumes/$id');
}
