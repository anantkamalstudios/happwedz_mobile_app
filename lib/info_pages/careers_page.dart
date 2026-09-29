// Native port of the website's /careers page (CareersPage.jsx, live chunk
// CareersPage-D4Xh36f1.js — identical text). The web page has no apply
// button or contact link, so neither does this one.

import 'package:flutter/material.dart';

import 'package:happy_wedz/core/core.dart';

import 'info_page_widgets.dart';

/// One job opening as shown under a Careers tab.
class CareerOpening {
  const CareerOpening({
    required this.title,
    required this.description,
    required this.responsibilities,
    required this.skills,
    required this.location,
  });

  final String title;
  final String description;
  final List<String> responsibilities;
  final List<String> skills;
  final String location;
}

enum CareerTab {
  technology('TECHNOLOGY'),
  business('BUSINESS');

  const CareerTab(this.label);
  final String label;
}

const Map<CareerTab, CareerOpening> careerOpenings = {
  CareerTab.technology: CareerOpening(
    title: 'AI Product Research Intern',
    description:
        'We’re looking for an enthusiastic intern who loves exploring the '
        'world of artificial intelligence. You’ll work with the product team '
        'to research AI tools, analyze market trends, and assist in building '
        'demo prototypes for new product concepts.',
    responsibilities: [
      'Assist in researching emerging AI and automation technologies',
      'Collect, clean, and organize sample datasets for product testing',
      'Collaborate with product designers to brainstorm new feature ideas and user flows',
      'Prepare short reports and competitor summaries for internal review',
    ],
    skills: [
      'Basic understanding of AI/ML concepts or APIs',
      'Comfortable with Google Sheets or data visualization tools',
      'Good written and communication skills',
      'Ability to work independently and learn quickly',
      'Students from technical or business backgrounds preferred',
    ],
    location: 'Remote / Hybrid',
  ),
  CareerTab.business: CareerOpening(
    title: 'Creative Content Strategist',
    description:
        'We’re seeking a creative storyteller who can craft engaging '
        'campaigns for our digital products. You’ll help shape how users '
        'discover, understand, and connect with our brand through social '
        'media, blogs, and newsletters.',
    responsibilities: [
      'Develop creative content strategies to enhance user engagement across platforms',
      'Write compelling copy for product pages, campaigns, and blog content',
      'Work with designers and marketing teams to maintain a consistent brand tone',
      'Research new trends and formats in digital storytelling',
    ],
    skills: [
      '1–3 years of experience in content writing or brand strategy',
      'Excellent command of English and storytelling techniques',
      'Strong attention to detail and understanding of audience behavior',
      'Experience with SEO or basic analytics is a plus',
      'Creative mindset with strong execution ability',
    ],
    location: 'Mumbai / Remote',
  ),
};

class CareersPage extends StatefulWidget {
  const CareersPage({super.key, this.initialTab = CareerTab.technology});

  final CareerTab initialTab;

  static const String title = 'HappyWedz Careers';

  /// Hero photo used by the web page.
  static const String heroImageUrl =
      'https://images.unsplash.com/photo-1557804506-669a67965ba0?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1074';

  @override
  State<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends State<CareersPage> {
  late CareerTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final job = careerOpenings[_tab]!;
    return InfoPageScaffold(
      title: CareersPage.title,
      header: _hero(context),
      children: [
        AnimatedSwitcher(
          duration: AppMotion.normal,
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: _JobView(job: job),
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            child: Image.network(
              CareersPage.heroImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        // rgba(0, 0, 0, 0.7) overlay, as on the web.
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.7)),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
              width: 48,
              height: 40,
              child: AppBackButton(color: AppColors.textOnPrimary),
            ),
                ),
                AppSpacing.h24,
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Column(
                    children: [
                      Text(
                        CareersPage.title,
                        textAlign: TextAlign.center,
                        style: AppText.displaySm.copyWith(color: Colors.white),
                      ),
                      AppSpacing.h12,
                      Text(
                        'We are a team of killer enthusiasts, aiming to '
                        're-build the wedding space.',
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(color: Colors.white),
                      ),
                      AppSpacing.h8,
                      Text(
                        'If you care about weddings, technology & innovation, '
                        'then you could be the one we are looking for.',
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(color: Colors.white),
                      ),
                      AppSpacing.h24,
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.xxxl,
                        children: [
                          for (final t in CareerTab.values) _tabButton(t),
                        ],
                      ),
                      AppSpacing.h16,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(CareerTab t) {
    final selected = t == _tab;
    return InkWell(
      onTap: () => setState(() => _tab = t),
      child: Container(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 3,
              color: selected ? const Color(0xFFD63384) : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          t.label,
          style: AppText.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _JobView extends StatelessWidget {
  const _JobView({required this.job});

  final CareerOpening job;

  @override
  Widget build(BuildContext context) {
    final body = AppText.bodyLg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(job.title, style: AppText.pageTitle),
        AppSpacing.h12,
        Text(job.description, style: body),
        AppSpacing.h16,
        Text(
          'Key Responsibilities :',
          style: body.copyWith(fontWeight: FontWeight.w700),
        ),
        AppSpacing.h8,
        for (final r in job.responsibilities) _bullet(r),
        AppSpacing.h16,
        Text(
          'Desired Skills and Experience :',
          style: body.copyWith(fontWeight: FontWeight.w700),
        ),
        AppSpacing.h8,
        for (final s in job.skills) _bullet(s),
        AppSpacing.h24,
        Text.rich(
          TextSpan(
            style: body,
            children: [
              const TextSpan(
                text: 'Location :',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' ${job.location}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: AppText.body.copyWith(height: 1.8)),
          AppSpacing.w8,
          Expanded(
            child: Text(text, style: AppText.body.copyWith(height: 1.8)),
          ),
        ],
      ),
    );
  }
}
