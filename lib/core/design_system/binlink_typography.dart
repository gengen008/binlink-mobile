import 'package:flutter/material.dart';

/// BDOS Theme Extension — Typography
/// 
/// Standardizes the font stack across all branding layers.
class BinLinkTypography extends ThemeExtension<BinLinkTypography> {
  const BinLinkTypography({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.button,
    required this.dataLarge,
    required this.dataMedium,
    required this.dataSmall,
  });

  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle button;
  final TextStyle dataLarge;
  final TextStyle dataMedium;
  final TextStyle dataSmall;

  @override
  BinLinkTypography copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? button,
    TextStyle? dataLarge,
    TextStyle? dataMedium,
    TextStyle? dataSmall,
  }) {
    return BinLinkTypography(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      button: button ?? this.button,
      dataLarge: dataLarge ?? this.dataLarge,
      dataMedium: dataMedium ?? this.dataMedium,
      dataSmall: dataSmall ?? this.dataSmall,
    );
  }

  @override
  BinLinkTypography lerp(ThemeExtension<BinLinkTypography>? other, double t) {
    if (other is! BinLinkTypography) return this;
    return BinLinkTypography(
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      dataLarge: TextStyle.lerp(dataLarge, other.dataLarge, t)!,
      dataMedium: TextStyle.lerp(dataMedium, other.dataMedium, t)!,
      dataSmall: TextStyle.lerp(dataSmall, other.dataSmall, t)!,
    );
  }
}
