class AdUnitIds {
  final String banner;
  final String interstitial;
  final String rewarded;
  final String appOpen;
  final String native;

  const AdUnitIds({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
    required this.appOpen,
    required this.native,
  });

  // Production ad unit IDs
  static const AdUnitIds production = AdUnitIds(
    banner: 'ca-app-pub-6827236307342517/3204401696',
    interstitial: 'ca-app-pub-6827236307342517/5414782008',
    rewarded:
        'ca-app-pub-6827236307342517/4181705357', // Use banner ID as placeholder
    appOpen:
        'ca-app-pub-6827236307342517/4181705357', // Use banner ID as placeholder
    native:
        'ca-app-pub-6827236307342517/4181705357', // Use banner ID as placeholder
  );

  // Test ad unit IDs for development
  static const AdUnitIds test = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
    appOpen: 'ca-app-pub-3940256099942544/3419835294',
    native: 'ca-app-pub-3940256099942544/2247696110',
  );
}
