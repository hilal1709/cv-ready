/// Build-time configuration, injected with
/// `flutter run --dart-define-from-file=.env.json`.
/// Nothing here is committed to source control.
class Env {
  static const dbHost = String.fromEnvironment('DB_HOST');
  static const dbName = String.fromEnvironment('DB_NAME', defaultValue: 'neondb');
  static const dbUser = String.fromEnvironment('DB_USER');
  static const dbPassword = String.fromEnvironment('DB_PASSWORD');
  static const anthropicKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const geminiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Any Gemini model id; the "-latest" alias follows Google's current Flash model.
  static const geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-flash-latest');

  static bool get hasDatabase => dbHost.isNotEmpty && dbPassword.isNotEmpty;
  static bool get hasAi => anthropicKey.isNotEmpty || geminiKey.isNotEmpty;
}
