import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../provider/ad_providers.dart';
import '../widgets/banner_ad_widget.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  int coins = 0;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    _preloadAd();
  }

  void _preloadAd() {
    setState(() => _isLoadingAd = true);
    ref
        .read(adServiceProvider)
        .loadRewarded(
          onLoaded: () {
            if (mounted) setState(() => _isLoadingAd = false);
          },
        );
  }

  Future<void> _watchAd() async {
    final adSvc = ref.read(adServiceProvider);

    if (_isLoadingAd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad is still loading, please wait...')),
      );
      return;
    }

    await adSvc.showRewarded(
      context: context,
      onRewarded: (RewardItem reward) {
        setState(() => coins += reward.amount.toInt());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You earned ${reward.amount} coins!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _preloadAd(); // Preload next ad

        // Auto-navigate to Screen 3
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacementNamed('/screen3');
        });
      },
      onFailed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad failed to load, try again later.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Rewards'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D83F2), Color(0xFF8FA9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.card_giftcard_outlined,
                        size: 80,
                        color: Color(0xFF6D83F2),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Coins: $coins',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _watchAd,
                        icon: _isLoadingAd
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_circle_outline),
                        label: Text(
                          _isLoadingAd
                              ? 'Loading Ad...'
                              : 'Watch Ad to Earn Coins',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
