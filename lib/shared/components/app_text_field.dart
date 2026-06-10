import 'package:flutter/material.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_motion.dart';
import '../../app.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.binlinkColors;
    final typography = context.binlinkTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: typography.bodySmall.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _isFocused ? colors.primary : colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: _isFocused ? colors.surface : colors.divider,
            borderRadius: AppRadius.mdBR,
            border: Border.all(
              color: _isFocused ? colors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: typography.bodyLarge,
            validator: widget.validator,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: typography.bodyLarge.copyWith(color: colors.textMuted),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ),
      ],
    );
  }
}
