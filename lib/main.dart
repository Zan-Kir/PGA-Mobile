import 'package:flutter/material.dart';
import 'dart:async';
import 'src/services/app_init.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'src/services/auth_provider.dart';
import 'src/theme/app_theme.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/dashboard_screen.dart';
import 'src/screens/projects_screen.dart';
import 'src/screens/create_project_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/widgets/splash_widget.dart';

const BACKEND_BASE = 'http://192.168.50.54:3000';
const String APP_LOGO_ASSET = 'assets/icons/app_icon.png';

// ensure splash shows at least this duration
final ValueNotifier<bool> minSplashDone = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider(baseUrl: BACKEND_BASE);
  await auth.loadFromStorage();

  runApp(ChangeNotifierProvider.value(
    value: auth,
    child: const MyApp(),
  ));

  // start minimum splash timer (20s) after app starts
  Future.delayed(const Duration(seconds: 20)).then((_) {
    minSplashDone.value = true;
  });

  () async {
    try {
      await AppInit().initialize(BACKEND_BASE);
    } catch (e) {
      debugPrint('AppInit failed: $e');
    }
  }();
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return ValueListenableBuilder<bool>(
      valueListenable: minSplashDone,
      builder: (context, minDone, _) {
        final showSplash = auth.isLoading || !minDone;
        if (showSplash) {
          return MaterialApp(
            title: 'PGA 2025 - Fatec Votorantim',
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SplashWidget(
                logoAsset: APP_LOGO_ASSET,
                backgroundAsset: 'assets/images/votorantim_inaugura-1047641.png',
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        } else {
          final router = GoRouter(
            initialLocation: '/',
            redirect: (context, state) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final loggedIn = auth.isAuthenticated;
              final loggingIn = state.uri.path == '/';
              if (!loggedIn && !loggingIn) return '/';
              if (loggedIn && loggingIn) return '/dashboard';
              return null;
            },
            routes: [
              GoRoute(
                path: '/',
                name: 'login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
              GoRoute(
                path: '/projects',
                name: 'projects',
                builder: (context, state) => const ProjectsScreen(),
              ),
              GoRoute(
                path: '/create-project',
                name: 'create-project',
                builder: (context, state) => const CreateProjectScreen(),
              ),
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          );

          return MaterialApp.router(
            title: 'PGA 2025 - Fatec Votorantim',
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        }
      },
    );
}
}