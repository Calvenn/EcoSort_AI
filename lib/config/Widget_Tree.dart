import 'package:eco_sort_ai/Module/Guide.dart';
import 'package:eco_sort_ai/Module/RedeemVoucher.dart';
import 'package:flutter/material.dart';
import 'Notifier.dart';
import '../Module/Home.dart';
import '../Module/Waste.dart';
import '../config/map.dart';
import '../Module/ProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';

List<Widget> widgetList = [
  Home(),
  ProfilePage(),
  WastePage(),
  GuidePage(),
  MapPage(),
  RedeemPage(),
];

Future<void> _logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushReplacementNamed(context, '/login');
}

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key, required this.title});
  final String title;

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  static const Color ecoGreen = Color(0xFFe8f5e9);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth >= 600;
        return Scaffold(
          backgroundColor: ecoGreen,
          appBar: AppBar(
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 25),
            ),
            centerTitle: true,
            backgroundColor: Colors.green,
            elevation: 2,
            automaticallyImplyLeading: !isWideScreen,
            actions: [
              if (isWideScreen)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') {
                      _logout(context);
                    }
                  },
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Log Out', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          drawer: isWideScreen
              ? null
              : Drawer(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const DrawerHeader(
                        decoration: BoxDecoration(color: Colors.green),
                        child: Text(
                          'EcoSort AI',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text("Home"),
                        onTap: () {
                          selectedPageNotifier.value = 0;
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text("Profile"),
                        onTap: () {
                          selectedPageNotifier.value = 1;
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.search),
                        title: const Text('Classify Waste'),
                        onTap: () {
                          selectedPageNotifier.value = 2;
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: const Text('Recycling Guide'),
                        onTap: () {
                          selectedPageNotifier.value = 3;
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.map), 
                        title: const Text('Recycling Centers'),
                        onTap: () {
                          selectedPageNotifier.value = 4;
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.redeem),
                        title: const Text("Redeem Vouchers"),
                        onTap: () {
                          selectedPageNotifier.value = 5;
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Log Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
          body: Row(
            children: [
              if (isWideScreen)
                NavigationRail(
                  selectedIndex: selectedPageNotifier.value,
                  onDestinationSelected: (int index) {
                    setState(() {
                      selectedPageNotifier.value = index;
                    });
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search),
                      label: Text('Classify'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book),
                      label: Text('Guide'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],

                  selectedIconTheme: const IconThemeData(color: Colors.green),
                  selectedLabelTextStyle: const TextStyle(color: Colors.green),
                ),
              Expanded(
                child: Container(
                  color: ecoGreen,
                  child: ValueListenableBuilder(
                    valueListenable: selectedPageNotifier,
                    builder:
                        (
                          BuildContext context,
                          int selectedPage,
                          Widget? child,
                        ) {
                          return widgetList[selectedPage];
                        },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
