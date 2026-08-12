/// Shared presentational pieces for the Honeymoon module.
///
/// Everything here builds on the app design system in `lib/core` — no new
/// button, card, image or state widget is introduced.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../honeymoon_config.dart';

// ---------------------------------------------------------------------------
// Service tabs
// ---------------------------------------------------------------------------

/// The four services the backend actually supports.
enum HoneymoonService { hotels, flights, insurance, carRental }

extension HoneymoonServiceX on HoneymoonService {
  String get label => switch (this) {
    HoneymoonService.hotels => 'Hotels',
    HoneymoonService.flights => 'Flights',
    HoneymoonService.insurance => 'Insurance',
    HoneymoonService.carRental => 'Car Rental',
  };

  IconData get icon => switch (this) {
    HoneymoonService.hotels => Icons.hotel_rounded,
    HoneymoonService.flights => Icons.flight_takeoff_rounded,
    HoneymoonService.insurance => Icons.shield_outlined,
    HoneymoonService.carRental => Icons.directions_car_filled_outlined,
  };
}

/// Glass pill navigation overlaid on the hero. Scrolls horizontally so it can
/// never overflow, however narrow the device.
class HoneymoonServiceTabs extends StatelessWidget {
  const HoneymoonServiceTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    this.services = HoneymoonService.values,
  });

  final HoneymoonService selected;
  final ValueChanged<HoneymoonService> onSelected;
  final List<HoneymoonService> services;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final service = services[i];
          final isSelected = service == selected;

          return Pressable(
            onTap: () => onSelected(service),
            borderRadius: AppRadii.rPill,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.14),
                borderRadius: AppRadii.rPill,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    service.icon,
                    size: 17,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    service.label,
                    style: AppText.buttonSm.copyWith(
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

/// Full-bleed romantic header with scrim, copy and the trust strip.
class HoneymoonHero extends StatelessWidget {
  const HoneymoonHero({super.key, required this.child, this.onBack});

  /// The service tabs, rendered inside the hero under the copy.
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: NetworkImageWidget(
            url: HoneymoonConfig.heroImageUrl,
            fit: BoxFit.cover,
            backgroundColor: AppColors.primaryDeep,
          ),
        ),

        // Scrim — keeps white type readable over any photo.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Color(0x66000000), Color(0xE6000000)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: AppBackButton(
                  color: AppColors.textOnPrimary,
                  background: Colors.white.withValues(alpha: 0.18),
                  onTap: onBack,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        HoneymoonConfig.heroTitle,
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        HoneymoonConfig.heroSubtitle,
                        style: AppText.body.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              const _HeroStats(),
              const SizedBox(height: AppSpacing.lg),
              child,
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FadeSlideIn(
        delay: AppMotion.stagger,
        child: Row(
          children: [
            for (var i = 0; i < HoneymoonConfig.heroStats.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 26,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  color: Colors.white24,
                ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      HoneymoonConfig.heroStats[i].value,
                      style: AppText.sectionTitle.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      HoneymoonConfig.heroStats[i].label,
                      style: AppText.caption.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search-card building blocks
// ---------------------------------------------------------------------------

/// The white rounded card the search forms sit inside.
class HoneymoonSearchCard extends StatelessWidget {
  const HoneymoonSearchCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadowLg,
      ),
      child: child,
    );
  }
}

/// Uppercase field label used across every search form.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
      child: Text(text.toUpperCase(), style: AppText.overline),
    );
  }
}

/// A read-only tappable field — used for dates and the traveller sheet.
class TapField extends StatelessWidget {
  const TapField({
    super.key,
    required this.icon,
    required this.value,
    required this.onTap,
    this.placeholder = 'Select',
    this.errorText,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String placeholder;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    final hasError = (errorText ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Pressable(
          onTap: onTap,
          borderRadius: AppRadii.rMd,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadii.rMd,
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    hasValue ? value : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hasValue
                        ? AppText.bodyStrong
                        : AppText.body.copyWith(
                            color: AppColors.textTertiary,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs, left: 2),
            child: Text(errorText!, style: AppText.error),
          ),
      ],
    );
  }
}

/// Stepper row used inside the traveller sheet.
class CounterRow extends StatelessWidget {
  const CounterRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 12,
  });

  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.bodyStrong),
              Text(subtitle, style: AppText.caption),
            ],
          ),
        ),
        _StepButton(
          icon: Icons.remove_rounded,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppText.sectionTitle,
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.pinkSurface : AppColors.background,
          border: Border.all(
            color: enabled ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? AppColors.primary : AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// Small pill used for facilities, inclusions and similar metadata.
class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.rSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `14 Aug 2026` — display only; the API layer does its own formatting.
String formatTripDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

/// `₹89,999` / `₹1,24,500` — Indian grouping: last three digits, then pairs.
String formatPrice(double amount, {String symbol = '₹'}) {
  final negative = amount < 0;
  final digits = amount.abs().round().toString();

  late final String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final lastThree = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);

    // Walk the remainder right-to-left in pairs.
    final pairs = <String>[];
    var i = rest.length;
    while (i > 2) {
      pairs.insert(0, rest.substring(i - 2, i));
      i -= 2;
    }
    if (i > 0) pairs.insert(0, rest.substring(0, i));

    grouped = '${pairs.join(',')},$lastThree';
  }

  return '${negative ? '-' : ''}$symbol$grouped';
}