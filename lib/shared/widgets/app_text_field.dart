import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

/// BinLink text field — Rydr CustomTextFieldWidget pattern with improvements.
///
/// Rydr bugs fixed:
///  - No label support → added
///  - No validator → added
///  - No obscure text toggle → added
///  - No focused fill state → added (AppColors.fieldFillFocused)
///  - Hardcoded radius → AppRadius.field (9px matches Rydr)
///  - No autofillHints → added
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.showToggle = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  /// When true and [showToggle] is true, renders an eye toggle button.
  final bool obscureText;
  /// Shows a password visibility toggle when [obscureText] is true.
  final bool showToggle;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;
  bool _focused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.label),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofillHints: widget.autofillHints,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            // Rydr field pattern: explicit fill colours per focus state
            filled: true,
            fillColor: _focused
                ? AppColors.fieldFillFocused
                : AppColors.fieldFill,
            prefixIcon: widget.prefixIcon,
            // Suffix: either custom suffix OR eye toggle if password field
            suffixIcon: widget.showToggle && widget.obscureText
                ? GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  )
                : widget.suffixIcon,
            // Rydr radius = 9px (AppRadius.field)
            border: OutlineInputBorder(
              borderRadius: AppRadius.fieldBR,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.fieldBR,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.fieldBR,
              borderSide: const BorderSide(color: AppColors.borderActive, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.fieldBR,
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.fieldBR,
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ── OTP digit field ────────────────────────────────────────────────────────────

class OtpField extends StatelessWidget {
  const OtpField({
    super.key,
    required this.controller,
    this.onCompleted,
  });

  final TextEditingController controller;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: AppTextStyles.monoLg.copyWith(letterSpacing: 12),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: AppColors.fieldFill,
        hintText: '••••••',
        hintStyle: AppTextStyles.monoLg.copyWith(
          color: AppColors.muted,
          letterSpacing: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldBR,
          borderSide: const BorderSide(color: AppColors.borderActive, width: 1.5),
        ),
      ),
      onChanged: (v) {
        if (v.length == 6) onCompleted?.call();
      },
    );
  }
}
