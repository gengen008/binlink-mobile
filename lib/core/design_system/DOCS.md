# BinLink Design Operating System (BDOS) Documentation

## Overview
BDOS is the formal design constitution for BinLink. It ensures visual consistency, motion quality, and architectural rigor as the product scales from a local logistics tool to a continental operating system.

---

## 1. Design Governance
**Law:** Zero hardcoded stylistic values allowed in the UI layer.
*   **Colors:** All colors must be accessed via `context.binlinkColors`.
*   **Typography:** All text styles must be accessed via `context.binlinkTypography`.
*   **Spacing:** Use `AppSpacing.md`, `AppSpacing.lg`, etc., for all paddings, margins, and gaps.
*   **Radius:** Cards and Sheets must use `AppRadius.lg` (24px). Buttons and Inputs use `AppRadius.md` (16px).

---

## 2. Dynamic Theming (`ThemeExtension`)
The system supports three core modes:
1.  **Light Mode:** Standard for Household users during the day.
2.  **Dark Mode:** Premium experience for Household users at night.
3.  **Collector Mode:** High-contrast, action-oriented (Amber/Gold) theme exclusively for the Collector flavor.

Access pattern:
```dart
final colors = context.binlinkColors;
final textStyle = context.binlinkTypography.h1;
```

---

## 3. Motion & Haptics
Motion is a physical property of BinLink, not just a visual one.
*   **Snappy:** 150ms for small interactions.
*   **Flow:** 350ms for screens and sheets.
*   **Haptics:** Must be triggered for all critical state changes (Success, Error, Selection).

---

## 4. Component Library
All components are built on accessible Material foundations.
*   `AppButton`: Replaces raw `ElevatedButton`. Includes haptics and scale animations.
*   `AppTextField`: Standardized inputs with animated focus states.
*   `AppCard`: Standardized radius and shadow application.

---

## 5. Asset Acquisition
Assets are synchronized locally using `scripts/sync_design_assets.sh`. 
**Forbidden:** Runtime image downloads for static UI elements. All icons must be SVGs stored in `assets/icons/`.
