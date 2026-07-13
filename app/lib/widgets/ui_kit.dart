import 'package:flutter/material.dart';

/// A small, iOS-flavoured design kit shared by the hub screens: grouped inset
/// lists with hairline separators, rounded-square accent icons, large titles
/// and the two-pillar accent colours. Keeps the screens declarative and the
/// look consistent without fighting Material 3.

/// The two navigation pillars each own an accent. Teal = the money/exit side,
/// amber = the applying/next-job side. Brightened on dark grounds so both stay
/// legible.
Color abfindungAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5AD1D5)
        : const Color(0xFF00696E);

Color bewerbenAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0B24A)
        : const Color(0xFFA2650E);

Color neutralAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF98989F)
        : const Color(0xFF8E8E93);

/// iOS "grouped" background and card colours – a hair cooler than pure grey.
Color groupedBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : const Color(0xFFF2F2F7);

Color groupedCard(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : Colors.white;

Color hairline(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0x60545458)
        : const Color(0x223C3C43);

Color _fgOn(Color bg) =>
    ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black;

/// Uppercase, tracked grey label above a group (iOS grouped-list header).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.topPad = 22, super.key});
  final String text;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(6, topPad, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A rounded white group holding [AppRow]s, with inset hairline separators.
class AppGroup extends StatelessWidget {
  const AppGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 58,
          color: hairline(context),
        ));
      }
      rows.add(children[i]);
    }
    return Material(
      color: groupedCard(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// A single tappable row: accent rounded-square icon, title (+ optional KI
/// badge), subtitle and a chevron.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
    this.badge,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = accent ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: a,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: _fgOn(a)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        _KiBadge(label: badge!, accent: a),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 20, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _KiBadge extends StatelessWidget {
  const _KiBadge({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 10, color: accent),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

/// One of the two big cards on the Start hub: soft accent wash, rounded-square
/// icon, eyebrow, title, a few status lines and an accent "go" link.
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    required this.accent,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.lines,
    required this.cta,
    required this.onTap,
    super.key,
  });

  final Color accent;
  final IconData icon;
  final String eyebrow;
  final String title;
  final List<String> lines;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: groupedCard(context),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.10), Colors.transparent],
              stops: const [0, 0.65],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, size: 24, color: _fgOn(accent)),
                    ),
                    const SizedBox(width: 13),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eyebrow.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        Text(title,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_rounded, size: 17, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(l,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(cta,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: accent, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 18, color: accent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A softly-tinted "hero" card that leads a tool page: eyebrow, a big value or
/// title, a caption and optional trailing content (a pill, chips).
class AppHero extends StatelessWidget {
  const AppHero({
    required this.accent,
    required this.eyebrow,
    required this.headline,
    required this.caption,
    this.big = false,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Color accent;
  final String eyebrow;
  final String headline;
  final String caption;
  final bool big;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: groupedCard(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.10), Colors.transparent],
              stops: const [0, 0.7],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 5),
                Text(
                  headline,
                  style: big
                      ? theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: -1)
                      : theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(caption,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (trailing != null) ...[
                  const SizedBox(height: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A large-title, grouped-background scaffold for the hub screens.
class HubScaffold extends StatelessWidget {
  const HubScaffold({
    required this.title,
    required this.slivers,
    this.actions,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: groupedBackground(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: groupedBackground(context),
            surfaceTintColor: Colors.transparent,
            actions: actions,
            title: Text(title),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList(delegate: SliverChildListDelegate(slivers)),
          ),
        ],
      ),
    );
  }
}

/// Wraps a body-only widget in a plain titled scaffold when pushed as a page.
class TitledPage extends StatelessWidget {
  const TitledPage({required this.title, required this.child, super.key});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}

/// A pushed detail page in the grouped iOS style: flat app bar over the grouped
/// background, a scrolling body and an optional pinned footer (disclaimer).
class GroupedPage extends StatelessWidget {
  const GroupedPage({
    required this.title,
    required this.children,
    this.actions,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: groupedBackground(context),
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: groupedBackground(context),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(padding: padding, children: children),
          ),
          ?footer,
        ],
      ),
    );
  }
}

/// A plain rounded grouped card holding arbitrary content (a chart, a form, a
/// block of figures). Use [AppGroup] instead when the content is a list of
/// tappable [AppRow]s.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(padding: padding, child: child);
    return Material(
      color: groupedCard(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? inner : InkWell(onTap: onTap, child: inner),
    );
  }
}

/// A label/value line for a block of figures inside an [AppCard]. The emphasised
/// variant renders the value big and in the accent colour.
class StatRow extends StatelessWidget {
  const StatRow({
    required this.label,
    required this.value,
    this.accent,
    this.emphasise = false,
    super.key,
  });

  final String label;
  final String value;
  final Color? accent;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = accent ?? theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: emphasise ? 4 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: emphasise
                ? theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: a)
                : theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
