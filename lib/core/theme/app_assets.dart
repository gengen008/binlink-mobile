/// BinLink Eco — Asset Paths
///
/// V5: Purged all raster PNGs. Enforcing SVG, 3D, and Lottie assets.
class AppAssets {
  AppAssets._();

  // ── Brand & Logos ─────────────────────────────────────────────────────────
  static const logoSvg        = 'assets/svg/binlink_logo.svg';
  static const logoPremiumSvg = 'assets/svg/binlink_logo_premium.svg';
  static const appIcon        = 'assets/branding/app_icon/app_icon.png';

  // ── SVG Icons & Assets ────────────────────────────────────────────────────
  static const pickupMarker    = 'assets/svg/pickup_marker.svg';
  static const collectorMarker = 'assets/svg/collector_marker.svg';
  static const google          = 'assets/svg/google.svg';
  static const globe           = 'assets/svg/globe-africa.svg';

  // ── Photography & Avatars ─────────────────────────────────────────────────
  static const userAvatar      = 'assets/images/defaultavatar.png';

  // ── 3D Illustrations (Icons8 Ouch) ────────────────────────────────────────
  // Placeholder paths for the new 3D assets to be downloaded
  static const bin3d           = 'assets/v4/3d/Recycling bin.png';
  static const truck3d         = 'assets/v4/3d/Recycling Truck.png';
  static const recycleBin      = 'assets/v4/3d/Recycling bin.png'; // Example placeholder
  static const leaf            = 'assets/v4/3d/Recycling bin.png'; // Example placeholder
  static const bottle          = 'assets/v4/3d/Recycling bin.png'; // Example placeholder
  static const laptop          = 'assets/v4/3d/Recycling bin.png'; // Example placeholder
  static const construction    = 'assets/v4/3d/Recycling bin.png'; // Example placeholder
  static const trashPile       = 'assets/v4/3d/Recycling bin.png'; // Example placeholder
  static const trashBin        = 'assets/v4/3d/Recycling bin.png'; // Example placeholder
  static const truck           = 'assets/v4/3d/Recycling Truck.png';
  static const pin             = 'assets/v4/3d/location.png'; // Used in map
  static const gps             = 'assets/v4/3d/location.png'; // Used in map
  
  // ── Premium Illustrations (unDraw) ────────────────────────────────────────
  static const onboarding1     = 'assets/illustrations/onboarding/onboarding_1.svg';
  static const onboarding2     = 'assets/illustrations/onboarding/onboarding_2.svg';
  static const onboarding3     = 'assets/illustrations/onboarding/onboarding_3.svg';
  static const onboarding4     = 'assets/illustrations/onboarding/onboarding_4.svg';
  static const emptyState      = 'assets/illustrations/empty_states/no_data.svg';
  static const emptyPickups    = 'assets/illustrations/empty_states/no_pickups.svg';
  static const emptyEarnings   = 'assets/illustrations/empty_states/no_earnings.svg';
  static const emptyNotifications = 'assets/illustrations/empty_states/no_notifications.svg';

  // ── Lottie Animations ────────────────────────────────────────────────────
  static const lottieSplash    = 'assets/branding/splash/splash.json';
  static const lottieLoading   = 'assets/lottie/loading/loading.json';
  static const lottieSearching = 'assets/lottie/booking/searching.json';
  static const lottieSuccess   = 'assets/lottie/success/success.json';
  static const lottieError     = 'assets/lottie/errors/error.json';
  static const lottieWallet    = 'assets/lottie/wallet/wallet.json';
  static const lottieBell      = 'assets/lottie/notifications/notifications.json';
  static const lottieLocation  = 'assets/lottie/errors/location_permission.json';
}
