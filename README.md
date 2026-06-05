# BinLink Eco

On-demand waste collection for Ghana. Households book pickups; collectors accept and complete jobs — all in real time.

---

## Download APK

> **[Latest Release — Download APKs](https://github.com/gengen008/binlink-mobile/releases/latest)**

| APK | Role |
|-----|------|
| `BinLink-Eco-v2.apk` | Household — book waste pickups |
| `BinLink-Collector-v2.apk` | Collector — accept and complete jobs |

### Install on Android
1. Download the APK for your role from the link above
2. On your phone: **Settings → Apps → Special access → Install unknown apps** → allow your browser or file manager
3. Open the downloaded `.apk` and tap **Install**

---

## What it does

**Household app**
- Book on-demand or recurring waste pickups
- Live GPS tracking of your collector
- In-app chat with your collector
- Eco points for recyclable waste
- Pickup history and receipts

**Collector app**
- Go online / offline toggle with live map
- Accept nearby job requests in real time
- Step-by-step pickup flow with photo evidence
- Earnings wallet with MoMo payout

---

## Tech stack

| Layer | Stack |
|-------|-------|
| Mobile | Flutter 3.38 · Dart · Provider · MapLibre GL |
| Backend | Node.js · Express · Prisma · PostgreSQL |
| Real-time | Socket.io · Redis pub/sub |
| Auth | Firebase Auth · JWT |
| Notifications | FCM |
| Maps | SmartMaps / TomTom / Nominatim cascade |
| Hosting | Railway (backend) · GitHub Releases (APKs) |

---

## Build from source

```bash
# 1. Clone
git clone https://github.com/gengen008/binlink-mobile.git
cd binlink-mobile

# 2. Copy and fill environment variables
cp .env.example .env

# 3. Install dependencies
flutter pub get

# 4. Run household flavor
flutter run --flavor household --target lib/main_household.dart

# 5. Run collector flavor
flutter run --flavor collector --target lib/main_collector.dart
```

### Required secrets (GitHub Actions / `.env`)

| Variable | Description |
|----------|-------------|
| `API_BASE_URL` | Backend URL, e.g. `https://binlink-api-production.up.railway.app` |
| `SOCKET_URL` | Same base URL as API |
| `TOMTOM_API_KEY` | TomTom Routing API key |
| `SMARTMAPS_API_KEY` | SmartMaps autocomplete key |
| `GOOGLE_SERVICES_JSON_HOUSEHOLD` | Base64-encoded `google-services.json` for household flavor |
| `GOOGLE_SERVICES_JSON_COLLECTOR` | Base64-encoded `google-services.json` for collector flavor |
| `KEYSTORE_BASE64` | Base64-encoded release keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEYSTORE_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

---

## CI / CD

Every push to `main` triggers the GitHub Actions workflow:

1. Builds both APKs (household + collector) with release signing
2. Runs `flutter analyze` — fails the build on any issue
3. Publishes both APKs to the [latest GitHub Release](https://github.com/gengen008/binlink-mobile/releases/latest)

---

## Backend

Source: [gengen008/binlink-backend](https://github.com/gengen008/binlink-backend)
Live API: `https://binlink-api-production.up.railway.app`
Health: `https://binlink-api-production.up.railway.app/health`

---

## Pricing (GHS)

| Bin size | Price |
|----------|-------|
| Small (≤120 L) | GHC 30 |
| Medium (180 L) | GHC 40 |
| Large (240 L) | GHC 50 |
| Extra bag | GHC 6 |

Payment: cash on delivery only.
