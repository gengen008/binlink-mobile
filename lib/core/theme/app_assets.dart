/// BinLink Eco — Asset Paths
class AppAssets {
  AppAssets._();

  // ── Brand & Logos ─────────────────────────────────────────────────────────
  // No logo SVG yet — auth screens fall back to text logo
  static const google          = 'assets/branding/google.svg';
  static const paystack        = 'assets/branding/paystack.svg';
  static const apple           = 'assets/branding/apple.svg';

  // ── Photography & Avatars ─────────────────────────────────────────────────
  static const userAvatar      = 'assets/images/defaultavatar.png';

  // ── 3D Illustrations ──────────────────────────────────────────────────────
  static const bin3d           = 'assets/v4/3d/Recycling bin.png';
  static const truck3d         = 'assets/v4/3d/Recycling Truck.png';
  static const recycleBin      = 'assets/v4/3d/Recycling bin.png';
  static const truck           = 'assets/v4/3d/Recycling Truck.png';
  // Category icons — all fall back to bin3d until custom assets are added
  static const bottle          = 'assets/v4/3d/Recycling bin.png';
  static const leaf            = 'assets/v4/3d/Recycling bin.png';
  static const construction    = 'assets/v4/3d/Recycling bin.png';
  static const laptop          = 'assets/v4/3d/Recycling bin.png';
  static const trashPile       = 'assets/v4/3d/Recycling bin.png';

  // ── Illustrations (SVG) ───────────────────────────────────────────────────
  static const emptyState         = 'assets/illustrations/empty_states/no_data.svg';
  // All empty-state illustrations use the same no_data.svg until custom ones are added
  static const emptyPickups       = 'assets/illustrations/empty_states/no_data.svg';
  static const emptyEarnings      = 'assets/illustrations/empty_states/no_data.svg';
  static const emptyNotifications = 'assets/illustrations/empty_states/no_data.svg';

  // Onboarding illustrations (JPG versions in images/onboarding/)
  static const onboarding1     = 'assets/images/onboarding/onboarding_1.jpg';
  static const onboarding2     = 'assets/images/onboarding/onboarding_2.jpg';
  static const onboarding3     = 'assets/images/onboarding/onboarding_3.jpg';
  static const onboarding4     = 'assets/images/onboarding/onboarding_1.jpg'; // fallback

  // ── Lottie Animations ────────────────────────────────────────────────────
  static const lottieSplash    = 'assets/branding/splash/splash.json';
  static const lottieLoading   = 'assets/lottie/loading/loading.json';
  static const lottieSearching = 'assets/lottie/booking/searching.json';
  static const lottieSuccess   = 'assets/lottie/success/success.json';
  static const lottieError     = 'assets/lottie/errors/error.json';
  static const lottieWallet    = 'assets/lottie/wallet/wallet.json';
  static const lottieBell      = 'assets/lottie/notifications/notifications.json';
  static const lottieLocation  = 'assets/lottie/errors/location_permission.json';
  static const lottieNoPickups = 'assets/lottie/empty_states/no_pickups.json';
}
