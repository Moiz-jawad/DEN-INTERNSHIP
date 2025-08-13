import 'dart:io';

class AdUnitIds {
  final String appOpen;
  final String banner;
  final String interstitial;
  final String rewarded;
  final String native;

  const AdUnitIds({
    required this.appOpen,
    required this.banner,
    required this.interstitial,
    required this.rewarded,
    required this.native,
  });

  factory AdUnitIds.fromMap(Map<String, dynamic> data) {
    return AdUnitIds(
      appOpen: data['appOpen'] as String? ?? '',
      banner: data['banner'] as String? ?? '',
      interstitial: data['interstitial'] as String? ?? '',
      rewarded: data['rewarded'] as String? ?? '',
      native: data['native'] as String? ?? '',
    );
  }

  /// Official Google Test IDs (safe for development)
  static AdUnitIds get test {
    if (Platform.isAndroid) {
      return const AdUnitIds(
        appOpen: 'ca-app-pub-6827236307342517/9633358491',
        banner: 'ca-app-pub-6827236307342517/4181705357',
        interstitial: 'ca-app-pub-6827236307342517/9058643424',
        rewarded: 'ca-app-pub-6827236307342517/1802954023',
        native: 'ca-app-pub-6827236307342517/1635464886',
      );
    } else if (Platform.isIOS) {
      return const AdUnitIds(
        appOpen: 'ca-app-pub-3940256099942544/5662855259',
        banner: 'ca-app-pub-3940256099942544/2934735716',
        interstitial: 'ca-app-pub-3940256099942544/4411468910',
        rewarded: 'ca-app-pub-3940256099942544/1712485313',
        native: 'ca-app-pub-3940256099942544/3986624511',
      );
    } else {
      throw UnsupportedError('Ads not supported on this platform');
    }
  }

  /// Production IDs (replace with real values, ideally loaded securely)
  static AdUnitIds get production {
    if (Platform.isAndroid) {
      return const AdUnitIds(
        appOpen: 'ca-app-pub-6827236307342517/9633358491',
        banner: 'ca-app-pub-6827236307342517/4181705357',
        interstitial: 'ca-app-pub-6827236307342517/9058643424',
        rewarded: 'ca-app-pub-6827236307342517/1802954023',
        native: 'ca-app-pub-3940256099942544/3986624511',
      );
    } else if (Platform.isIOS) {
      return const AdUnitIds(
        appOpen: 'YOUR_IOS_APP_OPEN_ID',
        banner: 'YOUR_IOS_BANNER_ID',
        interstitial: 'YOUR_IOS_INTERSTITIAL_ID',
        rewarded: 'YOUR_IOS_REWARDED_ID',
        native: 'YOUR_IOS_NATIVE_ID',
      );
    } else {
      throw UnsupportedError('Ads not supported on this platform');
    }
  }
}
