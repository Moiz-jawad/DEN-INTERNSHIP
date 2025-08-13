import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/ad_providers.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad.dart';

class Screen4 extends ConsumerStatefulWidget {
  const Screen4({super.key});

  @override
  ConsumerState<Screen4> createState() => _Screen4State();
}

class _Screen4State extends ConsumerState<Screen4> {
  @override
  void initState() {
    super.initState();
    // Preload native ad when the screen loads
    ref.read(adServiceProvider).loadNativeAd();
  }

  @override
  void dispose() {
    // Dispose native ad when leaving the screen
    ref.read(adServiceProvider).disposeNativeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen 4')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/screen5'),
                icon: const Icon(Icons.navigate_next),
                label: const Text('Go to Screen 5'),
              ),
            ),
          ),
          // Show Native Ad
          const NativeAdWidget(),
          // Show Banner Ad
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
