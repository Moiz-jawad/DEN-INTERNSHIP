import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/ad_providers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends ConsumerWidget {
  const NativeAdWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adSvc = ref.watch(adServiceProvider);
    final nativeAd = adSvc.nativeAd;

    if (nativeAd == null) return const SizedBox.shrink();

    return Container(
      height: 120, // adjust height for your layout
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AdWidget(ad: nativeAd),
    );
  }
}
