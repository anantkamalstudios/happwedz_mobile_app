// Native port of the website's /about-us page (layouts/AboutUs.jsx, live
// chunk AboutUs-VEtnjnyH.js — identical text). The web page has no links:
// its only CTA ("Explore" → "/") is commented out, and the "Design Studio"
// card is commented out while the virtual try-on is disabled; both stay out.

import 'package:flutter/material.dart';

import 'package:happy_wedz/core/core.dart';

import 'info_page_widgets.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const String title = 'About HappyWedz';

  /// `./images/categories/venues.jpg` on the website, resolved against its
  /// origin.
  static const String imageUrl =
      'https://happywedz.com/images/categories/venues.jpg';

  static const String intro =
      'Your Complete Online Wedding Planning Destination HappyWedz is a '
      'modern, easy-to-use wedding planning platform in India that helps '
      'couples plan their special day effortlessly. From discovering wedding '
      'themes, décor ideas, bridal fashion, groom styling, venue inspiration, '
      'to finding trusted wedding vendors in your city — everything you need '
      'is right here. Search and compare photographers, makeup artists, '
      'decorators, caterers, wedding venues, mehandi artists, and more based '
      'on your budget, style, and location. Every vendor listed on HappyWedz '
      'is verified to ensure reliable and professional service. Whether '
      'you’re planning a traditional ceremony or a modern destination '
      'wedding, HappyWedz helps you create a celebration filled with joy, '
      'beauty, and personal meaning — without stress. Start planning the '
      'wedding of your dreams with HappyWedz — simple, smart, and beautifully '
      'organized.';

  @override
  Widget build(BuildContext context) {
    final body = AppText.body.copyWith(color: AppColors.textSecondary);
    return InfoPageScaffold(
      title: title,
      children: [
        Text(intro, style: body),
        const Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.huge,
          ),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        const _SectionTitle('Make Planning Decisions'),
        const _FeatureCard(
          title: 'Vendors',
          body: 'Discover thousands of trusted wedding vendors all in one '
              'place at HappyWedz! From expert wedding photographers and '
              'creative decorators to experienced makeup artists, caterers, '
              'and wedding priests, we’ve got every service you need to make '
              'your big day perfect.',
        ),
        const _FeatureCard(
          title: 'HappyWedz Bridal Gallery – Find Your Dream Bridal Look',
          body: 'Discover your perfect wedding outfit at HappyWedz Bridal '
              'Gallery. Explore designer lehengas, sarees, gowns, and fusion '
              'styles. Connect directly with designers to customize your '
              'dream look. Enjoy a smooth online shopping experience from '
              'home. Elegance, style, and the perfect bridal outfit—all in one '
              'place.',
        ),
        const _FeatureCard(
          title: 'Shaadi AI',
          body: 'Not sure where to begin your wedding planning? Let ShadiAi, '
              'your AI-powered wedding planner, make it effortless. It '
              'understands your style, budget, and preferences instantly. Get '
              'perfect vendor matches in seconds—smart, simple, stress-free',
        ),
        const _FeatureCard(
          title: 'HappyWedz Mynt',
          spans: [
            TextSpan(
              text: 'An exclusive loyalty program for brides and '
                  'grooms-to-be, offering ',
            ),
            TextSpan(
              text: 'special offers and rewards',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: ' from 100+ premium brands in bridal wear, travel, '
                  'jewellery, beauty, and more!',
            ),
          ],
        ),
        AppSpacing.h16,
        const _SectionTitle(
          'Still early in your journey? Get inspired with HappyWedz',
        ),
        const _FeatureCard(
          title: 'Photos',
          body: 'Dive into a world of stunning wedding inspiration with the '
              'HappyWedz Photo Gallery. Discover beautiful ideas for bridal '
              'lehengas, groom outfits, wedding décor, pre-wedding shoots, and '
              'more — all curated to spark your creativity and help you shape '
              'your dream celebration. From timeless traditions to trending '
              'styles, explore thousands of real wedding photos shared by '
              'couples and professionals across India. Get inspired, save your '
              'favorite looks, and bring your wedding vision to life with '
              'HappyWedz.',
        ),
        const _FeatureCard(
          title: 'Real Weddings – Where Love Stories Come to Life 💍',
          body: 'Every love story is special, and at HappyWedz, we celebrate '
              'them all. Explore real weddings shared by couples from across '
              'India — each filled with heartfelt moments, creative themes, '
              'stunning décor, and unforgettable celebrations. Get inspired by '
              'true wedding stories, browse beautiful photos, and discover '
              'fresh ideas for your own big day. From intimate ceremonies to '
              'grand destination weddings, find endless inspiration and real '
              'experiences only on HappyWedz.',
        ),
        const _FeatureCard(
          title: 'HappyWedz Blog – Your Ultimate Wedding Inspiration Hub ✨',
          body: 'Step into the HappyWedz Blog, your go-to space for everything '
              'wedding! Discover the latest bridal fashion trends, decor '
              'inspirations, planning tips, and creative ideas to make your '
              'celebration truly one of a kind. Whether you’re exploring '
              'timeless traditions or modern wedding styles, our blog brings '
              'you expert advice, trend updates, and real stories to help you '
              'plan with confidence. Stay inspired and plan smarter with the '
              'HappyWedz Blog — your trusted guide to all things wedding!',
        ),
        AppSpacing.h16,
        const _SectionTitle('Our Exclusive Features'),
        const _FeatureCard(
          title: 'Available on Android & iOS',
          spans: [
            TextSpan(text: 'Download the '),
            TextSpan(
              text: 'HappyWedz app',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: ' from Google Play or the Apple App Store for a seamless '
                  'planning experience. Plan, manage, and track your wedding '
                  'anytime, anywhere!',
            ),
          ],
        ),
        AppSpacing.h16,
        const _SectionTitle('Celebrating Responsibly with HappyWedz 🌿'),
        Text(
          'At HappyWedz, we believe every celebration can make a positive '
          'impact. Beyond creating unforgettable weddings, we are committed to '
          'environmental sustainability, social welfare, and community '
          'empowerment. From promoting eco-friendly wedding solutions to '
          'supporting local artisans and small vendors, our initiatives ensure '
          'that your special day is not only beautiful but also responsible. '
          'Celebrate love while making a meaningful difference with HappyWedz.',
          style: body,
          textAlign: TextAlign.center,
        ),
        AppSpacing.h32,
        ClipRRect(
          borderRadius: AppRadii.rSm,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textDark),
              borderRadius: AppRadii.rSm,
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              semanticLabel: 'About Us',
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        AppSpacing.h24,
        Text(
          'At HappyWedz, we believe that celebrations should also create a '
          'positive impact. Beyond weddings, we are committed to supporting '
          'the communities we serve through meaningful initiatives in '
          'environmental sustainability, social welfare, and empowerment. From '
          'promoting eco-friendly wedding solutions to collaborating with '
          'local artisans and small vendors, our goal is to make every '
          'celebration beautiful — and responsible.',
          style: body,
        ),
        AppSpacing.h24,
        const Row(
          children: [
            Expanded(child: _StatCard(value: '370+', label: 'Qualified Experts')),
            SizedBox(width: AppSpacing.md),
            Expanded(child: _StatCard(value: '18k+', label: 'Satisfied Clients')),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.sectionTitle.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, this.body, this.spans});

  final String title;
  final String? body;
  final List<TextSpan>? spans;

  @override
  Widget build(BuildContext context) {
    final style = AppText.body.copyWith(color: AppColors.textSecondary);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      border: Border.all(color: AppColors.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.cardTitle),
          AppSpacing.h8,
          if (spans != null)
            Text.rich(TextSpan(style: style, children: spans))
          else
            Text(body ?? '', style: style),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      border: Border.all(color: AppColors.textDark),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.pageTitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.h4,
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
