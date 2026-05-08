import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../theme/landing_theme.dart';
import '../widgets/waitlist_form.dart';

const bool kWaitlistMode = bool.fromEnvironment(
  'WAITLIST_MODE',
  defaultValue: true,
);

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: buildLandingTheme(context),
      child: const Scaffold(
        backgroundColor: LandingColors.bg,
        body: SafeArea(child: _LandingBody()),
      ),
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          _NavBar(),
          _Section(tone: _SectionTone.plain, child: _Hero()),
          _Section(tone: _SectionTone.muted, child: _PainSection()),
          _Section(tone: _SectionTone.plain, child: _HowItWorks()),
          _Section(tone: _SectionTone.muted, child: _FeatureGrid()),
          _Section(tone: _SectionTone.plain, child: _Comparison()),
          _Section(tone: _SectionTone.muted, child: _Pricing()),
          _Section(tone: _SectionTone.plain, child: _Faq()),
          _Section(tone: _SectionTone.dark, child: _FooterCta()),
          _Footer(),
        ],
      ),
    );
  }
}

enum _SectionTone { plain, muted, dark }

class _Section extends StatelessWidget {
  const _Section({required this.child, this.tone = _SectionTone.plain});
  final Widget child;
  final _SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final hPad = width < 600 ? 20.0 : (width < 1024 ? 40.0 : 64.0);
    final vPad = width < 600 ? 56.0 : 88.0;
    final bg = switch (tone) {
      _SectionTone.plain => LandingColors.bg,
      _SectionTone.muted => Colors.white,
      _SectionTone.dark => const Color(0xFF111827),
    };
    return Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: child,
        ),
      ),
    );
  }
}

// ─── Nav ──────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LandingColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ClientPulse',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (!kWaitlistMode)
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      color: LandingColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero (Variant A) ─────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Stop chasing client status. Show it.',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: isMobile ? 36 : 56,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'ClientPulse is a branded client update portal for service agencies. '
            'Post structured project updates from your dashboard; clients see them on a '
            'mobile-friendly page via magic link. No login. No install. No app to learn.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        if (kWaitlistMode) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const WaitlistForm(),
          ),
          const SizedBox(height: 12),
          const Text(
            '50 design-partner spots. 3 months free + 50% off Starter for life.',
            style: TextStyle(color: LandingColors.textFaint, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ] else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => context.go('/register'),
                child: const Text('Start free'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/p/demo123'),
                child: const Text('See a live portal →'),
              ),
            ],
          ),
      ],
    );
  }
}

// ─── Pain section ─────────────────────────────────────────────────

class _PainSection extends StatelessWidget {
  const _PainSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You know this story.', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        const _Bullet('Your client asks for a status update on WhatsApp. Again.'),
        const _Bullet(
            'Your PM writes the same paragraph in three Slack threads, two emails, and one call.'),
        const _Bullet('Your shared Google Drive is a graveyard of unlabelled files.'),
        const _Bullet('Updates get lost. Trust erodes. Clients escalate.'),
        const SizedBox(height: 20),
        Text(
          "The current alternatives are too heavy (Jira, Asana — clients won't use them) "
          'or too light (WhatsApp — no structure, no history, no branding).',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'ClientPulse is the layer in between.',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 9, right: 12),
            child: Icon(Icons.circle, size: 6, color: LandingColors.textFaint),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

// ─── How it works (3 steps) ───────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        '1',
        'Post a structured update.',
        'Title, body, category (progress / milestone / deliverable / blocker / input-needed), '
            'file attachments. Two minutes from your dashboard.',
      ),
      (
        '2',
        'Client gets a link.',
        'Magic-link email lands in their inbox. They tap once and they\'re in. '
            'No password. No app. Works on the phone they\'re already holding.',
      ),
      (
        '3',
        'Client sees the whole project.',
        'Branded portal with timeline, milestones, progress bar, file downloads, and a comment box. '
            'They reply — you get notified instantly.',
      ),
    ];
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Three steps. That's the product.",
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 40),
        if (isMobile)
          Column(
            children: [
              for (final s in steps) ...[
                _Step(num: s.$1, title: s.$2, body: s.$3),
                const SizedBox(height: 24),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: _Step(
                    num: steps[i].$1,
                    title: steps[i].$2,
                    body: steps[i].$3,
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 32),
              ],
            ],
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.num, required this.title, required this.body});
  final String num;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// ─── Feature grid (4×2) ───────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const features = [
      ('Branded client portal', 'Your name and logo on every page'),
      ('Magic-link access', 'No client passwords, ever'),
      ('Structured updates', 'Categories, file attachments, markdown'),
      ('Milestone tracking', 'Auto progress bar from completion %'),
      ('Email notifications', 'Clients on new update; you on new comment'),
      ('Mobile-first portal', 'Clients open on phones, not laptops'),
      ('Multi-project workspace', 'One account, every client'),
      ('Open data export', 'CSV + JSON, day one, zero lock-in'),
    ];
    final width = MediaQuery.of(context).size.width;
    final cols = width < 600 ? 1 : (width < 1024 ? 2 : 4);
    final cardWidth = cols == 1
        ? double.infinity
        : (width - (cols - 1) * 16 - (width < 1024 ? 80 : 128)) / cols;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What you get on every plan',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final f in features)
              SizedBox(
                width: cardWidth.isFinite ? cardWidth : double.infinity,
                child: _FeatureCard(title: f.$1, body: f.$2),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LandingColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LandingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── Comparison ───────────────────────────────────────────────────

class _Comparison extends StatelessWidget {
  const _Comparison();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('No client login', '✅', '❌', '❌', '✅'),
      ('Branded for your agency', '✅', '❌', '❌', '❌'),
      ('Structured update categories', '✅', '❌', 'Partial', '❌'),
      ('Milestone tracker + progress bar', '✅', '❌', '❌', '❌'),
      ('Mobile-first portal UX', '✅', 'Partial', '❌', 'N/A'),
      ('Email-on-update notifications', '✅', '❌', '✅', 'N/A'),
      ('Designed for the agency-client loop', '✅', '❌', '❌', '❌'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Why not just use a tool you already have?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: LandingColors.border),
            borderRadius: BorderRadius.circular(12),
            color: LandingColors.surface,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  MaterialStateProperty.all(const Color(0xFFF3F4F6)),
              columns: const [
                DataColumn(label: Text('Feature')),
                DataColumn(label: Text('ClientPulse')),
                DataColumn(label: Text('Notion')),
                DataColumn(label: Text('Basecamp')),
                DataColumn(label: Text('WhatsApp')),
              ],
              rows: [
                for (final r in rows)
                  DataRow(cells: [
                    DataCell(Text(r.$1)),
                    DataCell(Text(r.$2)),
                    DataCell(Text(r.$3)),
                    DataCell(Text(r.$4)),
                    DataCell(Text(r.$5)),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pricing ──────────────────────────────────────────────────────

class _Pricing extends StatelessWidget {
  const _Pricing();

  @override
  Widget build(BuildContext context) {
    const tiers = [
      _Tier(name: 'Starter', price: '₹999', period: '/mo', projects: '5', team: '3'),
      _Tier(
        name: 'Growth',
        price: '₹2,499',
        period: '/mo',
        projects: '20',
        team: '10',
        customDomain: true,
        highlighted: true,
      ),
      _Tier(
        name: 'Agency',
        price: '₹5,999',
        period: '/mo',
        projects: 'Unlimited',
        team: 'Unlimited',
        customDomain: true,
        whiteLabel: true,
        priority: true,
      ),
    ];
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pricing', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Free forever — 1 active project, 1 team member. Card not required.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        if (isMobile)
          Column(
            children: [
              for (final t in tiers) ...[
                _PricingCard(tier: t),
                const SizedBox(height: 16),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tiers.length; i++) ...[
                Expanded(child: _PricingCard(tier: tiers[i])),
                if (i < tiers.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 16),
        Text(
          'Annual pricing at 20% off. Pay in INR or USD. Cancel anytime, take your data with you.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Tier {
  const _Tier({
    required this.name,
    required this.price,
    required this.period,
    required this.projects,
    required this.team,
    this.customDomain = false,
    this.whiteLabel = false,
    this.priority = false,
    this.highlighted = false,
  });
  final String name;
  final String price;
  final String period;
  final String projects;
  final String team;
  final bool customDomain;
  final bool whiteLabel;
  final bool priority;
  final bool highlighted;
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.tier});
  final _Tier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: LandingColors.surface,
        border: Border.all(
          color: tier.highlighted ? AppColors.primary : LandingColors.border,
          width: tier.highlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tier.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tier.price,
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(fontSize: 32),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  tier.period,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _PricingFeature('${tier.projects} active projects'),
          _PricingFeature('${tier.team} team members'),
          _PricingFeature('Custom domain', enabled: tier.customDomain),
          _PricingFeature('White-label', enabled: tier.whiteLabel),
          _PricingFeature('Priority support', enabled: tier.priority),
        ],
      ),
    );
  }
}

class _PricingFeature extends StatelessWidget {
  const _PricingFeature(this.text, {this.enabled = true});
  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check : Icons.close,
            size: 16,
            color: enabled ? AppColors.success : LandingColors.textFaint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? LandingColors.textPrimary : LandingColors.textFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FAQ ──────────────────────────────────────────────────────────

class _Faq extends StatelessWidget {
  const _Faq();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Is this different from Notion or Basecamp?',
        'Yes. Notion needs a login and has no milestone or category tracking. '
            "Basecamp is a full project management tool — clients won't learn it. "
            'ClientPulse is a thin, purpose-built layer for the agency → client loop.',
      ),
      (
        'Where is my data stored?',
        'Supabase Postgres in ap-south-1 (Mumbai) for Indian workspaces, us-east-1 for US/EU. '
            'Encrypted at rest, TLS in transit. Open data export from day one.',
      ),
      (
        'Can I use a custom domain like updates.myagency.com?',
        'Custom domain mapping ships in Q3 2026 on Growth and Agency tiers. '
            'Until then, your portal lives at clientpulse.dev/p/{token} with your logo and name on the page.',
      ),
      (
        'What if you shut down?',
        'Open data export, day one. CSV + JSON of every project, update, file URL, and comment. '
            'Zero lock-in by design.',
      ),
      (
        'Do my clients need to install anything?',
        'No. The portal is a webpage that opens via magic link. Phone or laptop, any browser, no app.',
      ),
      (
        'Why magic links instead of passwords?',
        'Clients hate passwords. Every password you ask a client to set is a chance for them to abandon the portal. '
            'Magic links remove the friction entirely.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Common questions',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        for (final i in items)
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            shape: const Border(),
            title: Text(
              i.$1,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(i.$2, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
      ],
    );
  }
}

// ─── Footer CTA ───────────────────────────────────────────────────

class _FooterCta extends StatelessWidget {
  const _FooterCta();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Built for agencies. Loved by their clients.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Free forever on the Starter tier. Two-minute setup. No credit card.',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (kWaitlistMode)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const WaitlistForm(),
          )
        else
          FilledButton(
            onPressed: () => context.go('/register'),
            child: const Text('Start free →'),
          ),
      ],
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LandingColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: const Center(
        child: Text(
          'ClientPulse · Built in Mumbai',
          style: TextStyle(color: LandingColors.textFaint, fontSize: 13),
        ),
      ),
    );
  }
}
