import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_bar.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<_FaqItem> _faqs = const [
    _FaqItem(
      q: 'How do I book a pickup?',
      a: 'Tap "Request Now" on the home screen for immediate pickup, or "Schedule" to choose a specific date and time. Follow the 5-step wizard to choose waste category, bin size, date, address, and payment.',
    ),
    _FaqItem(
      q: 'How are collectors assigned?',
      a: 'BinLink automatically matches your booking to the nearest available collector based on GPS location and current load capacity. You\'ll see their name and ETA once assigned.',
    ),
    _FaqItem(
      q: 'What are Eco Rewards?',
      a: 'When you book a pickup for recyclable waste (Plastic, Glass, Metal, or Organic), you earn 10 Eco Points. Every 100 points earns a GHC 5 discount on your next pickup.',
    ),
    _FaqItem(
      q: 'How do I cancel a booking?',
      a: 'Tap the active booking banner on your home screen, then tap the three-dot menu and select "Cancel Booking". Cancellations are free before a collector is assigned.',
    ),
    _FaqItem(
      q: 'How do I get a refund?',
      a: 'Refunds for cancelled bookings are processed within 3-5 business days back to your MoMo account. Contact support if your refund has not arrived after 7 days.',
    ),
    _FaqItem(
      q: 'Which payment methods are supported?',
      a: 'We support MTN Mobile Money, Telecel Cash, and AirtelTigo Money. All payments are processed securely through Paystack.',
    ),
    _FaqItem(
      q: 'What bin sizes are available?',
      a: 'Small (≤120L) for GHC 30, Medium (180L) for GHC 40, and Large (240L) for GHC 50. You can also add extra bags for GHC 6 each.',
    ),
    _FaqItem(
      q: 'How do I track my collector?',
      a: 'Once your booking is accepted, tap the active pickup banner on your home screen to see your collector\'s live location on the map.',
    ),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppScaffoldBar(title: 'Help & Support'),
      body: Column(
          children: [
            Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frequently Asked Questions',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.secondary,
                          )),
                      const SizedBox(height: 16),

                      // FAQ accordion
                      ...List.generate(_faqs.length, (i) {
                        final isOpen = _expanded.contains(i);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              if (isOpen) {
                                _expanded.remove(i);
                              } else {
                                _expanded.add(i);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppColors.primary.withAlpha(10)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isOpen
                                      ? AppColors.primary.withAlpha(30)
                                      : AppColors.border,
                                ),
                                boxShadow: [
                                  if (!isOpen)
                                    BoxShadow(
                                      color: Colors.black.withAlpha(5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _faqs[i].q,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedRotation(
                                          turns: isOpen ? 0.5 : 0,
                                          duration: const Duration(
                                              milliseconds: 200),
                                          child: const Icon(
                                            LucideIcons.chevronDown,
                                            color: AppColors.muted,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isOpen) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _faqs[i].a,
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
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Contact support card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'Still need help?',
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _ContactRow(
                              icon: LucideIcons.phone,
                              label: 'Customer Support',
                              value: '+233 24 000 0000',
                              onTap: () => launchUrl(
                                Uri.parse('tel:+233240000000'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ContactRow(
                              icon: LucideIcons.mail,
                              label: 'Email Support',
                              value: 'help@binlink.eco',
                              onTap: () => launchUrl(
                                Uri.parse('mailto:help@binlink.eco'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                    )),
                Text(value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    )),
              ],
            ),
          ),
          const Icon(LucideIcons.arrowRight,
              color: AppColors.muted, size: 10),
        ],
      ),
    );
  }
}
