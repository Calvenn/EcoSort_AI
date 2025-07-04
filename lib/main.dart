import 'package:eco_sort_ai/Module/Guide.dart';
import 'package:eco_sort_ai/Module/RedeemVoucher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config/Notifier.dart';
import 'Module/Waste.dart';
import 'Module/Login.dart';
import 'Module/Register.dart';
import 'Module/ProfilePage.dart';
import 'config/Widget_Tree.dart';
import 'config/Map.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // firebase will check if the user is logged in previously or not
  // if yes, it will automatically redirect to the home page
  // if not, it will redirect to the login page

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    await windowManager.ensureInitialized();
    windowManager.setTitle('EcoSort AI');
  }

  runApp(const Main());
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
          navigatorObservers: [routeObserver],
          title: 'EcoSort AI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          ),
          routes: {
            '/classify': (context) => WastePage(),
            '/map': (context) => MapPage(),
            '/guide': (context) => GuidePage(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/profile': (context) => const ProfilePage(),
            '/redeem': (context) => const RedeemPage(),
            '/home': (context) => const WidgetTree(title: 'EcoSort AI'),
          },
          home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                return const WidgetTree(title: 'EcoSort AI');
              } else {
                return const LoginPage();
              }
            },
          ),
        );
      },
    );
  }
}
