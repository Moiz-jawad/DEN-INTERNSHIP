import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/ad_config.dart';

class AdConfigService {
  /// Fetches ad IDs from Firebase Realtime Database with a safe timeout.
  /// RTDB Structure:
  /// ad_units/
  ///   android: { appOpen, banner, interstitial, rewarded }
  ///   ios:     { appOpen, banner, interstitial, rewarded }
  Future<AdUnitIds> fetchAdUnits({
    required String platformKey, // 'android' or 'ios'
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final ref = FirebaseDatabase.instance.ref('ad_units/$platformKey');
      final snap = await ref.get().timeout(timeout);

      if (snap.exists && snap.value is Map) {
        final raw = snap.value as Map;
        final map = raw.map((key, value) => MapEntry(key.toString(), value));
        return AdUnitIds.fromMap(map);
      }

      // Fallback to test IDs if no data in RTDB
      return AdUnitIds.test;
    } on Exception {
      // Fallback to test IDs if RTDB unavailable or offline
      return AdUnitIds.test;
    }
  }
}
