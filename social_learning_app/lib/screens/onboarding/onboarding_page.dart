import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onFinish;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.isLastPage,
    required this.onNext,
    required this.onPrevious,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(data.image),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(data.icon, size: 64, color: data.color),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Content section
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  data.subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  data.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Navigation buttons
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                // Previous button (only show if not first page)
                if (!isLastPage &&
                    data.title != 'Welcome to Social Learning App')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPrevious,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: data.color),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(color: data.color),
                      ),
                    ),
                  ),

                if (!isLastPage &&
                    data.title != 'Welcome to Social Learning App')
                  const SizedBox(width: 16),

                // Next/Finish button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLastPage ? onFinish : onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    child: Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

