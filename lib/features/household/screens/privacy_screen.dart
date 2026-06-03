import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PolicyScreen(
      title: 'Privacy Policy',
      icon: PhosphorIconsFill.shieldCheck,
      sections: const [
        _PolicySection(
          heading: '1. Information We Collect',
          body:
              'BinLink collects information you provide directly, including your name, email address, phone number, and pickup address. We also collect location data when you use the app to enable GPS-based collector matching and live tracking. Usage data such as pickup history and payment records are stored to improve our service.',
        ),
        _PolicySection(
          heading: '2. How We Use Your Information',
          body:
              'We use your information to:\n• Match your pickup requests to the nearest available collector\n• Process payments through Paystack\n• Send booking confirmations and status updates via push notifications and SMS\n• Calculate and credit Eco Rewards points\n• Improve the reliability and features of our platform',
        ),
        _PolicySection(
          heading: '3. Data Sharing',
          body:
              'We share only the minimum information required with third parties:\n• Collectors receive your name, address, and phone number for pickup coordination\n• Paystack processes payment data under their own privacy policy\n• Firebase handles push notification delivery\n• Termii handles SMS delivery\n\nWe never sell your personal data.',
        ),
        _PolicySection(
          heading: '4. Location Data',
          body:
              'Your GPS location is used in real-time during an active booking to enable live tracking. Location data is not stored permanently. Collector locations are temporarily stored to enable the nearby collector map view.',
        ),
        _PolicySection(
          heading: '5. Data Retention',
          body:
              'Account data is retained for as long as your account is active. Booking history is retained for 3 years for accounting and dispute resolution. You may request deletion of your account and associated data by contacting support@binlink.eco.',
        ),
        _PolicySection(
          heading: '6. Security',
          body:
              'All data is transmitted over HTTPS. Passwords are hashed using bcrypt with 12 rounds. JWT tokens expire after 15 minutes. We employ rate limiting and other technical safeguards to protect your account.',
        ),
        _PolicySection(
          heading: '7. Your Rights',
          body:
              'You have the right to access, correct, or delete your personal data. You may opt out of marketing communications at any time. For any privacy-related requests, contact us at privacy@binlink.eco.',
        ),
        _PolicySection(
          heading: '8. Contact',
          body:
              'BinLink Eco Ltd.\nAccra, Ghana\nEmail: privacy@binlink.eco\nPhone: +233 55 123 4567\n\nLast updated: June 2026',
        ),
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PolicyScreen(
      title: 'Terms of Service',
      icon: PhosphorIconsFill.files,
      sections: const [
        _PolicySection(
          heading: '1. Acceptance of Terms',
          body:
              'By using the BinLink app, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app. We reserve the right to modify these terms at any time with notice.',
        ),
        _PolicySection(
          heading: '2. Service Description',
          body:
              'BinLink is an on-demand waste collection platform that connects households and businesses with independent waste collectors in Ghana. We act as a marketplace and are not directly responsible for the physical collection service provided by independent collectors.',
        ),
        _PolicySection(
          heading: '3. User Accounts',
          body:
              'You are responsible for maintaining the security of your account credentials. You must be at least 18 years old to use BinLink. One account per person. Accounts found to be abused may be suspended or terminated.',
        ),
        _PolicySection(
          heading: '4. Bookings and Payments',
          body:
              'All bookings are subject to collector availability. Prices are displayed in Ghana Cedis (GHC). Payments are processed by Paystack. BinLink charges a GHC 2 service fee per booking. Collectors receive 80% of the booking amount.',
        ),
        _PolicySection(
          heading: '5. Cancellations and Refunds',
          body:
              'Free cancellation is available before a collector accepts your booking. After acceptance, a cancellation fee of GHC 5 applies. Refunds are processed within 3-5 business days. No refunds are available once a collector has arrived at your location.',
        ),
        _PolicySection(
          heading: '6. Eco Rewards',
          body:
              'Eco Points are earned on eligible recyclable waste pickups and have no cash value except when redeemed as booking discounts. Points expire after 12 months of account inactivity. BinLink reserves the right to modify or discontinue the rewards program.',
        ),
        _PolicySection(
          heading: '7. Prohibited Uses',
          body:
              'You may not use BinLink to:\n• Dispose of hazardous, medical, or illegal materials\n• Book pickups with no intention of using the service\n• Harass or abuse collectors\n• Circumvent our payment systems\n\nViolations will result in account suspension.',
        ),
        _PolicySection(
          heading: '8. Limitation of Liability',
          body:
              'BinLink is not liable for any damages arising from the actions of independent collectors, delays in service, or any indirect, incidental, or consequential damages. Our maximum liability is limited to the amount paid for the disputed booking.',
        ),
        _PolicySection(
          heading: '9. Governing Law',
          body:
              'These terms are governed by the laws of the Republic of Ghana. Any disputes will be resolved in the courts of Accra, Ghana.\n\nLast updated: June 2026',
        ),
      ],
    );
  }
}

// ── Shared policy screen layout ───────────────────────────────────────────────

class _PolicyScreen extends StatelessWidget {
  const _PolicyScreen({
    required this.title,
    required this.icon,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final List<_PolicySection> sections;

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
                    Icon(icon, color: AppColors.skyBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(title, style: AppTextStyles.h3)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sections.map((s) => _SectionBlock(section: s)).toList(),
                  ),
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
  const _PolicySection({required this.heading, required this.body});
  final String heading;
  final String body;
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});
  final _PolicySection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.heading,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.skyBlue,
              )),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
