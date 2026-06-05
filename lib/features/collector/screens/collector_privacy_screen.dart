import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_radius.dart';

class CollectorPrivacyScreen extends StatelessWidget {
  const CollectorPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(PhosphorIconsRegular.arrowLeft,
                          color: AppColors.white),
                    ),
                    const Expanded(
                      child: Text('Privacy Policy', style: AppTextStyles.h3),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // Header badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(15),
                        borderRadius: AppRadius.xlBR,
                        border: Border.all(
                            color: AppColors.warning.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsFill.shieldCheck,
                              color: AppColors.warning, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This policy applies to BinLink Collector accounts.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    ..._sections.map((s) => _SectionTile(section: s)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection {
  final String heading;
  final String body;
  const _PolicySection({required this.heading, required this.body});
}

const _sections = [
  _PolicySection(
    heading: '1. Information We Collect',
    body:
        'BinLink collects information you provide during registration and while using the app, including:\n• Full name, phone number, and email address\n• Vehicle type and plate number\n• GPS location during active pickups\n• Bank or MoMo account details for payout processing\n• Photos uploaded during pickups (before/after)\n• Pickup history and earnings records',
  ),
  _PolicySection(
    heading: '2. How We Use Your Information',
    body:
        'We use your information to:\n• Dispatch pickup jobs to you based on your location\n• Process your earnings and payouts via MoMo\n• Enable live GPS tracking for households during active pickups\n• Maintain your earnings history and tax records\n• Calculate your performance rating\n• Send job notifications and app updates via push (FCM)',
  ),
  _PolicySection(
    heading: '3. Location Data',
    body:
        'Your GPS location is broadcast in real-time to BinLink\'s servers while you are online. During an active pickup, your location is shared with the household you are serving. Location is not stored permanently after a pickup is completed.',
  ),
  _PolicySection(
    heading: '4. Data Sharing',
    body:
        'We share the minimum necessary data with third parties:\n• Households see your name, phone, and live location during active pickups\n• Paystack and MoMo operators process payout transactions\n• Firebase handles push notification delivery\n• Termii handles SMS delivery\n\nWe never sell your personal data to advertisers or third parties.',
  ),
  _PolicySection(
    heading: '5. Photos and Media',
    body:
        'Before and after photos you upload during pickups are stored securely on BinLink servers. They are used solely for job verification and dispute resolution. Photos are retained for 12 months and then automatically deleted.',
  ),
  _PolicySection(
    heading: '6. Data Retention',
    body:
        'Account data is retained while your account is active. Earnings and payout records are retained for 5 years for accounting and regulatory compliance. You may request account deletion at any time by contacting support@binlink.eco.',
  ),
  _PolicySection(
    heading: '7. Security',
    body:
        'All data is transmitted over HTTPS with TLS encryption. Passwords are hashed using bcrypt (12 rounds). JWT tokens expire every 15 minutes. We employ rate limiting, IP monitoring, and other technical controls to protect your account.',
  ),
  _PolicySection(
    heading: '8. Your Rights',
    body:
        'You have the right to access, correct, or delete your personal data. You may deactivate your account at any time from the app. For any privacy-related requests, contact us at privacy@binlink.eco.',
  ),
  _PolicySection(
    heading: '9. Contact',
    body:
        'BinLink Eco Ltd.\nAccra, Ghana\nEmail: privacy@binlink.eco\nCollector Support: collectors@binlink.eco\nPhone: +233 55 123 4567\n\nLast updated: June 2026',
  ),
];

class _SectionTile extends StatelessWidget {
  final _PolicySection section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.xlBR,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.heading,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.warning,
                )),
            const SizedBox(height: 10),
            Text(
              section.body,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
