import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

enum NetworkSpeed { unknown, slow, normal, fast }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream to listen for connectivity changes (takes the first result in the list).
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) =>
            results.isNotEmpty ? results.first : ConnectivityResult.none,
      );

  /// Checks the current connectivity status (takes the first result in the list).
  Future<ConnectivityResult> check() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty ? results.first : ConnectivityResult.none;
  }

  /// Estimates network speed by making a quick HTTP request.
  Future<NetworkSpeed> estimateSpeed({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final Uri uri = Uri.parse('https://www.google.com/generate_204');
      final Stopwatch stopwatch = Stopwatch()..start();

      final http.Response resp = await http.get(uri).timeout(timeout);
      stopwatch.stop();

      if (resp.statusCode >= 200 && resp.statusCode < 400) {
        final int ms = max(stopwatch.elapsedMilliseconds, 1);

        if (ms < 150) return NetworkSpeed.fast;
        if (ms < 500) return NetworkSpeed.normal;
        return NetworkSpeed.slow;
      }
      return NetworkSpeed.unknown;
    } catch (_) {
      return NetworkSpeed.unknown;
    }
  }
}
