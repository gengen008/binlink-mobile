# BinLink Mobile — Asset Licenses

All assets used in this project are listed below with source, license, and date.

---

## Icons

| Asset | Source | License | Notes |
|-------|--------|---------|-------|
| All UI icons (Phosphor) | [phosphoricons.com](https://phosphoricons.com) | MIT | Via `phosphor_flutter: ^2.1.0` Dart package — no separate asset files needed |

---

## Fonts

| Font | Source | License | Notes |
|------|--------|---------|-------|
| Plus Jakarta Sans | [fonts.google.com/specimen/Plus+Jakarta+Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) | SIL OFL 1.1 | Loaded at runtime via `google_fonts: ^6.2.1` package |
| DM Mono | [fonts.google.com/specimen/DM+Mono](https://fonts.google.com/specimen/DM+Mono) | SIL OFL 1.1 | Loaded at runtime via `google_fonts: ^6.2.1` package |

---

## Images (`assets/images/`)

| File | Source | License | Notes |
|------|--------|---------|-------|
| `app_icon.png` | BinLink internal | Proprietary | App launcher icon — replace with official brand asset |
| `logo.png` | BinLink internal | Proprietary | In-app logo — replace with official brand asset |
| `defaultavatar.png` | BinLink internal | Proprietary | Fallback user avatar |
| `destination.png` | BinLink internal | Proprietary | Map destination marker |
| `house.png` | BinLink internal | Proprietary | Map home-location marker |

---

## SVG Assets (`assets/svg/`)

| File | Source | License | Notes |
|------|--------|---------|-------|
| `google.svg` | Google Brand Resources | [Google Brand Permissions](https://about.google/brand-resource-center/) | Use only for "Sign in with Google" button per guidelines |
| `binlink_logo.svg` | BinLink internal | Proprietary | Brand mark — bin icon + wordmark |
| `pickup_marker.svg` | BinLink internal | Proprietary | Map marker for pickup location |
| `collector_marker.svg` | BinLink internal | Proprietary | Map marker for collector position |
| `empty_pickups.svg` | BinLink internal | Proprietary | Empty state for pickup history |
| `empty_notifications.svg` | BinLink internal | Proprietary | Empty state for notifications |
| `empty_earnings.svg` | BinLink internal | Proprietary | Empty state for earnings screen |
| `globe-africa.svg` | BinLink internal / custom | Proprietary | Auth screen illustration |
| `locate.svg` | BinLink internal / custom | Proprietary | Map locate-me button |
| `drawer.svg` | BinLink internal / custom | Proprietary | Sidebar menu icon |
| `cash.svg` | BinLink internal / custom | Proprietary | Payment / wallet illustration |
| `envelope.svg` | BinLink internal / custom | Proprietary | Email / notification illustration |

---

## Deleted Assets (removed from this version)

| File | Reason |
|------|--------|
| `assets/fonts/*.ttf` (7 files) | HTML documents masquerading as TTF binaries — replaced with `google_fonts` runtime loading |
| `assets/images/main.jpg` | Unused background image |
| `assets/images/Citybackground.jpg` | Unused background image |
| `assets/jsons/dribbble.json` | Template/placeholder Lottie animation not used in production |
| `assets/svg/bag.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/bank.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/call.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/card.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/chat.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/home.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/hospital.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/house.svg` | Unused + contained base64-embedded PNG violating SVG purity rule |
| `assets/svg/school.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/shop.svg` | Unused — no code reference, no pubspec entry |
| `assets/svg/stopwatch.svg` | Unused — no code reference, no pubspec entry |

---

_Last updated: 2026-06-06_
