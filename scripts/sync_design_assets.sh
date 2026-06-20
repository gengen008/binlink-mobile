#!/bin/bash

# BDOS Asset Acquisition Engine
# Authentically downloads premium open-source SVGs into the local library.

set -e

PROJECT_ROOT=$(pwd)
ASSETS_DIR="$PROJECT_ROOT/assets"

echo "🚀 BDOS Asset Acquisition Engine starting..."

# 1. Structure Preparation
mkdir -p "$ASSETS_DIR"/icons/{navigation,booking,waste,tracking,wallet,analytics,profile,status}
mkdir -p "$ASSETS_DIR"/branding

# 2. Download Core Brand Icons (Simple Icons)
# Using raw.githubusercontent.com for direct SVG access
echo "📥 Fetching Brand Logos..."
curl -s -o "$ASSETS_DIR/branding/google.svg" https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/google.svg
curl -s -o "$ASSETS_DIR/branding/apple.svg" https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/apple.svg
curl -s -o "$ASSETS_DIR/branding/paystack.svg" https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/paystack.svg

# 3. Download Functional Icons (Phosphor Icons - Bold/Fill)
echo "📥 Fetching Navigation Icons..."
curl -s -o "$ASSETS_DIR/icons/navigation/home.svg" https://raw.githubusercontent.com/phosphor-icons/core/main/assets/fill/house-fill.svg
curl -s -o "$ASSETS_DIR/icons/navigation/back.svg" https://raw.githubusercontent.com/phosphor-icons/core/main/assets/bold/arrow-left-bold.svg
curl -s -o "$ASSETS_DIR/icons/navigation/search.svg" https://raw.githubusercontent.com/phosphor-icons/core/main/assets/bold/magnifying-glass-bold.svg

echo "📥 Fetching Logistics Icons..."
curl -s -o "$ASSETS_DIR/icons/waste/trash.svg" https://raw.githubusercontent.com/phosphor-icons/core/main/assets/fill/trash-fill.svg
curl -s -o "$ASSETS_DIR/icons/waste/recycle.svg" https://raw.githubusercontent.com/phosphor-icons/core/main/assets/fill/recycle-fill.svg
curl -s -o "$ASSETS_DIR/icons/tracking/truck.svg" https://raw.githubusercontent.com/phosphor-icons/core/main/assets/fill/truck-fill.svg

# 4. Preparation for Lottie (Documentation)
cat <<EOF > "$ASSETS_DIR/lottie/README.md"
# Lottie Animation Requirements
Download and place the following JSONs from LottieFiles:
- loading.json
- success.json
- searching.json
- wallet.json
EOF

# 5. Asset Cleanup
find "$ASSETS_DIR" -name "*.gitkeep" -delete
find "$ASSETS_DIR" -type d -exec touch {}/.gitkeep \;

echo "✅ BDOS Assets synchronized locally. No remote dependencies at runtime."
