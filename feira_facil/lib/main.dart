import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: FeiraFacilApp(),
    ),
  );
}

class FeiraFacilApp extends ConsumerWidget {
  const FeiraFacilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appThemeMode = ref.watch(themeModeProvider);

    final flutterThemeMode = switch (appThemeMode) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.colorblind => ThemeMode.light,
    };

    final lightTheme = appThemeMode == AppThemeMode.colorblind 
        ? AppTheme.colorblindTheme 
        : AppTheme.lightTheme;

    return MaterialApp.router(
      title: 'Feira Fácil',
      theme: lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
