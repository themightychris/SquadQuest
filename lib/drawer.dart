import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:squadquest/router.dart';
import 'package:squadquest/controllers/auth.dart';
import 'package:squadquest/controllers/profile.dart';
import 'package:squadquest/controllers/settings.dart';

class _MenuItem {
  static const divider = Key('divider');

  final IconData icon;
  final String label;
  final String route;
  final Future<void> Function(WidgetRef ref)? afterNavigate;
  final bool developerMode;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    this.afterNavigate,
    this.developerMode = false,
  });
}

final _menu = [
  _MenuItem(
    icon: Icons.home,
    label: 'Home',
    route: 'home',
  ),
  _MenuItem(
    icon: Icons.people,
    label: 'Buddy List',
    route: 'friends',
  ),
  _MenuItem(
    icon: Icons.checklist,
    label: 'Topics',
    route: 'topics',
  ),
  _MenuItem(
    icon: Icons.person,
    label: 'Profile',
    route: 'profile-edit',
  ),
  _MenuItem(
    icon: Icons.settings,
    label: 'Settings',
    route: 'settings',
  ),
  _MenuItem(
    icon: Icons.map,
    label: 'Map',
    route: 'map',
    developerMode: true,
  ),
  _MenuItem.divider,
  _MenuItem(
    icon: Icons.logout,
    label: 'Sign out',
    route: 'login',
    afterNavigate: (ref) async {
      await ref.read(authControllerProvider.notifier).signOut();
    },
  ),
];

final _menuItems = _menu.whereType<_MenuItem>().toList();

bool isDrawerRoute(String routeName) {
  return _menuItems.any((item) => item.route == routeName);
}

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final developerMode = ref.watch(developerModeProvider);
    final effectiveMenuItems = _menuItems
        .where((menuItem) => !menuItem.developerMode || developerMode)
        .toList();

    // get current screen name
    final router = ref.watch(routerProvider);
    final currentScreenName =
        router.routerDelegate.currentConfiguration.last.route.name;

    return NavigationDrawer(
      selectedIndex: effectiveMenuItems
          .indexWhere((item) => item.route == currentScreenName),
      onDestinationSelected: (int newSelection) async {
        final menuItem = effectiveMenuItems[newSelection];

        Navigator.pop(context);

        context.goNamed(menuItem.route);

        if (menuItem.afterNavigate != null) {
          await menuItem.afterNavigate!(ref);
        }
      },
      children: <Widget>[
        profileAsync.when(
            data: (profile) => UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                accountName: Text(profile!.fullName),
                accountEmail: profile.phone == null
                    ? null
                    : Text(profile.phoneFormatted!)),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink()),
        ..._menu
            .where((menuItem) =>
                menuItem is! _MenuItem ||
                !menuItem.developerMode ||
                developerMode)
            .map((menuItem) => switch (menuItem) {
                  _MenuItem.divider => const Divider(thickness: 1),
                  (_MenuItem _) => NavigationDrawerDestination(
                      icon: Icon(menuItem.icon),
                      label: Text(menuItem.label),
                    ),
                  _ => throw 'Invalid menu item: $menuItem',
                })
      ],
    );
  }
}
