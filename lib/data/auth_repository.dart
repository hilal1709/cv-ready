import 'api_client.dart';
import 'models.dart';

/// Accounts live on the backend; passwords are hashed there, never on the phone.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AppUser> _enter(String path, Map<String, dynamic> body) async {
    final j = await _api.request('POST', path, body: body);
    await _api.setToken(j['token'] as String);
    return AppUser.fromJson(j['user'] as Map<String, dynamic>);
  }

  Future<AppUser> register({required String fullName, required String email, required String password}) =>
      _enter('/auth/register', {'fullName': fullName.trim(), 'email': email.trim(), 'password': password});

  Future<AppUser> login({required String email, required String password}) =>
      _enter('/auth/login', {'email': email.trim(), 'password': password});

  Future<void> updateName(String fullName) => _api.request('PATCH', '/me', body: {'fullName': fullName.trim()});

  Future<void> signOut() => _api.setToken(null);
}
