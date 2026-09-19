/// Dashboard shell — ports `dashboard/MatrimonialDashboard.jsx`'s sidebar +
/// section switcher.
///
/// The source's dashboard fabricates almost everything it shows:
///  - `sampleProfiles` is a hardcoded list of six people with stock photos.
///  - `stats` (`totalProfiles`/`activeProfiles`/`newMatches`/`messages`)
///    auto-increments every 10s via `Math.random()` — invented metrics with
///    no backend behind them.
///  - `sections/Messages.jsx` has its real UI commented out, replaced with a
///    static "Service Unavailable" stub.
///  - `sections/Interests.jsx` renders hardcoded sent/received arrays with
///    no-op Accept/Decline buttons.
///  - `sections/Activity.jsx` renders a hardcoded `mockData` map.
///
/// None of that is reproduced here. Every tab below is either the real,
/// functional "Advanced Search" form, or an honest empty state. Per this
/// app's rule against fabricated metrics, the stats row is a static
/// "Coming soon" tile with no numbers at all — seeing a real-looking count
/// that means nothing would be worse than seeing no count.
///
/// One deliberate deviation from the source: `sidebarItems` in the source
/// comments out the "Interests" entry, so that tab is unreachable from the
/// UI even though the section component still exists. This port makes it
/// reachable — there is no reason to reproduce that particular omission —
/// see MIGRATION_NOTES.md.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../matrimonial_search_page.dart';
import 'matrimonial_edit_profile_page.dart';

class MatrimonialDashboardPage extends StatefulWidget {
  const MatrimonialDashboardPage({super.key});

  @override
  State<MatrimonialDashboardPage> createState() => _MatrimonialDashboardPageState();
}

class _DashboardTab {
  const _DashboardTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _tabs = [
  _DashboardTab('My Matches', Icons.favorite_border),
  _DashboardTab('Activity', Icons.timeline_outlined),
  _DashboardTab('Messages', Icons.mail_outline),
  _DashboardTab('Interests', Icons.person_add_alt_outlined),
  _DashboardTab('Advanced Search', Icons.search),
  _DashboardTab('Profile', Icons.person_outline),
];

class _MatrimonialDashboardPageState extends State<MatrimonialDashboardPage> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'My Dashboard'),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              // A plain Row (not a lazy ListView) so every tab exists in the
              // tree up front — there are only six, and this keeps them
              // reachable without first scrolling them into the viewport.
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final selected = i == _selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      avatar: Icon(tab.icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
                      label: Text(tab.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selected = i),
                      selectedColor: AppColors.primary,
                      labelStyle: AppText.labelSm.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _selected,
              sizing: StackFit.expand,
              children: const [
                _MatchesTab(),
                _NotAvailableTab(
                  title: 'Activity',
                  message: "Activity tracking isn't available yet.",
                  icon: Icons.timeline_outlined,
                ),
                _NotAvailableTab(
                  title: 'Messages',
                  message: 'Sorry, the messaging service is temporarily unavailable.\nPlease try again later.',
                  icon: Icons.mail_outline,
                ),
                _NotAvailableTab(
                  title: 'Interests',
                  message: "Sent and received interests aren't available yet.",
                  icon: Icons.person_add_alt_outlined,
                ),
                MatrimonialSearchForm(),
                _ProfileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _ComingSoonStatsRow(),
        AppSpacing.h24,
        const EmptyState(
          compact: true,
          icon: Icons.favorite_border,
          title: 'No matches available yet',
          message: "Matching isn't connected to a live directory yet — please check back soon.",
        ),
      ],
    );
  }
}

/// Replaces the source's `Math.random()`-driven stat cards with a plain,
/// honest placeholder — no numbers that could be mistaken for real ones.
class _ComingSoonStatsRow extends StatelessWidget {
  const _ComingSoonStatsRow();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.bar_chart_outlined, color: AppColors.textTertiary),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile & match stats', style: AppText.bodyStrong),
                Text('Coming soon', style: AppText.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotAvailableTab extends StatelessWidget {
  const _NotAvailableTab({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: '$title not available',
      message: message,
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.badge_outlined,
        title: "You haven't completed your profile yet",
        message: 'Fill in your details so matches can find you.',
        actionLabel: 'Edit Profile',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MatrimonialEditProfilePage()),
        ),
      ),
    );
  }
}
