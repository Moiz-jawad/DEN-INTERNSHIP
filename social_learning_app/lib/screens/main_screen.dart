import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'quiz/home_screen.dart';
import 'task/tasks_screen.dart';
import 'chat/real_time_chat_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const RealTimeChatScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.quiz, label: 'Quiz', isActive: true),
    NavigationItem(icon: Icons.task, label: 'Tasks', isActive: false),
    NavigationItem(icon: Icons.chat, label: 'Chat', isActive: false),
    NavigationItem(icon: Icons.person, label: 'Profile', isActive: false),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize app state after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.initializeUserApp(); // Use user-specific initialization
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      // Update active states
      for (int i = 0; i < _navigationItems.length; i++) {
        _navigationItems[i].isActive = i == index;
      }
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _navigationItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = index == _currentIndex;

            return GestureDetector(
              onTap: () => _onTabTapped(index),
              child: SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Orange circular background for active item
                    if (isActive)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 174, 170, 238),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),

                    // Icon with animation
                    AnimatedScale(
                      scale: isActive ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        item.icon,
                        size: 28,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  bool isActive;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });
}
