import 'package:eco_sort_ai/Module/Guide.dart';
import 'package:flutter/material.dart';
import 'Notifier.dart';
import '../Module/Home.dart';
import '../Module/Waste.dart';
import 'NavBar.dart';

List<Widget> widgetList = [Home(), WastePage(), GuidePage()];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key, required this.title});
  final String title;
  static const Color ecoGreen = Color(0xFFe8f5e9);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ecoGreen,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 25),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 2,
        // actions: [
        //   IconButton(
        //     icon: ValueListenableBuilder(
        //       valueListenable: isDarkModeNotifier,
        //       builder:
        //           (BuildContext context, dynamic isDarkMode, Widget? child) {
        //             return Icon(
        //               isDarkMode ? Icons.dark_mode : Icons.light_mode,
        //             );
        //           },
        //     ),
        //     onPressed: () {
        //       isDarkModeNotifier.value = !isDarkModeNotifier.value;
        //     },
        //   ),
        // ],
      ),

      body: Container(
        color: ecoGreen,
        child: ValueListenableBuilder(
          valueListenable: selectedPageNotifier,
          builder: (BuildContext context, int selectedPage, Widget? child) {
            return widgetList[selectedPage];
          },
        ),
      ),

      bottomNavigationBar: NavBar(),
    );
  }
}
