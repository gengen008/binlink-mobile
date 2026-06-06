/// BinLink Eco — Asset Paths
///
/// Single source of truth for all asset paths.
/// Never hard-code paths in widgets — always use AppAssets.
class AppAssets {
  AppAssets._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const logo      = 'assets/images/logo.png';   // PNG for Image.asset
  static const logoSvg   = 'assets/svg/binlink_logo.svg';
  static const splash    = 'assets/images/logo.png';
  static const appIcon   = 'assets/images/app_icon.png';

  // ── Avatars ───────────────────────────────────────────────────────────────
  static const userAvatar  = 'assets/images/defaultavatar.png';

  // ── Map markers ───────────────────────────────────────────────────────────
  static const pickupMarker    = 'assets/svg/pickup_marker.svg';
  static const collectorMarker = 'assets/svg/collector_marker.svg';

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
