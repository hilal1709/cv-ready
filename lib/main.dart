import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/theme/app_theme.dart';
import 'data/auth_repository.dart';
import 'data/api_client.dart';
import 'data/resume_repository.dart';
import 'services/ai_service.dart';
import 'state/resume_store.dart';
import 'state/session.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final session = Session(AuthRepository(ApiClient.instance));
  await session.restore();
  // An expired or revoked token drops the user back to the sign-in screen.
  ApiClient.instance.onUnauthorized = () => session.logout();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => ResumeStore(ResumeRepository(ApiClient.instance))),
        Provider(create: (_) => AiService()),
      ],
      child: const CvReadyApp(),
    ),
  );
}

class CvReadyApp extends StatelessWidget {
  const CvReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      theme: AppTheme.shad(Brightness.light),
      darkTheme: AppTheme.shad(Brightness.dark),
      themeMode: ThemeMode.system,
      appBuilder: (context) => MaterialApp(
        title: 'CV Ready',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.material(Brightness.light),
        darkTheme: AppTheme.material(Brightness.dark),
        themeMode: ThemeMode.system,
        builder: (context, child) => ShadAppBuilder(child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}
