import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/navigation.dart';
import 'abfindung_screen.dart';
import 'bewerben_hub_screen.dart';
import 'mehr_screen.dart';
import 'start_hub_screen.dart';

/// The app's home after onboarding: a persistent bottom navigation over the
/// two goal pillars — Abfindung (the money/exit side) and Bewerben (the
/// applying/next-job side) — plus the Start dashboard and a Mehr catch-all.
/// The KI features live inside their pillar, not in a separate tab. The
/// selected tab lives in [rootTabProvider] so other screens can switch areas
/// (e.g. the wizard jumps to Abfindung when done).
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(rootTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          StartHubScreen(),
          AbfindungScreen(),
          BewerbenScreen(),
          MehrScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(rootTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Start'),
          NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: 'Abfindung'),
          NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge),
              label: 'Bewerben'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'Mehr'),
        ],
      ),
    );
  }
}
