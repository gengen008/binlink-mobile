// Rydr authHeader(BuildContext context) — exact transplant.
// Source: views/Authentication/components/auth_header.dart
//
// FadeInDown(1500ms) > Column([
//   Center(Container(w:105, h:33, DecorationImage(logo))),
//   YMargin(30),
//   Container(screenWidth, 160, DecorationImage(authimage1, contain))
// ])

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/rydr_assets.dart';

Widget authHeader(BuildContext context) {
  return FadeInDown(
    duration: const Duration(milliseconds: 1500),
    child: Column(
      children: [
        // Rydr: Center(Container(w:105, h:33, alignment:center, DecorationImage(logo)))
        Center(
          child: Container(
            alignment: Alignment.center,
            width: 105,
            height: 33,
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.contain,
                image: AssetImage(RydrAssets.logo),
              ),
            ),
          ),
        ),
        // Rydr: YMargin(30)
        const SizedBox(height: 30),
        // Rydr: Container(screenWidth, 160, DecorationImage(authimage1, contain))
        Container(
          width: MediaQuery.sizeOf(context).width,
          height: 160,
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.contain,
              image: AssetImage(RydrAssets.authimage1),
            ),
          ),
        ),
      ],
    ),
  );
}
