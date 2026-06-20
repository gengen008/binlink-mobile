import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/utils/formatters.dart';

class BinLinkAvatar extends StatelessWidget {
  const BinLinkAvatar({
    super.key,
    required this.name,
    this.imagePath,
    required this.fallbackAsset,
    this.size = 72,
    this.dark = false,
  });

  final String? name;
  final String? imagePath;
  final String fallbackAsset;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF263241) : const Color(0xFFE8EEF6);
    final fg = dark ? Colors.white : const Color(0xFF1F2937);
    Widget child;
    if (imagePath != null && imagePath!.isNotEmpty) {
      final path = imagePath!;
      if (path.startsWith('http')) {
        child = Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback(fg));
      } else if (File(path).existsSync()) {
        child = Image.file(File(path), fit: BoxFit.cover);
      } else if (path.endsWith('.svg')) {
        child = SvgPicture.asset(path, fit: BoxFit.cover);
      } else {
        child = _fallback(fg);
      }
    } else {
      child = _fallback(fg);
    }
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: bg,
        child: child,
      ),
    );
  }

  Widget _fallback(Color fg) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SvgPicture.asset(fallbackAsset, fit: BoxFit.cover),
        Center(
          child: Text(
            Fmt.initials(name),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.24,
            ),
          ),
        ),
      ],
    );
  }
}
