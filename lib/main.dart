import 'package:eco_sort_ai/Module/Guide.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/Notifier.dart';
import 'config/Widget_Tree.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Module/Home.dart';
import 'Module/Waste.dart';
import '../config/Map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    windowManager.setTitle('EcoSort AI');
  }

  runApp(Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (BuildContext context, dynamic isDarkMode, Widget? child) {
        return MaterialApp(
          title: 'Eco Sort AI',
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/classify': (context) => WastePage(),
            '/map': (context) => MapPage(),
            '/guide': (context) => GuidePage(),
          },
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              //brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: WidgetTree(title: 'EcoSort AI'),
        );
      },
    );
  }
}
