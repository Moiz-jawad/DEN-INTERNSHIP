// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import '../../services/ad_service.dart';
import '../../widget/banner_ad_widget.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onOnboardingComplete;

  const OnboardingScreen({super.key, this.onOnboardingComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _onboardingPages = [
    OnboardingPageData(
      title: 'Welcome to Social Learning App',
      subtitle: 'Your journey to collaborative learning starts here',
      description:
          'Join a community of learners, take interactive quizzes, manage your tasks, and connect with fellow students.',
      icon: Icons.school,
      color: Colors.blue,
      image: 'assets/images/quiz_bg.jpg',
    ),
    OnboardingPageData(
      title: 'Discover Amazing Features',
      subtitle: 'Everything you need for effective learning',
      description:
          '• Interactive quizzes with real-time feedback\n• Task management and progress tracking\n• Chat with study groups and mentors\n• Personalized learning dashboard',
      icon: Icons.star,
      color: Colors.green,
      image: 'assets/images/quiz_bg-pic.jpg',
    ),
    OnboardingPageData(
      title: 'Privacy & Terms',
      subtitle: 'Your data is safe with us',
      description:
          'We respect your privacy and ensure your data is protected. By continuing, you agree to our Terms of Service and Privacy Policy.',
      icon: Icons.security,
      color: Colors.orange,
      image: 'assets/images/quiz_bg.jpg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      // Show interstitial ad before completing onboarding
      if (AdService.isInterstitialAdReady) {
        print('Showing interstitial ad...');
        await AdService.showInterstitialAd();
      } else {
        print('Interstitial ad not ready, proceeding without ad');
      }

      // Complete onboarding
      await OnboardingService.completeOnboarding();
      if (mounted) {
        // Call the callback to notify parent that onboarding is complete
        // This will trigger AuthWrapper to rebuild and show MainScreen
        widget.onOnboardingComplete?.call();
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing onboarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging for ad status
    print('AdService initialized: ${AdService.isInitialized}');
    print('Banner ad ready: ${AdService.isBannerAdReady}');
    print('Interstitial ad ready: ${AdService.isInterstitialAdReady}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator and skip button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: () => _skipOnboarding(),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Page indicator
                  Row(
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Placeholder for balance
                  const SizedBox(width: 60),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    data: _onboardingPages[index],
                    isLastPage: index == _onboardingPages.length - 1,
                    onNext: _nextPage,
                    onPrevious: _previousPage,
                    onFinish: _finishOnboarding,
                  );
                },
              ),
            ),

            // Banner ad at the bottom
            const BannerAdWidget(
              height: 60,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String image;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.image,
  });
}
