/// Build-time configuration, injected with
/// `flutter run --dart-define-from-file=.env.json`.
///
/// Only the public address of the backend lives in the app. The database
/// password and the AI keys stay on the server (see `server/`), so an APK
/// that is shared around carries no secrets.
class Env {
  static const _apiUrl = String.fromEnvironment('API_URL');

  /// Backend base URL without a trailing slash, e.g. `https://cv-ready.onrender.com`.
  static String get apiUrl => _apiUrl.trim().replaceFirst(RegExp(r'/+$'), '');

  static bool get hasBackend => apiUrl.isNotEmpty;
}
