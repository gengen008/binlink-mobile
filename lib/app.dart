import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/household/providers/household_provider.dart';
import 'features/household/screens/home_screen.dart';
import 'features/collector/providers/collector_provider.dart';
import 'features/collector/screens/map_screen.dart';
import 'shared/models/user_model.dart';

class BinLinkApp extends StatelessWidget {
  const BinLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HouseholdProvider()),
        ChangeNotifierProvider(create: (_) => CollectorProvider()),
      ],
      child: MaterialApp(
        title: 'BinLink Eco',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: '/splash',
        routes: {
          '/splash':          (_) => const SplashScreen(),
          '/login':           (_) => const LoginScreen(),
          '/register':        (_) => const RegisterScreen(),
          '/forgot-password': (_) => const ForgotPasswordScreen(),
          '/household':       (_) => const HouseholdHomeScreen(),
          '/collector':       (_) => const CollectorMapScreen(),
          '/pending':         (_) => const _PendingVerificationScreen(),
        },
      ),
    );
  }
}

class _PendingVerificationScreen extends StatelessWidget {
  const _PendingVerificationScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.warning.withAlpha(80)),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: AppColors.warning, size: 40),
                ),
                const SizedBox(height: 24),
                Text('Account Under Review', style: AppTextStyles.h2, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Your collector account is being verified by our team. '
                  'You\'ll receive a notification once approved.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text('Sign Out', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
