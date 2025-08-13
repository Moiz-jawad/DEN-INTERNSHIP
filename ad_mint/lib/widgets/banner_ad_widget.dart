import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../provider/ad_providers.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded && !_isLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    _isLoading = true;
    _ad?.dispose();

    try {
      final adSvc = ref.read(adServiceProvider);

      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate(),
          );

      if (!mounted) return;

      if (size == null) {
        debugPrint('Unable to determine banner size.');
        setState(() {
          _isLoaded = false;
          _isLoading = false;
        });
        return;
      }

      final banner = BannerAd(
        size: size,
        adUnitId: adSvc.bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) return;
            setState(() {
              _ad = ad as BannerAd;
              _isLoaded = true;
              _isLoading = false;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'Banner ad failed to load: ${error.code} - ${error.message}',
            );
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _isLoaded = false;
              _isLoading = false;
            });
          },
        ),
      );

      banner.load();
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
      if (mounted) {
        setState(() {
          _isLoaded = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholderHeight = _ad?.size.height.toDouble() ?? 50;

    if (!_isLoaded || _ad == null) {
      return SafeArea(
        child: SizedBox(
          height: placeholderHeight,
          child: const Center(
            child: Text(
              'Ad Space',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SizedBox(
        height: _ad!.size.height.toDouble(),
        width: _ad!.size.width.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
