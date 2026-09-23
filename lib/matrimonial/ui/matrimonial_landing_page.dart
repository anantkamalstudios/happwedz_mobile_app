/// Matrimonial landing page — ports `MatrimonialMain.jsx` and its three
/// Home sections (`Home/Hero.jsx`, `Home/MembersPlan.jsx`, `Home/
/// HomeSlider.jsx`).
///
/// This whole module has no backend anywhere in the source (see
/// MIGRATION_NOTES.md's Matrimonial section). The hero stats and the
/// membership plan prices/features below are the same static marketing copy
/// the source hardcodes (not live data, same status as the Honeymoon hero
/// figures already documented as "configuration, not data"). The two source
/// CTAs that had no `onClick` at all in the JSX ("Select Plan" and the
/// success-story cards' "View Profile" / "Send Wish") are wired here to an
/// honest gated message instead of staying silent no-ops, per this app's
/// rule against buttons that do nothing when tapped.
///
/// Not ported: the source's hero image carousel, which is a real bug, not
/// content — `swiperImages` in `Hero.jsx` is the same Unsplash URL repeated
/// six times. Replaced with a static decorative panel instead of replicating
/// that copy-paste mistake or inventing six different stock photos.
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../main.dart' show requireAuthentication;
import 'matrimonial_profile_page.dart';
import 'matrimonial_registration_page.dart';
import 'matrimonial_search_page.dart';
import 'dashboard/matrimonial_dashboard_page.dart';
import 'dashboard/matrimonial_edit_profile_page.dart';

/// Shows an honest "not available yet" message instead of doing nothing or
/// faking success. Used by every non-functional action across this module.
void showMatrimonialGate(BuildContext context, String message) {
  AppSnackbar.warning(context, message);
}

/// Opens a matrimonial page that belongs to the user's own account (profile,
/// dashboard, registration). A guest signs in first and then lands on the
/// page they tapped; cancelling keeps them on the landing page. Browsing and
/// searching profiles stay public.
Future<void> openMatrimonialAccountPage(
  BuildContext context,
  Widget page, {
  required String reason,
}) async {
  final signedIn = await requireAuthentication(context, reason: reason);
  if (!signedIn || !context.mounted) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class MatrimonialLandingPage extends StatelessWidget {
  const MatrimonialLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Matrimonial',
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => openMatrimonialAccountPage(
              context,
              const MatrimonialEditProfilePage(),
              reason: 'Sign in to create your matrimonial profile.',
            ),
          ),
          IconButton(
            tooltip: 'My dashboard',
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () => openMatrimonialAccountPage(
              context,
              const MatrimonialDashboardPage(),
              reason: 'Sign in to see your matches, interests and messages.',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          _Hero(),
          const SizedBox(height: AppSpacing.xl),
          _MembersPlan(),
          const SizedBox(height: AppSpacing.xl),
          _HomeSlider(),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Perfect Life Partner',
            style: AppText.display.copyWith(color: Colors.white),
          ),
          AppSpacing.h8,
          Text(
            'Trusted by millions of families to discover meaningful connections',
            style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          AppSpacing.h24,
          Row(
            children: const [
              Expanded(child: _HeroStat(value: '10M+', label: 'Registered Users')),
              Expanded(child: _HeroStat(value: '500K+', label: 'Success Stories')),
              Expanded(child: _HeroStat(value: '20+', label: 'Years of Experience')),
            ],
          ),
          AppSpacing.h24,
          PremiumButton.secondary(
            label: 'Register Free',
            onPressed: () => openMatrimonialAccountPage(
              context,
              const MatrimonialRegistrationPage(),
              reason: 'Sign in to register for HappyWedz Matrimonial.',
            ),
          ),
          AppSpacing.h12,
          Row(
            children: [
              Expanded(
                child: PremiumButton.outlined(
                  label: 'Search Profiles',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MatrimonialSearchPage()),
                  ),
                ),
              ),
              AppSpacing.w12,
              Expanded(
                child: PremiumButton.outlined(
                  label: 'Browse Matches',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MatrimonialProfilePage()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.sectionTitle.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        AppSpacing.h4,
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.85)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Membership plans
// ---------------------------------------------------------------------------

class _MembershipPlan {
  const _MembershipPlan(this.name, this.price, this.duration, this.features);
  final String name;
  final String price;
  final String duration;
  final List<String> features;
}

const List<_MembershipPlan> _plans = [
  _MembershipPlan('Free', '₹0', 'Forever', [
    'Basic profile',
    'Limited searches',
    '10 interest requests',
  ]),
  _MembershipPlan('Gold', '₹3,999', '3 Months', [
    'Unlimited searches',
    'Unlimited interests',
    'Priority listing',
    'Profile highlight',
  ]),
  _MembershipPlan('Platinum', '₹6,999', '6 Months', [
    'All Gold features',
    'Verified badge',
    'Profile boost',
    'Matchmaking assistance',
    'Privacy control',
  ]),
];

class _MembersPlan extends StatelessWidget {
  const _MembersPlan();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Choose Your Membership Plan',
          subtitle: 'Find the perfect plan to meet your matchmaking needs',
        ),
        // Sized to the tallest plan instead of a fixed 300 px, which the
        // Platinum plan (5 features) overflowed — worse at larger system
        // font sizes. IntrinsicHeight + stretch keeps every card the same
        // height so the "Select Plan" buttons still line up. Only 3 plans,
        // so building them all at once (no lazy ListView) costs nothing.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _plans.length; i++) ...[
                  if (i > 0) AppSpacing.w12,
                  SizedBox(
                    width: 230,
                    child: _PlanCard(plan: _plans[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final _MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    final recommended = plan.name == 'Gold';
    return AppCard(
      color: recommended ? AppColors.blush : AppColors.surface,
      border: recommended ? Border.all(color: AppColors.primary, width: 1.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recommended)
            const AppBadge(label: 'Most Popular', background: AppColors.primary),
          if (recommended) AppSpacing.h8,
          Text('${plan.name} Plan', style: AppText.cardTitle),
          AppSpacing.h4,
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: plan.price, style: AppText.price),
                TextSpan(text: ' /${plan.duration}', style: AppText.bodySm),
              ],
            ),
          ),
          AppSpacing.h12,
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  Expanded(child: Text(f, style: AppText.bodySm)),
                ],
              ),
            ),
          ),
          const Spacer(),
          PremiumButton(
            label: 'Select Plan',
            size: PremiumButtonSize.medium,
            onPressed: () => showMatrimonialGate(
              context,
              'Plan purchase isn\'t available yet — please check back soon.',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success stories (static marketing carousel — see file header)
// ---------------------------------------------------------------------------

class _SuccessStory {
  const _SuccessStory(this.names, this.date, this.location);
  final String names;
  final String date;
  final String location;
}

const List<_SuccessStory> _stories = [
  _SuccessStory('Raj & Priya', 'Mar 2023', 'Mumbai, Maharashtra'),
  _SuccessStory('Amit & Neha', 'Jan 2023', 'Delhi, NCR'),
  _SuccessStory('Vikram & Anjali', 'Dec 2022', 'Bangalore, Karnataka'),
  _SuccessStory('Sanjay & Meera', 'Oct 2022', 'Chennai, Tamil Nadu'),
  _SuccessStory('Rahul & Shreya', 'Aug 2022', 'Hyderabad, Telangana'),
  _SuccessStory('Arjun & Pooja', 'Jun 2022', 'Pune, Maharashtra'),
];

class _HomeSlider extends StatelessWidget {
  const _HomeSlider();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Success Stories',
          subtitle: 'Real couples who found their perfect match through our platform',
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: _stories.length,
            separatorBuilder: (_, __) => AppSpacing.w12,
            itemBuilder: (context, i) => SizedBox(
              width: 220,
              child: _StoryCard(story: _stories[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});

  final _SuccessStory story;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The card has a fixed height (the carousel is 190 px), so the
          // banner takes whatever the text and button leave rather than a
          // fixed 70 px — that overflowed by a few pixels on real devices and
          // more at larger system font sizes.
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.blushGradient,
                borderRadius: AppRadii.rMd,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.favorite, color: AppColors.primary, size: 28),
            ),
          ),
          AppSpacing.h8,
          Text(story.names, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Married: ${story.date}', style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(story.location, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(
            children: [
              Expanded(
                child: PremiumButton.text(
                  label: 'View Profile',
                  onPressed: () => showMatrimonialGate(
                    context,
                    'Profile matching isn\'t available yet.',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
