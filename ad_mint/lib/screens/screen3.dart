import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/ad_providers.dart';
import '../widgets/banner_ad_widget.dart';

class Screen3 extends ConsumerWidget {
  const Screen3({super.key});

  Future<void> _goNext(BuildContext context, WidgetRef ref) async {
    final adSvc = ref.read(adServiceProvider);
    await adSvc.showInterstitialIfAvailable(
      context: context,
      onContinue: () async {
        if (context.mounted) {
          Navigator.of(context).pushNamed('/screen4');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen 3')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _goNext(context, ref),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue to Screen 4 (Interstitial here)'),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
