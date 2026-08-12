import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The app's text input.
///
/// Wraps [TextFormField] so validation, focus styling, error text and the
/// password visibility toggle behave the same everywhere. All standard
/// TextFormField hooks (controller, validator, onChanged, …) are passed
/// through unchanged so existing form logic keeps working.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.prefix,
    this.required = false,
    this.fillColor,
  });

  final TextEditingController? controller;

  /// Label rendered above the field (not a floating label — keeps row height
  /// stable and avoids jumpy layouts).
  final String? label;
  final String? hint;
  final String? helperText;

  /// External error message. When null, [validator] drives the error state.
  final String? errorText;

  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  /// When true renders a password field with a visibility toggle.
  final bool obscureText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  /// Arbitrary leading widget (e.g. a country-code selector).
  final Widget? prefix;

  /// Shows a subtle asterisk next to the label.
  final bool required;

  final Color? fillColor;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _ownsFocusNode = false;
  bool _obscured = true;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final disabled = !widget.enabled;

    final Color borderColor = hasError
        ? AppColors.error
        : _focused
            ? AppColors.primary
            : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
            child: RichText(
              text: TextSpan(
                text: widget.label,
                style: AppText.formLabel.copyWith(
                  color: disabled
                      ? AppColors.textTertiary
                      : _focused
                          ? AppColors.primary
                          : AppColors.textSecondary,
                ),
                children: widget.required
                    ? [
                        TextSpan(
                          text: ' *',
                          style: AppText.formLabel
                              .copyWith(color: AppColors.error),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            boxShadow: _focused && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText && _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            autofocus: widget.autofocus,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            cursorColor: AppColors.primary,
            style: AppText.body.copyWith(
              color: disabled ? AppColors.textTertiary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
              errorText: widget.errorText,
              helperText: widget.helperText,
              helperStyle: AppText.caption,
              errorStyle: AppText.error,
              counterText: '',
              filled: true,
              fillColor: disabled
                  ? AppColors.background
                  : widget.fillColor ?? Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null || widget.prefix != null
                    ? AppSpacing.md
                    : AppSpacing.lg,
                vertical: (widget.maxLines ?? 1) > 1 ? AppSpacing.lg : 15,
              ),
              prefixIcon: widget.prefix ??
                  (widget.prefixIcon == null
                      ? null
                      : Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: _focused
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        )),
              prefixIconConstraints: widget.prefix != null
                  ? const BoxConstraints(minWidth: 0, minHeight: 0)
                  : null,
              suffixIcon: _buildSuffix(),
              border: _border(AppColors.divider),
              enabledBorder: _border(borderColor),
              focusedBorder: _border(AppColors.primary, width: 1.4),
              errorBorder: _border(AppColors.error),
              focusedErrorBorder: _border(AppColors.error, width: 1.4),
              disabledBorder: _border(AppColors.divider),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        splashRadius: 20,
        icon: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Icon(
            _obscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey(_obscured),
            size: 20,
            color: AppColors.textTertiary,
          ),
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Show password' : 'Hide password',
      );
    }
    if (widget.suffixIcon != null) {
      final icon = Icon(
        widget.suffixIcon,
        size: 20,
        color: _focused ? AppColors.primary : AppColors.textTertiary,
      );
      if (widget.onSuffixTap == null) {
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: icon,
        );
      }
      return IconButton(
        splashRadius: 20,
        icon: icon,
        onPressed: widget.onSuffixTap,
      );
    }
    return null;
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadii.rMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
