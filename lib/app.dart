import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_flavor.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/l10n/strings.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/household/providers/household_provider.dart';
import 'features/household/screens/home_screen.dart';
import 'features/collector/providers/collector_provider.dart';
import 'features/collector/screens/map_screen.dart';

class BinLinkApp extends StatelessWidget {
  const BinLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isCollector = FlavorConfig.isCollector;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) {
          final tp = ThemeProvider();
          tp.load();
          return tp;
        }),
        ChangeNotifierProvider(create: (_) {
          final sp = AppStringsProvider();
          sp.load();
          return sp;
        }),
        // Only instantiate the provider relevant to this flavor —
        // prevents household and collector state from cross-contaminating
        if (!isCollector)
          ChangeNotifierProvider(create: (_) => HouseholdProvider()),
        if (isCollector)
          ChangeNotifierProvider(create: (_) => CollectorProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) => MaterialApp(
          title: FlavorConfig.appName,
          debugShowCheckedModeBanner: false,
          // Household → steelBlue theme | Collector → amber/driver theme
          theme: isCollector ? AppTheme.collectorLight : AppTheme.light,
          darkTheme: isCollector ? AppTheme.collectorDark : AppTheme.dark,
          themeMode: themeProv.themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash':          (_) => const SplashScreen(),
            '/onboarding':      (_) => const OnboardingScreen(),
            '/login':           (_) => const LoginScreen(),
            '/register':        (_) => const RegisterScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/household':       (_) => const HouseholdHomeScreen(),
            '/collector':       (_) => const CollectorMapScreen(),
          },
        ),
      ),
    );
  }
}
