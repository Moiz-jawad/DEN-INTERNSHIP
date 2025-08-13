import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ad_config.dart';
import '../services/ad_config_service.dart';
import '../services/ad_service.dart';
import '../services/connectivity_service.dart';

// Firebase lazy init and guard
import 'package:firebase_core/firebase_core.dart';

final firebaseInitProvider = FutureProvider<bool>((ref) async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    // Continue in offline/local fallback mode
    return false;
  }
});

final connectivityServiceProvider = Provider((ref) => ConnectivityService());
final networkSpeedProvider = FutureProvider<NetworkSpeed>((ref) async {
  final conn = ref.watch(connectivityServiceProvider);
  return conn.estimateSpeed();
});

final adConfigServiceProvider = Provider((ref) => AdConfigService());

// Provides AdUnitIds loaded from Firebase or falls back to AdMob test IDs.
final adUnitIdsProvider = FutureProvider<AdUnitIds>((ref) async {
  final firebaseReady = await ref.watch(firebaseInitProvider.future);
  final svc = ref.watch(adConfigServiceProvider);
  if (firebaseReady) {
    return svc.fetchAdUnits(platformKey: AdService.platformKey());
  } else {
    return AdUnitIds.test;
  }
});

// Singleton AdService with latest AdUnitIds
final adServiceProvider = Provider<AdService>((ref) {
  // Initialize with test IDs first; update after adUnitIdsProvider resolves
  final service = AdService(AdUnitIds.test);

  // Listen and update when fetched
  ref.listen<AsyncValue<AdUnitIds>>(adUnitIdsProvider, (previous, next) {
    next.whenData((ids) => service.updateAdUnits(ids));
  });

  return service;
});

// Preloaders and flows
final appOpenPreloadProvider = FutureProvider<void>((ref) async {
  final adSvc = ref.read(adServiceProvider);
  await adSvc.loadAppOpenAd();
});

final interstitialPreloadProvider = Provider<void>((ref) {
  final adSvc = ref.read(adServiceProvider);
  adSvc.preloadInterstitial();
  return;
});
