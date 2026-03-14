import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'upload_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const UploadScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.divider.withOpacity(0.7)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.cloud_upload_outlined,
                  activeIcon: Icons.cloud_upload_rounded,
                  label: 'Upload',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentBlue.withOpacity(0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
