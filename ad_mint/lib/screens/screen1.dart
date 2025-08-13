import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/ad_providers.dart';
import '../widgets/banner_ad_widget.dart';

class Screen1 extends ConsumerStatefulWidget {
  const Screen1({super.key});

  @override
  ConsumerState<Screen1> createState() => _Screen1State();
}

class _Screen1State extends ConsumerState<Screen1> {
  bool _hasShownAppOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showAppOpenAd();
  }

  Future<void> _showAppOpenAd() async {
    if (_hasShownAppOpen) return;
    _hasShownAppOpen = true;

    final adSvc = ref.read(adServiceProvider);

    // Show App Open Ad
    await adSvc.showAppOpenAdIfAvailable();

    // Optional: After App Open Ad, you can preload a Rewarded ad
    adSvc.loadRewarded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen 1')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/screen2'),
                    icon: const Icon(Icons.navigate_next),
                    label: const Text('Go to Screen 2'),
                  ),
                ],
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
