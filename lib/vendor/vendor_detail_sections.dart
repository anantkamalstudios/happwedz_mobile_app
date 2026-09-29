import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/core.dart';
import 'vendor_listing_utils.dart' show VendorFaq;

// Sections of the vendor detail page that the website has and the app lacked
// (src/components/layouts/Detailed.jsx): Pricing & Packages, the Available
// Dates calendar, the attribute-derived FAQ, Similar vendors, and the full
// review list / full-review sheet.

bool _has(Object? v) {
  final s = (v ?? '').toString().trim();
  return s.isNotEmpty && s.toLowerCase() != 'null';
}

String _inr(Object? raw) {
  final digits = (raw ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
  final n = int.tryParse(digits) ?? 0;
  return NumberFormat.decimalPattern('en_IN').format(n);
}

// ---------------------------------------------------------------------------
// Pricing & Packages (Detailed.jsx `pricingDetails`, ~6819-7990)
// ---------------------------------------------------------------------------

/// The listing's pricing block: description, base package price with
/// "Request Quote", and the rate-card brochure (image or PDF).
class VendorPricingDetails {
  VendorPricingDetails._({
    required this.description,
    required this.brochureName,
    required this.brochureUrl,
    required this.brochureBase64,
    required this.startingPrice,
  });

  factory VendorPricingDetails.of(Map service) {
    final attrs = service['attributes'] is Map ? service['attributes'] as Map : const {};
    Object? pick(String k) => _has(attrs[k]) ? attrs[k] : service[k];
    return VendorPricingDetails._(
      description: _has(pick('pricing_description'))
          ? pick('pricing_description').toString()
          : '',
      brochureName: _has(pick('pricing_brochure_name'))
          ? pick('pricing_brochure_name').toString()
          : null,
      brochureUrl: _has(pick('pricing_brochure_url'))
          ? pick('pricing_brochure_url').toString()
          : null,
      brochureBase64: _has(pick('pricing_brochure_base64'))
          ? pick('pricing_brochure_base64').toString()
          : null,
      startingPrice: _has(pick('starting_price')) ? pick('starting_price') : null,
    );
  }

  final String description;
  final String? brochureName;
  final String? brochureUrl;
  final String? brochureBase64;
  final Object? startingPrice;

  static final _imageExt = RegExp(r'\.(jpg|jpeg|png|webp|gif)$', caseSensitive: false);

  bool get isImage =>
      (brochureBase64?.startsWith('data:image') ?? false) ||
      (brochureUrl != null && _imageExt.hasMatch(brochureUrl!)) ||
      (brochureName != null && _imageExt.hasMatch(brochureName!));

  bool get isPdf => brochureName?.toLowerCase().endsWith('.pdf') ?? false;

  /// A data: URL or a hosted URL for the brochure image.
  String? get imageSrc => (brochureBase64?.startsWith('data:image') ?? false)
      ? brochureBase64
      : brochureUrl;

  bool get hasBrochure => imageSrc != null || brochureName != null;

  bool get hasAny =>
      description.isNotEmpty || imageSrc != null || brochureName != null ||
      startingPrice != null;
}

class VendorPricingSection extends StatelessWidget {
  const VendorPricingSection({
    super.key,
    required this.details,
    required this.onRequestQuote,
  });

  final VendorPricingDetails details;

  /// Opens the Request Pricing form, as the website's "Request Quote" and
  /// "Request PDF Copy" buttons do.
  final VoidCallback onRequestQuote;

  @override
  Widget build(BuildContext context) {
    final d = details;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: 'Pricing & Packages',
          subtitle: 'Pricing plans & brochures',
          accent: true,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard.outlined(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.description.isNotEmpty
                    ? 'Package Overview & Pricing Details'
                    : 'Pricing Information',
                style: AppText.bodyStrong,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                d.description.isNotEmpty
                    ? d.description
                    : 'Contact this vendor for customized pricing plans, '
                        'package inclusions, and date availability.',
                style: AppText.bodySm.copyWith(height: 1.6),
              ),
              if (d.startingPrice != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSurface,
                    borderRadius: AppRadii.rMd,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Base Package Starting At', style: AppText.caption),
                            Text('₹ ${_inr(d.startingPrice)}', style: AppText.price),
                          ],
                        ),
                      ),
                      PremiumButton(
                        label: 'Request Quote',
                        size: PremiumButtonSize.small,
                        // Inside a Row: the default expanded:true asks for
                        // infinite width and the rest of the page vanished.
                        expanded: false,
                        onPressed: onRequestQuote,
                      ),
                    ],
                  ),
                ),
              ],
              if (d.hasBrochure) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Rate Card & Brochure', style: AppText.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                _Brochure(details: d, onRequest: onRequestQuote),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Brochure extends StatelessWidget {
  const _Brochure({required this.details, required this.onRequest});

  final VendorPricingDetails details;
  final VoidCallback onRequest;

  Widget _image(String src, {BoxFit fit = BoxFit.cover}) {
    if (src.startsWith('data:image')) {
      try {
        return Image.memory(base64Decode(src.split(',').last), fit: fit);
      } catch (_) {
        return const Icon(Icons.broken_image_outlined);
      }
    }
    return NetworkImageWidget(url: src, fit: fit, width: double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final d = details;
    final name = d.brochureName ?? 'Pricing Brochure';
    if (d.isImage && d.imageSrc != null) {
      return Pressable(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(name, style: const TextStyle(color: Colors.white)),
              ),
              body: InteractiveViewer(
                maxScale: 5,
                child: Center(child: _image(d.imageSrc!, fit: BoxFit.contain)),
              ),
            ),
          ),
        ),
        borderRadius: AppRadii.rMd,
        child: ClipRRect(
          borderRadius: AppRadii.rMd,
          child: SizedBox(height: 180, width: double.infinity, child: _image(d.imageSrc!)),
        ),
      );
    }
    final url = d.brochureUrl;
    return Row(
      children: [
        const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(name, style: AppText.bodySm, maxLines: 2, overflow: TextOverflow.ellipsis)),
        PremiumButton.text(
          label: url != null ? 'Download PDF →' : 'Request PDF Copy →',
          size: PremiumButtonSize.small,
          onPressed: url != null
              ? () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
              : onRequest,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Available Dates (Detailed.jsx buildAvailabilityMonths + ~8540)
// ---------------------------------------------------------------------------

/// Future `available_slots` dates as `yyyy-MM-dd`, sorted — empty when the
/// vendor switched availability off (`availabilityActive === false`).
List<String> upcomingAvailableDates(Map service, {DateTime? now}) {
  if (service['availabilityActive'] == false) return const [];
  final attrs = service['attributes'] is Map ? service['attributes'] as Map : const {};
  final raw = attrs['available_slots'] ?? attrs['availableSlots'];
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final out = <String>{};
  if (raw is List) {
    for (final slot in raw) {
      final s = (slot is Map ? slot['date'] : slot)?.toString() ?? '';
      final d = DateTime.tryParse(s.split('T').first);
      if (d != null && !d.isBefore(today)) {
        out.add(DateFormat('yyyy-MM-dd').format(d));
      }
    }
  }
  return out.toList()..sort();
}

/// View-only month calendar of the vendor's open dates, paging through the
/// months that contain one (max 12), like the website's "Available Dates".
class VendorAvailabilityCalendar extends StatefulWidget {
  const VendorAvailabilityCalendar({super.key, required this.dates});

  /// `yyyy-MM-dd`, sorted, future only (see [upcomingAvailableDates]).
  final List<String> dates;

  @override
  State<VendorAvailabilityCalendar> createState() =>
      _VendorAvailabilityCalendarState();
}

class _VendorAvailabilityCalendarState extends State<VendorAvailabilityCalendar> {
  int _index = 0;

  List<DateTime> get _months {
    final keys = <String>[];
    for (final d in widget.dates) {
      final k = d.substring(0, 7);
      if (!keys.contains(k)) keys.add(k);
    }
    keys.sort();
    return keys.take(12).map((k) {
      final p = k.split('-').map(int.parse).toList();
      return DateTime(p[0], p[1]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final months = _months;
    if (months.isEmpty) return const SizedBox.shrink();
    final m = months[_index.clamp(0, months.length - 1)];
    final available = widget.dates.toSet();
    final daysInMonth = DateUtils.getDaysInMonth(m.year, m.month);
    final lead = DateTime(m.year, m.month, 1).weekday % 7; // Sunday first
    final hasPrev = _index > 0;
    final hasNext = _index < months.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text('Available Dates', style: AppText.sectionTitle)),
            Text(
              '${months.length} ${months.length == 1 ? 'Month' : 'Months'}',
              style: AppText.labelSm,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard.outlined(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous Month',
                    onPressed: hasPrev ? () => setState(() => _index--) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(m),
                      textAlign: TextAlign.center,
                      style: AppText.bodyStrong,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next Month',
                    onPressed: hasNext ? () => setState(() => _index++) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final w in const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
                    Expanded(
                      child: Center(child: Text(w, style: AppText.caption)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                  for (var day = 1; day <= daysInMonth; day++)
                    Builder(builder: (_) {
                      final key = DateFormat('yyyy-MM-dd')
                          .format(DateTime(m.year, m.month, day));
                      final open = available.contains(key);
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: open ? AppColors.successDark : null,
                          borderRadius: AppRadii.rSm,
                        ),
                        child: Text(
                          '$day',
                          style: AppText.caption.copyWith(
                            color: open ? Colors.white : AppColors.textTertiary,
                            fontWeight: open ? FontWeight.w700 : null,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FAQ (VenueFAQ.jsx)
// ---------------------------------------------------------------------------

class VendorFaqSection extends StatefulWidget {
  const VendorFaqSection({super.key, required this.title, required this.faqs});

  /// "Frequently Asked Questions about {name}" (`vendorFaqTitle`).
  final String title;

  /// As built by `vendorFaqs()`.
  final List<VendorFaq> faqs;

  @override
  State<VendorFaqSection> createState() => _VendorFaqSectionState();
}

class _VendorFaqSectionState extends State<VendorFaqSection> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: widget.title,
          accent: true,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < widget.faqs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard.outlined(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Pressable(
                    onTap: () => setState(() => _open = _open == i ? null : i),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(widget.faqs[i].question, style: AppText.bodyStrong),
                          ),
                          Icon(
                            _open == i ? Icons.remove_rounded : Icons.add_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_open == i)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(widget.faqs[i].answer, style: AppText.bodySm),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Similar vendors (SimilarServices.jsx)
// ---------------------------------------------------------------------------

class SimilarVendorsSection extends StatelessWidget {
  const SimilarVendorsSection({
    super.key,
    required this.title,
    required this.items,
    required this.imageOf,
    required this.nameOf,
    required this.cityOf,
    required this.priceOf,
    required this.onTap,
  });

  final String title;
  final List<Map> items;
  final String Function(Map) imageOf;
  final String Function(Map) nameOf;
  final String Function(Map) cityOf;
  final String Function(Map) priceOf;
  final void Function(Map) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(title: title, accent: true, padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final item = items[i];
              final city = cityOf(item);
              return SizedBox(
                width: 200,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  onTap: () => onTap(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NetworkImageWidget(
                        url: imageOf(item),
                        height: 120,
                        width: double.infinity,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadii.lg),
                        ),
                        memCacheWidth: 420,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(nameOf(item), style: AppText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (city.isNotEmpty)
                              Text(city, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(priceOf(item), style: AppText.priceSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reviews: "Show all n reviews" list and the full-review sheet
// (ReviewSection.jsx — 6 shown, comments cut at 180 chars with "Show more")
// ---------------------------------------------------------------------------

const Map<String, String> reviewCategoryLabels = {
  'quality': 'Quality of service',
  'responsiveness': 'Responsiveness',
  'professionalism': 'Professionalism',
  'value': 'Value',
  'flexibility': 'Flexibility',
};

String reviewDate(Object? raw) {
  final d = DateTime.tryParse((raw ?? '').toString());
  return d == null ? '' : DateFormat('d MMM yyyy').format(d.toLocal());
}

/// Full review: every category rating, the whole comment, photos and the
/// vendor's reply.
void showFullReviewSheet(BuildContext context, Map<String, dynamic> review) {
  final media = (review['media'] is List ? review['media'] as List : const [])
      .map((e) => e.toString())
      .toList();
  final categories = review['categories'] is Map
      ? Map<String, double>.from(review['categories'] as Map)
      : const <String, double>{};
  AppBottomSheet.show(
    context,
    title: (review['userName'] ?? 'Guest').toString(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_has(review['createdAt']))
          Text(reviewDate(review['createdAt']), style: AppText.caption),
        for (final e in reviewCategoryLabels.entries)
          if ((categories[e.key] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text(e.value, style: AppText.bodySm)),
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= (categories[e.key] ?? 0).round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                ],
              ),
            ),
        if (_has(review['title'])) ...[
          const SizedBox(height: AppSpacing.md),
          Text(review['title'].toString(), style: AppText.bodyStrong),
        ],
        if (_has(review['comment'])) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(review['comment'].toString(), style: AppText.bodySm),
        ],
        if (media.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => NetworkImageWidget(
                url: media[i],
                width: 90,
                height: 90,
                radius: AppRadii.md,
              ),
            ),
          ),
        ],
        if (_has(review['vendorReply'])) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadii.rSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Response from the owner',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(review['vendorReply'].toString(), style: AppText.bodySm),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    ),
  );
}

/// Every review, reached from "Show all n reviews".
class AllReviewsPage extends StatelessWidget {
  const AllReviewsPage({
    super.key,
    required this.vendorName,
    required this.reviews,
    required this.tileBuilder,
  });

  final String vendorName;
  final List<Map<String, dynamic>> reviews;
  final Widget Function(Map<String, dynamic>) tileBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Reviews of $vendorName', style: AppText.pageTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: reviews.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => tileBuilder(reviews[i]),
      ),
    );
  }
}
