import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'reward_screen.dart';

class Screen2 extends StatefulWidget {
  const Screen2({super.key});

  @override
  State<Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  bool _rewardShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_rewardShown) {
      _rewardShown = true;
      // Show reward screen after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRewardScreen();
      });
    }
  }

  void _showRewardScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const RewardsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen 2')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/screen3'),
                icon: const Icon(Icons.navigate_next),
                label: const Text('Go to Screen 3'),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
