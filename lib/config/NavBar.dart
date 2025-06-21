import 'package:flutter/material.dart';
import 'Notifier.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (BuildContext context, int selectedPage, Widget? child) {
        return NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
              selectedIcon: Icon(Icons.home_rounded, color: Colors.blue),
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Classify Waste',
              selectedIcon: Icon(Icons.search, color: Colors.blue),
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book),
              label: 'Recycling Guide',
              selectedIcon: Icon(Icons.menu_book, color: Colors.blue),
            ),
          ],
          onDestinationSelected: (int value) {
            selectedPageNotifier.value = value;
          },
          selectedIndex: selectedPage,
        );
      },
    );
  }
}
