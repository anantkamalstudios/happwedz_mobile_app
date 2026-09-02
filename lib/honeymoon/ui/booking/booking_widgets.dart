/// The mobile booking kit shared by the four Honeymoon funnels.
///
/// The web client lays a booking out as a two-column page: form on the left,
/// a fare summary pinned in a right-hand rail. Neither half fits a phone, so
/// the same information is re-arranged rather than shrunk:
///
/// ```
/// desktop rail      → sticky bottom bar (total + action), tap to expand
/// desktop stepper   → compact numbered step bar under the app bar
/// desktop table     → stacked cards
/// desktop modal     → bottom sheet
/// ```
///
/// Everything here is built to survive a 320 px width, a 1.2× text scale and
/// an open keyboard without a single overflow.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../models/booking_models.dart';
import '../widgets/honeymoon_widgets.dart';

// ---------------------------------------------------------------------------
// Step bar
// ---------------------------------------------------------------------------

/// The compact numbered progress bar under the app bar.
///
/// Steps share the width evenly and their labels are allowed to ellipsise, so
/// four steps still fit at 320 px instead of pushing the row off-screen.
class BookingStepBar extends StatelessWidget {
  const BookingStepBar({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
  });

  /// The height this bar needs, worst case.
  ///
  /// It goes into `AppBar.bottom`, which gives a child *exactly* its declared
  /// height — so this is published rather than guessed at the call site, and
  /// it allows for the 1.2x text scale the app clamps to:
  /// 6 top + 26 circle row + 4 gap + ~20 label + 10 bottom.
  static const double height = 74;

  final List<String> steps;

  /// Zero-based.
  final int currentStep;

  /// Supplied only for steps already completed — a traveller may go back to
  /// edit, never forward past validation.
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        6,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: _Step(
                index: i,
                label: steps[i],
                isFirst: i == 0,
                isLast: i == steps.length - 1,
                isDone: i < currentStep,
                isCurrent: i == currentStep,
                onTap: i < currentStep && onStepTapped != null
                    ? () => onStepTapped!(i)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.isDone,
    required this.isCurrent,
    this.onTap,
  });

  final int index;
  final String label;
  final bool isFirst;
  final bool isLast;
  final bool isDone;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = isDone || isCurrent;
    final circleColor = active ? AppColors.primary : AppColors.divider;

    return Semantics(
      label: 'Step ${index + 1}, $label',
      selected: isCurrent,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rSm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  // Half-width connectors on each side keep the circles
                  // centred over their labels at any width.
                  Expanded(
                    child: isFirst
                        ? const SizedBox.shrink()
                        : _Connector(filled: active),
                  ),
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppText.labelSm.copyWith(
                              color: active
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  Expanded(
                    child: isLast
                        ? const SizedBox.shrink()
                        : _Connector(filled: isDone),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.labelSm.copyWith(
                color: active ? AppColors.textPrimary : AppColors.textTertiary,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    height: 2,
    color: filled ? AppColors.primary : AppColors.divider,
  );
}

// ---------------------------------------------------------------------------
// Sticky action bar
// ---------------------------------------------------------------------------

/// The bottom bar that replaces the web's fare rail.
///
/// The total stays visible on every step and the breakdown is one tap away in
/// a sheet, so the traveller never has to scroll to find out what they are
/// about to pay.
class BookingActionBar extends StatelessWidget {
  const BookingActionBar({
    super.key,
    required this.actionLabel,
    required this.onAction,
    this.fare,
    this.priceLabel = 'Total',
    this.isLoading = false,
    this.enabled = true,
    this.onShowBreakdown,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String actionLabel;
  final VoidCallback? onAction;
  final FareBreakdown? fare;
  final String priceLabel;
  final bool isLoading;
  final bool enabled;

  /// Opens the fare breakdown sheet. Omitted when there is nothing to break
  /// down, which also hides the affordance rather than showing a dead chevron.
  final VoidCallback? onShowBreakdown;

  /// An optional second action (e.g. "Hold fare"), rendered above the primary
  /// one so neither button is ever squeezed below a comfortable tap target.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final hasFare = fare != null && !fare!.isEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (secondaryLabel != null) ...[
                PremiumButton.outlined(
                  label: secondaryLabel!,
                  size: PremiumButtonSize.medium,
                  onPressed: isLoading ? null : onSecondary,
                  enabled: enabled,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  if (hasFare) ...[
                    // Capped rather than flexible: a price is short and
                    // bounded, and giving it half the bar was ellipsising
                    // action labels like "Review booking" at 320 px.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 132),
                      child: _FareTrigger(
                        label: priceLabel,
                        total: fare!.total,
                        onTap: onShowBreakdown,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: PremiumButton(
                      label: actionLabel,
                      size: PremiumButtonSize.medium,
                      isLoading: isLoading,
                      enabled: enabled,
                      onPressed: onAction,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FareTrigger extends StatelessWidget {
  const _FareTrigger({
    required this.label,
    required this.total,
    required this.onTap,
  });

  final String label;
  final double total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            Text(
              formatPrice(total),
              style: AppText.price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the fare breakdown as a sheet — the mobile stand-in for the web's
/// always-visible fare rail.
Future<void> showFareBreakdownSheet(
  BuildContext context,
  FareBreakdown fare, {
  String title = 'Fare summary',
  String? footnote,
}) {
  return AppBottomSheet.show<void>(
    context,
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in fare.lines) ...[
          FareRow(line: line),
          const SizedBox(height: AppSpacing.md),
        ],
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: Text('Total payable', style: AppText.bodyStrong)),
            const SizedBox(width: AppSpacing.sm),
            Text(formatPrice(fare.total), style: AppText.price),
          ],
        ),
        if (footnote != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(footnote, style: AppText.caption),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    ),
  );
}

/// One line of a fare breakdown.
class FareRow extends StatelessWidget {
  const FareRow({super.key, required this.line});

  final FareLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(line.label, style: AppText.body),
              if (line.detail.isNotEmpty)
                Text(line.detail, style: AppText.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatPrice(line.amount),
          style: AppText.bodyStrong,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form building blocks
// ---------------------------------------------------------------------------

/// A titled white card. Booking forms are long, and grouping them into cards
/// is what keeps a phone-height scroll navigable.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
    this.trailing,
    this.initiallyExpanded = true,
    this.collapsible = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.blush,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppText.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppText.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    if (!collapsible) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            const SizedBox(height: AppSpacing.lg),
            body,
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        // The default divider lines fight the card border.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: AppRadii.rLg,
          ),
          title: header,
          children: [body],
        ),
      ),
    );
  }
}

/// A read-only field that opens a picker — dates, titles, dialling codes.
///
/// Renders exactly like [AppTextField] so a form mixing typed and picked
/// values still reads as one form.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint = 'Select',
    this.icon = Icons.keyboard_arrow_down_rounded,
    this.errorText,
    this.required = false,
    this.enabled = true,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final String? errorText;
  final bool required;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: AppText.formLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (required)
              Text(' *', style: AppText.formLabel.copyWith(
                color: AppColors.primary,
              )),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.rMd,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: enabled ? AppColors.background : AppColors.divider,
              borderRadius: AppRadii.rMd,
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                Icon(icon, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(errorText!, style: AppText.error),
          ),
      ],
    );
  }
}

/// Picks one value from a short list, in a sheet rather than a dropdown menu —
/// a native menu overlays the keyboard badly on small screens.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  T? selected,
  String Function(T)? subtitleOf,
}) {
  return AppBottomSheet.show<T>(
    context,
    title: title,
    child: ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: options.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, i) {
        final option = options[i];
        final isSelected = option == selected;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            labelOf(option),
            style: isSelected ? AppText.bodyStrong : AppText.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitleOf == null
              ? null
              : Text(
                  subtitleOf(option),
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: isSelected
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 20,
                )
              : null,
          onTap: () => Navigator.pop(context, option),
        );
      },
    ),
  );
}

/// A mobile-friendly phone field: dialling code opens a sheet, the number is
/// digits-only so the numeric keyboard is always the right one.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.label = 'Mobile number',
    this.errorText,
    this.required = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final String label;
  final String? errorText;
  final bool required;

  /// Clears a stale error as soon as the number is corrected — without it the
  /// "enter a valid mobile number" message sits under a valid number until
  /// the next submit.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      required: required,
      hint: '10-digit number',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      errorText: errorText,
      onChanged: onChanged,
      maxLength: 15,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofillHints: const [AutofillHints.telephoneNumberNational],
      prefix: InkWell(
        onTap: () async {
          final picked = await showOptionSheet<({String code, String name})>(
            context,
            title: 'Country code',
            options: kCountryDialCodes,
            labelOf: (c) => '${c.name} (${c.code})',
            selected: kCountryDialCodes
                .where((c) => c.code == countryCode)
                .firstOrNull,
          );
          if (picked != null) onCountryCodeChanged(picked.code);
        },
        borderRadius: AppRadii.rSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(countryCode, style: AppText.bodyStrong),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review helpers
// ---------------------------------------------------------------------------

/// A label/value pair on a review or detail screen.
///
/// The value is allowed to wrap: passport numbers and long addresses would
/// otherwise be truncated exactly where they matter.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.icon,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 15, color: AppColors.textTertiary),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          SizedBox(
            width: 104,
            child: Text(label, style: AppText.caption),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: valueStyle ?? AppText.bodyStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// A short inline notice — required-field warnings, refund rules, hold terms.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = InfoTone.info,
    this.action,
  });

  final String message;
  final IconData icon;
  final InfoTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      InfoTone.info => AppColors.info,
      InfoTone.warning => AppColors.warning,
      InfoTone.error => AppColors.error,
      InfoTone.success => AppColors.successDark,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.rMd,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.bodySm.copyWith(color: AppColors.textDark),
            ),
          ),
          if (action != null) ...[const SizedBox(width: AppSpacing.sm), action!],
        ],
      ),
    );
  }
}

enum InfoTone { info, warning, error, success }

/// Counts a held fare down and calls [onExpire] once.
///
/// Suppliers release an unpaid seat after a few minutes. The web client shows
/// a floating timer; on a phone it lives in the app bar, where it cannot
/// collide with the form.
class SessionCountdown extends StatefulWidget {
  const SessionCountdown({super.key, required this.expiresAt, this.onExpire});

  final DateTime expiresAt;
  final VoidCallback? onExpire;

  @override
  State<SessionCountdown> createState() => _SessionCountdownState();
}

class _SessionCountdownState extends State<SessionCountdown> {
  Timer? _timer;
  late Duration _left;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _remaining();
      setState(() => _left = next);
      if (next <= Duration.zero && !_fired) {
        _fired = true;
        _timer?.cancel();
        widget.onExpire?.call();
      }
    });
  }

  Duration _remaining() {
    final left = widget.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _left.inMinutes.toString().padLeft(2, '0');
    final seconds = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = _left.inMinutes < 2;
    final color = urgent ? AppColors.error : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Center(
        child: Semantics(
          label: 'Fare held for $minutes minutes $seconds seconds',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: AppRadii.rPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: color),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$minutes:$seconds',
                  style: AppText.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The terms line every funnel shows above its pay button.
class TermsNotice extends StatelessWidget {
  const TermsNotice({super.key, this.product = 'booking'});

  final String product;

  @override
  Widget build(BuildContext context) {
    return Text(
      'By continuing you agree to our Terms of Use and Privacy Policy, and to '
      'the $product terms of our travel partner.',
      style: AppText.caption,
    );
  }
}
