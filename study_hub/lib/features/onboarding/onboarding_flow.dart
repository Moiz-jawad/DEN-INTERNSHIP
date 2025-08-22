import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart' as app_state;

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _index = 0;
  BannerAd? _banner;
  InterstitialAd? _interstitial;

  @override
  void initState() {
    super.initState();
    _banner = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      listener: const BannerAdListener(),
      request: const AdRequest(),
    )..load();

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (e) => _interstitial = null,
      ),
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    _interstitial?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    		final appState = context.read<app_state.AppState>();
    appState.setHasSeenOnboarding();
    if (_interstitial != null) {
      _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          context.go('/home/quiz');
        },
        onAdFailedToShowFullScreenContent: (ad, e) {
          ad.dispose();
          context.go('/home/quiz');
        },
      );
      _interstitial!.show();
    } else {
      context.go('/home/quiz');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: const [
                _OnboardPage(
                    title: 'Welcome',
                    description:
                        'Your study companion for quizzes, tasks, and chat.'),
                _OnboardPage(
                    title: 'Features',
                    description:
                        'Practice quizzes, manage tasks, and collaborate.'),
                _OnboardPage(
                    title: 'Privacy & Terms',
                    description:
                        'By continuing you agree to our Privacy Policy and Terms.'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: (_index + 1) / 3),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _next,
                  child: Text(_index < 2 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ),
          if (_banner != null)
            SizedBox(
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String title;
  final String description;
  const _OnboardPage({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
