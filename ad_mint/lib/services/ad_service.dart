import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/ad_config.dart';

class AdService {
  AdService(this._adUnitIds);

  AdUnitIds _adUnitIds;

  String get bannerAdUnitId => _adUnitIds.banner;

  void updateAdUnits(AdUnitIds ids) {
    _adUnitIds = ids;
  }

  void _log(String message) {
    debugPrint("[AdService] $message");
  }

  // ---------------- App Open Ad ----------------
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpen = false;
  bool _appOpenShownOnce = false;
  bool _loadingAppOpen = false;

  Future<void> loadAppOpenAd() async {
    if (_loadingAppOpen) return;
    _loadingAppOpen = true;

    try {
      await AppOpenAd.load(
        adUnitId: _adUnitIds.appOpen,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _loadingAppOpen = false;
            _log("App Open Ad loaded.");
          },
          onAdFailedToLoad: (error) {
            _appOpenAd = null;
            _loadingAppOpen = false;
            _log("App Open Ad failed: $error");
          },
        ),
      );
    } catch (e) {
      _loadingAppOpen = false;
      _log("App Open load exception: $e");
    }
  }

  Future<void> showAppOpenAdIfAvailable() async {
    if (_appOpenShownOnce || _appOpenAd == null || _isShowingAppOpen) return;

    _isShowingAppOpen = true;
    try {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) => _resetAppOpenState(ad),
        onAdFailedToShowFullScreenContent: (ad, error) {
          _log("App Open failed to show: $error");
          _resetAppOpenState(ad);
        },
      );
      _appOpenAd!.show();
    } catch (e) {
      _log("App Open show exception: $e");
      _resetAppOpenState(_appOpenAd);
    }
  }

  void _resetAppOpenState(Ad? ad) {
    _isShowingAppOpen = false;
    _appOpenShownOnce = true;
    ad?.dispose();
    _appOpenAd = null;
  }

  // ---------------- Interstitial ----------------
  InterstitialAd? _interstitialAd;
  bool _isShowingInterstitial = false;

  void preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: _adUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _log("Interstitial loaded.");
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _log("Interstitial failed: $error");
        },
      ),
    );
  }

  Future<void> showInterstitialIfAvailable({
    required BuildContext context,
    required FutureOr<void> Function() onContinue,
    Duration waitTimeout = const Duration(seconds: 2),
  }) async {
    if (_isShowingInterstitial || _interstitialAd == null) {
      await onContinue();
      preloadInterstitial();
      return;
    }

    _isShowingInterstitial = true;
    _showLoadingDialog(context, message: 'Loading ad...');
    bool shown = false;
    Timer? timeout;

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          shown = true;
          _safePop(context);
        },
        onAdDismissedFullScreenContent: (ad) async {
          _disposeInterstitial(ad);
          await onContinue();
        },
        onAdFailedToShowFullScreenContent: (ad, error) async {
          _log("Interstitial failed: $error");
          _disposeInterstitial(ad);
          _safePop(context);
          await onContinue();
        },
      );

      timeout = Timer(waitTimeout, () {
        if (!shown) _safePop(context);
      });

      _interstitialAd!.show();
    } catch (e) {
      _log("Interstitial show exception: $e");
      _safePop(context);
      _disposeInterstitial(_interstitialAd);
      await onContinue();
    } finally {
      timeout?.cancel();
    }
  }

  void _disposeInterstitial(Ad? ad) {
    ad?.dispose();
    _interstitialAd = null;
    _isShowingInterstitial = false;
    preloadInterstitial();
  }

  // ---------------- Rewarded ----------------
  RewardedAd? _rewardedAd;
  bool _loadingRewarded = false;

  void loadRewarded({
    void Function()? onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    if (_loadingRewarded) return;
    _loadingRewarded = true;

    RewardedAd.load(
      adUnitId: _adUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingRewarded = false;
          _log("Rewarded loaded.");
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _loadingRewarded = false;
          _log("Rewarded failed: $error");
          onFailed?.call(error);
        },
      ),
    );
  }

  Future<void> showRewarded({
    required BuildContext context,
    required void Function(RewardItem reward) onRewarded,
    required VoidCallback onFailed,
  }) async {
    if (_rewardedAd == null) {
      loadRewarded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready, try again later')),
      );
      return;
    }

    _showLoadingDialog(context, message: 'Loading rewarded ad...');
    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) => _safePop(context),
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _log("Rewarded failed: $error");
          ad.dispose();
          _rewardedAd = null;
          _safePop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed: $error')));
          loadRewarded();
        },
      );
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) => onRewarded(reward),
      );
    } catch (e) {
      _safePop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ad error: $e')));
    }
  }

  // ---------------- Banner ----------------
  Future<BannerAd?> createAnchoredAdaptiveBanner({
    required BuildContext context,
    AdRequest request = const AdRequest(),
  }) async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (size == null) {
      _log('Cannot get banner size.');
      return null;
    }

    return BannerAd(
      size: size,
      adUnitId: _adUnitIds.banner,
      request: request,
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          _log('Banner failed: $error');
          ad.dispose();
        },
      ),
    );
  }

  // ---------------- Native ----------------
  NativeAd? _nativeAd;
  bool _isNativeLoaded = false;

  void loadNativeAd({
    void Function()? onLoaded,
    void Function(LoadAdError error)? onFailed,
    String factoryId = 'listTile', // <-- Must match registered factory
  }) {
    _nativeAd?.dispose();

    _nativeAd = NativeAd(
      adUnitId: _adUnitIds.native,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isNativeLoaded = true;
          _log("Native loaded.");
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isNativeLoaded = false;
          _log("Native failed: $error");
          onFailed?.call(error);
        },
      ),
    );

    _nativeAd!.load();
  }

  NativeAd? get nativeAd => _isNativeLoaded ? _nativeAd : null;

  void disposeNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isNativeLoaded = false;
  }

  // ---------------- Helpers ----------------
  void _showLoadingDialog(BuildContext context, {String? message}) {
    if (!Navigator.of(context).mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(message ?? 'Loading...')),
            ],
          ),
        ),
      ),
    );
  }

  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  static String platformKey() => Platform.isAndroid ? 'android' : 'ios';
}
