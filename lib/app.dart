import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_flavor.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/l10n/strings.dart';
import 'core/navigation/nav_service.dart';
import 'core/design_system/binlink_colors.dart';
import 'core/design_system/binlink_typography.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/household/providers/household_provider.dart';
import 'features/household/screens/home_screen.dart';
import 'features/household/screens/notifications_screen.dart';
import 'features/household/screens/help_screen.dart';
import 'features/household/screens/privacy_screen.dart';
import 'features/household/screens/edit_profile_screen.dart';
import 'features/household/screens/saved_addresses_screen.dart';
import 'features/household/screens/subscriptions_screen.dart';
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
        if (!isCollector)
          ChangeNotifierProvider(create: (_) => HouseholdProvider()),
        if (isCollector)
          ChangeNotifierProvider(create: (_) => CollectorProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) {
          return MaterialApp(
            navigatorKey: NavService.navigatorKey,
            title: FlavorConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: FlavorConfig.isCollector ? AppTheme.collector : AppTheme.light,
            darkTheme: FlavorConfig.isCollector ? AppTheme.collector : AppTheme.dark,
            themeMode: FlavorConfig.isCollector ? ThemeMode.dark : themeProv.themeMode,
            initialRoute: '/splash',
            routes: {
              '/splash':          (_) => const SplashScreen(),
              '/onboarding':      (_) => const OnboardingScreen(),
              '/login':           (_) => const LoginScreen(),
              '/register':        (_) => const RegisterScreen(),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/household':       (_) => const HouseholdHomeScreen(),
              '/collector':       (_) => const CollectorMapScreen(),
              '/notifications':   (_) => const NotificationsScreen(),
              '/help':            (_) => const HelpScreen(),
              '/privacy':         (_) => const PrivacyScreen(),
              '/edit-profile':    (_) => const EditProfileScreen(),
              '/saved-addresses': (_) => const SavedAddressesScreen(),
              '/subscriptions':   (_) => const SubscriptionsScreen(),
            },
          );
        },
      ),
    );
  }
}

// ── Context Extensions for easier BDOS access ────────────────────────────────

extension BinLinkThemeX on BuildContext {
  BinLinkColors get binlinkColors => Theme.of(this).extension<BinLinkColors>()!;
  BinLinkTypography get binlinkTypography => Theme.of(this).extension<BinLinkTypography>()!;
}
