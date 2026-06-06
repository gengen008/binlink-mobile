/// BinLink Eco — Asset Paths
///
/// Single source of truth for all asset paths.
/// Never hard-code paths in widgets — always use AppAssets.
class AppAssets {
  AppAssets._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const logoSvg        = 'assets/svg/binlink_logo.svg';
  static const logoPremiumSvg = 'assets/svg/binlink_logo_premium.svg';
  static const splash         = 'assets/svg/binlink_logo.svg';
  static const appIcon   = 'assets/svg/binlink_logo.svg';

  // ── Avatars ───────────────────────────────────────────────────────────────
  static const userAvatar  = 'assets/images/defaultavatar.png';

  // ── Onboarding ──────────────────────────────────────────────────────────
  static const onboarding1 = 'assets/svg/onboarding_1.svg';
  static const onboarding2 = 'assets/svg/onboarding_2.svg';
  static const onboarding3 = 'assets/svg/onboarding_3.svg';
  static const onboarding4 = 'assets/svg/onboarding_4.svg';

  // ── Map markers ───────────────────────────────────────────────────────────
  static const pickupMarker    = 'assets/svg/pickup_marker.svg';
  static const collectorMarker = 'assets/svg/collector_marker.svg';
  static const truck           = 'assets/svg/collector_truck.svg';

  // ── Domain Icons ──────────────────────────────────────────────────────────
  static const rubbishBin     = 'assets/svg/rubbish_bin.svg';
  static const recyclingBag   = 'assets/svg/recycling_bag.svg';
  static const verifiedBadge  = 'assets/svg/verified_badge.svg';

  // ── Empty states ──────────────────────────────────────────────────────────
  static const emptyPickups       = 'assets/svg/empty_pickups.svg';
  static const emptyNotifications = 'assets/svg/empty_notifications.svg';
  static const emptyEarnings      = 'assets/svg/empty_earnings.svg';

  // ── Auth & UI ─────────────────────────────────────────────────────────────
  static const google    = 'assets/svg/google.svg';
  static const locate    = 'assets/svg/locate.svg';
  static const drawer    = 'assets/svg/drawer.svg';
  static const cash      = 'assets/svg/cash.svg';
  static const envelope  = 'assets/svg/envelope.svg';
  static const globe     = 'assets/svg/globe-africa.svg';
}
