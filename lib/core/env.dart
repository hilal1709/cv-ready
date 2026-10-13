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

  /// Any Gemini model id. A pinned Flash-Lite version is the default: on the
  /// free tier the "-latest" aliases are often overloaded (503) or hang, and
  /// short CV rewrites don't need a bigger model.
  static const geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.1-flash-lite');

  static bool get hasDatabase => dbHost.isNotEmpty && dbPassword.isNotEmpty;
  static bool get hasAi => anthropicKey.isNotEmpty || geminiKey.isNotEmpty;
}
