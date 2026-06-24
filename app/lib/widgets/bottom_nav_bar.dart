import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryFixed,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 70,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: colorScheme.onPrimaryFixed),
          label: 'בית',
        ),
        NavigationDestination(
          icon: const Icon(Icons.qr_code_scanner_outlined),
          selectedIcon:
              Icon(Icons.qr_code_scanner, color: colorScheme.onPrimaryFixed),
          label: 'סריקה',
        ),
        NavigationDestination(
          icon: const Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups, color: colorScheme.onPrimaryFixed),
          label: 'קהילה',
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite, color: colorScheme.onPrimaryFixed),
          label: 'מועדפים',
        ),
      ],
    );
  }
}