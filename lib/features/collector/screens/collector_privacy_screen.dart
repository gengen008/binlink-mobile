import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_bar.dart';

class CollectorPrivacyScreen extends StatelessWidget {
  const CollectorPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppScaffoldBar(title: 'Privacy Policy'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            ..._sections.map((s) => _SectionTile(section: s)),
          ],
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
        'BinLink collects information you provide during registration and while using the app, including:\n• Full name, phone number, and email address\n• Vehicle type and plate number\n• GPS location during active pickups\n• Bank or MoMo account details for payout processing\n• Pickup history and earnings records',
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
    heading: '5. Data Retention',
    body:
        'Account data is retained while your account is active. Earnings and payout records are retained for 5 years for accounting and regulatory compliance. You may request account deletion at any time by contacting support@binlink.eco.',
  ),
  _PolicySection(
    heading: '6. Security',
    body:
        'All data is transmitted over HTTPS with TLS encryption. Passwords are hashed using bcrypt (12 rounds). JWT tokens expire every 15 minutes. We employ rate limiting, IP monitoring, and other technical controls to protect your account.',
  ),
  _PolicySection(
    heading: '7. Your Rights',
    body:
        'You have the right to access, correct, or delete your personal data. You may deactivate your account at any time from the app. For any privacy-related requests, contact us at privacy@binlink.eco.',
  ),
  _PolicySection(
    heading: '8. Contact',
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
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.heading,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                )),
            const SizedBox(height: 10),
            Text(
              section.body,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
