import 'dart:ui';
import 'package:ad_mint/screens/reward_screen.dart';
import 'package:ad_mint/screens/screen1.dart';
import 'package:ad_mint/screens/screen2.dart';
import 'package:ad_mint/screens/screen4.dart';
import 'package:ad_mint/screens/screen5.dart';
import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'screen3.dart';

// Example screen mapping function
Widget _getPage(String route) {
  switch (route) {
    case '/screen1':
      return const Screen1();
    case '/screen2':
      return const Screen2();
    case '/screen3':
      return const Screen3();
    case '/screen4':
      return const Screen4();
    case '/screen5':
      return const Screen5();
    case '/rewards':
      return const RewardsScreen();
    default:
      return const Scaffold(body: Center(child: Text('Page not found')));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void _nav(BuildContext ctx, String route) {
    Navigator.of(ctx).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _getPage(route);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          final scale = Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Screen 1', '/screen1', Icons.filter_1_outlined),
      ('Screen 2', '/screen2', Icons.filter_2_outlined),
      ('Screen 3', '/screen3', Icons.filter_3_outlined),
      ('Screen 4', '/screen4', Icons.filter_4_outlined),
      ('Screen 5', '/screen5', Icons.filter_5_outlined),
      ('Rewards', '/rewards', Icons.card_giftcard_outlined),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Home'),
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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final (title, route, icon) = items[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        leading: Icon(icon, color: Colors.black87),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.black45,
                        ),
                        onTap: () => _nav(ctx, route),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
