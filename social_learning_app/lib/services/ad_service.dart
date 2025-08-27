// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/ad_config.dart';

class AdService {
  AdService(this._adUnitIds);

  AdUnitIds _adUnitIds;

  // Static instance for easy access
  static AdService? _instance;
  static bool _isInitialized = false;

  // Factory constructor to get singleton instance
  factory AdService.instance() {
    // Use test ads by default for development
    _instance ??= AdService(AdUnitIds.test);
    return _instance!;
  }

  // Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Starting Mobile Ads SDK initialization...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      print('Mobile Ads SDK initialized successfully');

      // Initialize the instance if not already done
      _instance ??= AdService(AdUnitIds.test);

      // Start preloading ads
      _instance!.preloadInterstitial();
      _instance!.loadAppOpenAd();
    } catch (e) {
      print('Failed to initialize Mobile Ads SDK: $e');
      _isInitialized = false;
    }
  }

  // Static getters for backward compatibility
  static bool get isInitialized => _isInitialized;
  static bool get isInterstitialAdReady => _instance?._interstitialAd != null;
  static bool get isBannerAdReady => true; // Banner ads are created on-demand

  // Static method for banner ads (backward compatibility)
  static Widget getBannerAd() {
    if (!_isInitialized) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50,
        color: Colors.grey[200],
        child: const Text(
          'Ad Service Not Ready',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: 50,
      child: const Text(
        'Banner Ad Ready',
        style: TextStyle(color: Colors.green),
      ),
    );
  }

  // Static method for interstitial ads (backward compatibility)
  static Future<bool> showInterstitialAd() async {
    if (!_isInitialized || _instance == null) return false;

    try {
      // Show interstitial without blocking the UI
      if (_instance!._interstitialAd != null) {
        print('Showing interstitial ad...');
        _instance!._interstitialAd!.show();
        return true;
      } else {
        print('Interstitial ad not ready');
        return false;
      }
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }

  // Helper to get current context (you'll need to implement this)
  static BuildContext _getCurrentContext() {
    // This is a placeholder - you'll need to pass context from your UI
    throw UnimplementedError('Context must be passed from UI layer');
  }

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
      print('Loading app open ad...');
      await AppOpenAd.load(
        adUnitId: _adUnitIds.appOpen,
        orientation: 1, // Portrait orientation
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _loadingAppOpen = false;
            print("App Open Ad loaded successfully.");
          },
          onAdFailedToLoad: (error) {
            _appOpenAd = null;
            _loadingAppOpen = false;
            print("App Open Ad failed to load: $error");
            // Don't retry app open ads if they fail
          },
        ),
      );
    } catch (e) {
      _loadingAppOpen = false;
      print("App Open load exception: $e");
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
    print('Preloading interstitial ad...');
    InterstitialAd.load(
      adUnitId: _adUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print("Interstitial loaded successfully.");

          // Set up callbacks for the loaded ad
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print("Interstitial ad dismissed");
              _disposeInterstitial(ad);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print("Interstitial failed to show: $error");
              _disposeInterstitial(ad);
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          print("Interstitial failed to load: $error");
          // Retry after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (_isInitialized) {
              preloadInterstitial();
            }
          });
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
    try {
      final width = MediaQuery.of(context).size.width.truncate();
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      if (size == null) {
        print('Cannot get banner size for width: $width');
        return null;
      }

      print('Creating banner ad with size: $size');
      final bannerAd = BannerAd(
        size: size,
        adUnitId: _adUnitIds.banner,
        request: request,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('Banner ad loaded successfully');
          },
          onAdFailedToLoad: (ad, error) {
            print('Banner failed to load: $error');
            ad.dispose();
          },
        ),
      );

      return bannerAd;
    } catch (e) {
      print('Error creating banner ad: $e');
      return null;
    }
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
