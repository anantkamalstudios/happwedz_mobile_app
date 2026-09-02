import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../models/shaadi_ai_models.dart';

/// Renders the optional result blocks a [ShaadiChatMessage] can carry —
/// budget breakdown, vendor cards, order cards, product cards, comparison
/// cards and suggestion pills, in that fixed order — below the message's
/// plain-text content (which the caller renders separately).
///
/// Pure presentation: navigation, external links and re-sending a suggestion
/// as a new message are all decisions the caller makes via the callbacks.
class ShaadiMessageResults extends StatelessWidget {
  const ShaadiMessageResults({
    super.key,
    required this.message,
    required this.onVendorTap,
    required this.onProductTap,
  });

  final ShaadiChatMessage message;
  final void Function(String vendorId) onVendorTap;
  final void Function(String url) onProductTap;

  @override
  Widget build(BuildContext context) {
    if (!message.hasResults) return const SizedBox.shrink();

    final blocks = <Widget>[];

    if (message.budgetBreakdown.isNotEmpty) {
      blocks.add(_BudgetBreakdownCard(breakdown: message.budgetBreakdown));
    }

    if (message.vendors.isNotEmpty) {
      blocks.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withGaps(
            [
              for (final vendor in message.vendors)
                _VendorCard(vendor: vendor, onTap: onVendorTap),
            ],
            AppSpacing.h8,
          ),
        ),
      );
    }

    if (message.orders.isNotEmpty) {
      blocks.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withGaps(
            [for (final order in message.orders) _OrderCard(order: order)],
            AppSpacing.h8,
          ),
        ),
      );
    }

    if (message.products.isNotEmpty) {
      blocks.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withGaps(
            [
              for (final product in message.products)
                _ProductCard(product: product, onTap: onProductTap),
            ],
            AppSpacing.h8,
          ),
        ),
      );
    }

    if (message.comparisons.isNotEmpty) {
      blocks.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withGaps(
            [
              for (final comparison in message.comparisons)
                _ComparisonCard(comparison: comparison),
            ],
            AppSpacing.h8,
          ),
        ),
      );
    }

    if (message.suggestions.isNotEmpty) {
      blocks.add(_SuggestionPills(suggestions: message.suggestions));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _withGaps(blocks, AppSpacing.h12),
    );
  }
}

List<Widget> _withGaps(List<Widget> items, Widget gap) {
  if (items.isEmpty) return items;
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if (i != items.length - 1) result.add(gap);
  }
  return result;
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

/// Small colored pill used for order status and out-of-stock flags.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.rPill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Small blush pill used for a vendor's `whyRecommended` reasons and a
/// product's `reasons`.
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: AppRadii.rPill,
      ),
      child: Text(text, style: AppText.caption.copyWith(color: AppColors.textSecondary)),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Budget breakdown
// ---------------------------------------------------------------------------

class _BudgetBreakdownCard extends StatelessWidget {
  const _BudgetBreakdownCard({required this.breakdown});

  final Map<String, double> breakdown;

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, size: 18, color: AppColors.primary),
              AppSpacing.w8,
              Text('Budget Breakdown', style: AppText.cardTitle),
            ],
          ),
          AppSpacing.h12,
          for (var i = 0; i < entries.length; i++) ...[
            if (i != 0) ...[
              AppSpacing.h8,
              const Divider(height: 1),
              AppSpacing.h8,
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    entries[i].key,
                    style: AppText.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatBudgetAmount(entries[i].value),
                  style: AppText.bodyStrong.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Vendor cards
// ---------------------------------------------------------------------------

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor, required this.onTap});

  final ShaadiVendor vendor;
  final void Function(String vendorId) onTap;

  /// The backend sometimes omits `vendor_id` on a recommendation it can't
  /// resolve to a listing — those cards render as plain info, not a link.
  bool get _tappable => vendor.vendorId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      vendor.category,
      vendor.location,
    ].where((s) => s.isNotEmpty).join(' · ');

    return AppCard(
      onTap: _tappable ? () => onTap(vendor.vendorId) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: AppText.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      AppSpacing.h4,
                      Text(
                        subtitle,
                        style: AppText.cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (vendor.priceRange.isNotEmpty) ...[
                AppSpacing.w8,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSurface,
                    borderRadius: AppRadii.rPill,
                  ),
                  child: Text(
                    vendor.priceRange,
                    style: AppText.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (vendor.whyRecommended.isNotEmpty) ...[
            AppSpacing.h12,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final reason in vendor.whyRecommended) _ReasonChip(text: reason),
              ],
            ),
          ],
          if (_tappable) ...[
            AppSpacing.h12,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to view',
                  style: AppText.labelSm.copyWith(color: AppColors.primary),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Order cards
// ---------------------------------------------------------------------------

class _OrderStatusStyle {
  const _OrderStatusStyle(this.label, this.color);

  final String label;
  final Color color;
}

/// Mirrors `_shopStatusFor` in `lib/my_bookings/my_bookings.dart` — same
/// PENDING/PROCESSING/DELIVERED/CANCEL(LED) mapping — kept local since that
/// function is private to the other file.
_OrderStatusStyle _shaadiOrderStatus(String raw) {
  final value = raw.trim().toUpperCase();
  switch (value) {
    case 'PENDING':
      return const _OrderStatusStyle('Pending', AppColors.warning);
    case 'PROCESSING':
      return const _OrderStatusStyle('Processing', AppColors.info);
    case 'DELIVERED':
      return const _OrderStatusStyle('Delivered', AppColors.success);
    case 'CANCEL':
    case 'CANCELLED':
    case 'CANCELED':
      return const _OrderStatusStyle('Cancelled', AppColors.error);
    default:
      return _OrderStatusStyle(
        value.isEmpty ? 'Unknown' : value,
        AppColors.textTertiary,
      );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ShaadiOrder order;

  @override
  Widget build(BuildContext context) {
    final status = _shaadiOrderStatus(order.status);
    final firstImage = order.items.isNotEmpty ? order.items.first.image : '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.rSm,
                child: firstImage.isNotEmpty
                    ? NetworkImageWidget(url: firstImage, width: 56, height: 56)
                    : Container(
                        width: 56,
                        height: 56,
                        color: AppColors.pinkSurface,
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.invoice.isNotEmpty ? 'Order #${order.invoice}' : 'Order',
                      style: AppText.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.h4,
                    Text(
                      '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                      style: AppText.cardSubtitle,
                    ),
                  ],
                ),
              ),
              AppSpacing.w8,
              _StatusPill(label: status.label, color: status.color),
            ],
          ),
          AppSpacing.h12,
          const Divider(height: 1),
          AppSpacing.h8,
          Row(
            children: [
              Text('Total', style: AppText.label),
              const Spacer(),
              Text(formatBudgetAmount(order.total), style: AppText.price),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Product cards
// ---------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ShaadiProduct product;
  final void Function(String url) onTap;

  bool get _tappable => product.url.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: _tappable ? () => onTap(product.url) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.rSm,
                child: NetworkImageWidget(url: product.image, width: 64, height: 64),
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.category.isNotEmpty)
                      Text(product.category.toUpperCase(), style: AppText.overline),
                    Text(
                      product.title,
                      style: AppText.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.h4,
                    Row(
                      children: [
                        Text(formatBudgetAmount(product.price), style: AppText.priceSm),
                        if (product.originalPrice > product.price) ...[
                          AppSpacing.w8,
                          Text(
                            formatBudgetAmount(product.originalPrice),
                            style: AppText.caption.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!product.inStock) ...[
                      AppSpacing.h8,
                      const _StatusPill(label: 'Out of stock', color: AppColors.error),
                    ],
                  ],
                ),
              ),
              if (_tappable) ...[
                AppSpacing.w8,
                const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textTertiary),
              ],
            ],
          ),
          if (product.reasons.isNotEmpty) ...[
            AppSpacing.h12,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final reason in product.reasons) _ReasonChip(text: reason),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Comparison cards
// ---------------------------------------------------------------------------

class _ComparisonField extends StatelessWidget {
  const _ComparisonField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          Text(value, style: AppText.bodySm.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ComparisonSideColumn extends StatelessWidget {
  const _ComparisonSideColumn({required this.side});

  final ShaadiComparisonSide side;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          side.name,
          style: AppText.bodyStrong,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        AppSpacing.h8,
        _ComparisonField(label: 'Price', value: side.price),
        _ComparisonField(label: 'Capacity', value: side.capacity),
        _ComparisonField(label: 'Indoor/Outdoor', value: side.indoorOutdoor),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison});

  final ShaadiComparison comparison;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, size: 18, color: AppColors.primary),
              AppSpacing.w8,
              Text('Comparison', style: AppText.cardTitle),
            ],
          ),
          AppSpacing.h12,
          LayoutBuilder(
            builder: (context, constraints) {
              final sideA = _ComparisonSideColumn(side: comparison.vendor1);
              final sideB = _ComparisonSideColumn(side: comparison.vendor2);

              if (constraints.maxWidth < 320) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    sideA,
                    AppSpacing.h12,
                    const Divider(height: 1),
                    AppSpacing.h12,
                    sideB,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: sideA),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: VerticalDivider(width: 1),
                    ),
                    Expanded(child: sideB),
                  ],
                ),
              );
            },
          ),
          if (comparison.recommendation.isNotEmpty) ...[
            AppSpacing.h12,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.pinkSurface,
                borderRadius: AppRadii.rMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      AppSpacing.w8,
                      Text(
                        'Recommendation',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h4,
                  Text(
                    comparison.recommendation,
                    style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Suggestion pills
// ---------------------------------------------------------------------------

/// AUDIT FIX: the React source renders these as plain, non-interactive
/// callouts (`suggestionAlert`, no `onClick`) — not tappable chips. Matched
/// here exactly rather than inventing a tap affordance the source doesn't
/// have.
class _SuggestionPills extends StatelessWidget {
  const _SuggestionPills({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.blush,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '✨ $suggestion',
                style: AppText.labelSm.copyWith(color: AppColors.primaryDark),
              ),
            ),
          ),
      ],
    );
  }
}
