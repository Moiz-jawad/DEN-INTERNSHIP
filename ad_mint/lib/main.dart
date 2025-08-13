import 'dart:async';
import 'package:ad_mint/screens/login_screen.dart';
import 'package:ad_mint/screens/reward_screen.dart';
import 'package:ad_mint/screens/screen1.dart';
import 'package:ad_mint/screens/screen2.dart';
import 'package:ad_mint/screens/screen3.dart';
import 'package:ad_mint/screens/screen4.dart';
import 'package:ad_mint/screens/screen5.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/splash_screen.dart';

// import 'app.dart';
// import 'providers/ad_providers.dart';
// import 'providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads with error handling
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    // Do not crash if ads init fails
    debugPrint('MobileAds initialize failed: $e');
  }

  // Try Firebase init inside provider (lazy, guarded) — see firebaseInitProvider

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ThemeData(
      colorSchemeSeed: const Color(0xFF6750A4),
      useMaterial3: true,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'AdMob + Firebase Demo',
      theme: theme,
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MyApp(),
        '/screen1': (_) => const Screen1(),
        '/screen2': (_) => const Screen2(),
        '/screen3': (_) => const Screen3(),
        '/screen4': (_) => const Screen4(),
        '/screen5': (_) => const Screen5(),
        '/rewards': (_) => const RewardsScreen(),
      },
      initialRoute: '/',
    );
  }
}
