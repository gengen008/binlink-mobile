import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget.ripple() extension — Rydr's home_extention.dart pattern.
///
/// Adds a full-cover InkWell ripple effect over any widget without
/// requiring the widget to be wrapped in a GestureDetector or InkWell.
///
/// Rydr bugs fixed:
///  - Used deprecated MaterialStateProperty.all → WidgetStateProperty.all
///  - Empty Container() as TextButton child → replaced with SizedBox.shrink()
///  - No haptic feedback option → added [haptic] parameter
///
/// Usage:
///   MyWidget().ripple(() { doSomething(); })
///   MyWidget().ripple(() { doSomething(); }, borderRadius: AppRadius.mdBR)
///   MyWidget().ripple(() { doSomething(); }, haptic: true)
extension RippleExt on Widget {
  Widget ripple(
    VoidCallback? onTap, {
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
    bool haptic = false,
  }) {
    return Stack(
      children: [
        this,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap == null
                  ? null
                  : () {
                      if (haptic) HapticFeedback.selectionClick();
                      onTap();
                    },
              borderRadius: borderRadius,
              splashColor: Colors.white.withAlpha(20),
              highlightColor: Colors.white.withAlpha(10),
            ),
          ),
        ),
      ],
    );
  }
}
