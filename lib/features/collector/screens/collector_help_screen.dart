import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_bar.dart';

class CollectorHelpScreen extends StatelessWidget {
  const CollectorHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppScaffoldBar(title: 'Help & Support'),
      body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Collector Support',
                      style: AppTextStyles.h4.copyWith(color: AppColors.secondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We're here to help you earn more.",
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.steelBlue),
                    ),
                    const SizedBox(height: 20),

                    Text('Frequently Asked Questions',
                        style: AppTextStyles.h4.copyWith(color: AppColors.secondary)),
                    const SizedBox(height: 12),

                    ..._faqs.map((faq) => _FaqTile(faq: faq)),

                    const SizedBox(height: 28),

                    Text('Contact Support',
                        style: AppTextStyles.h4.copyWith(color: AppColors.secondary)),
                    const SizedBox(height: 12),

                    _ContactCard(
                      icon: PhosphorIconsRegular.phone,
                      label: 'Call Us',
                      value: '+233 55 123 4567',
                      onTap: () =>
                          launchUrl(Uri.parse('tel:+233551234567')),
                    ),

                    const SizedBox(height: 10),

                    _ContactCard(
                      icon: PhosphorIconsRegular.envelope,
                      label: 'Email Support',
                      value: 'collectors@binlink.eco',
                      onTap: () => launchUrl(
                        Uri.parse('mailto:collectors@binlink.eco'
                            '?subject=Collector%20Support%20Request'),
                      ),
                    ),

                    const SizedBox(height: 10),

                    _ContactCard(
                      icon: PhosphorIconsRegular.whatsappLogo,
                      label: 'WhatsApp',
                      value: 'Chat with an agent',
                      onTap: () => launchUrl(
                        Uri.parse('https://wa.me/233551234567'
                            '?text=Hello%2C%20I%20need%20help%20as%20a%20BinLink%20collector'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}

// ── FAQ data ─────────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

const _faqs = [
  _FaqItem(
    'How do I go online and start receiving jobs?',
    'Tap the green "Go Online" toggle on your map screen. Once online, BinLink will notify you instantly when a new pickup request is nearby. Make sure your GPS and notifications are enabled for the best experience.',
  ),
  _FaqItem(
    'How do I accept a job?',
    'When a new job arrives, you\'ll see a popup card with the job details — location, bin size, and payout amount. Tap "Accept Job" within 60 seconds. Jobs are assigned on a first-come, first-served basis, so act quickly!',
  ),
  _FaqItem(
    'What happens after I accept a job?',
    'After accepting:\n1. Tap "En Route" when you start heading to the pickup.\n2. Tap "I\'ve Arrived" when you reach the household.\n3. Take a "before" photo of the waste.\n4. Collect the waste, then tap "Complete Pickup".\n5. Take an optional "after" photo.\nThe household is notified at each step.',
  ),
  _FaqItem(
    'How do I complete a pickup correctly?',
    'Make sure you:\n• Mark "En Route" before leaving\n• Arrive at the correct address (confirm with the household if needed)\n• Upload the before-photo when prompted\n• Only mark "Complete" once the waste is fully collected\n\nIncomplete or fraudulent pickups may result in account suspension.',
  ),
  _FaqItem(
    'How and when do I get paid?',
    'Your earnings are credited immediately after each completed pickup. You can view your balance in the Earnings tab. Request a payout to your registered MoMo number at any time — payouts are processed within 24 hours on business days.',
  ),
  _FaqItem(
    'What is the platform commission?',
    'BinLink takes a 10% platform fee from each completed job. You receive 90% of the household\'s payment. For example, a GHC 40 pickup earns you GHC 36 net.',
  ),
  _FaqItem(
    'What vehicle types are accepted?',
    'We accept tricycles, pickup trucks, mini trucks, and vans. Your vehicle must be in good working condition and able to transport at least one 240L bin. You can update your vehicle details from your Profile > Vehicle Details.',
  ),
  _FaqItem(
    'Can I cancel an accepted job?',
    'We ask that you only cancel in genuine emergencies. To cancel, go to the active job screen and tap "Cancel Pickup". Frequent cancellations will negatively impact your rating and may reduce the number of jobs you receive.',
  ),
  _FaqItem(
    'What is the rating system?',
    'Households rate you 1–5 stars after each completed pickup. Your average rating is shown on your profile. Maintain a rating above 4.0 to stay eligible for premium jobs in high-demand areas.',
  ),
  _FaqItem(
    'My GPS is not working — what do I do?',
    'Ensure location permission is set to "Allow all the time" in your phone settings for BinLink. Restart the app if the map is not updating. If GPS issues persist, contact our support team.',
  ),
];

// ── Widgets ──────────────────────────────────────────────────────────────────

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _open
                ? AppColors.steelBlue.withAlpha(15)
                : AppColors.fieldFill,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _open
                  ? AppColors.steelBlue.withAlpha(80)
                  : AppColors.fieldFill,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  Icon(
                    _open
                        ? PhosphorIconsRegular.caretUp
                        : PhosphorIconsRegular.caretDown,
                    color: AppColors.steelBlue,
                    size: 18,
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.secondary.withAlpha(30)),
                const SizedBox(height: 12),
                Text(
                  widget.faq.answer,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5483B3), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                      )),
                  const SizedBox(height: 2),
                  Text(value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      )),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.arrowRight,
                color: AppColors.muted, size: 10),
          ],
        ),
      ),
    );
  }
}
