import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedModel = 'kimi-k2.5';

  final List<Map<String, String>> _models = [
    {'id': 'kimi-k2.5', 'name': 'Kimi K2.5', 'desc': 'Fastest responses'},
    {'id': 'glm-5', 'name': 'GLM-5', 'desc': 'Balanced performance'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedModel = prefs.getString('selected_model') ?? 'kimi-k2.5';
    });
  }

  Future<void> _saveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_model', model);
    setState(() => _selectedModel = model);
    HapticFeedback.selectionClick();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model selection
          _buildSection(
            title: 'AI Model',
            children: [
              ..._models.map((model) => _buildModelOption(model)),
            ],
          ),
          const SizedBox(height: 24),

          // Account section
          _buildSection(
            title: 'Account',
            children: [
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Log out of your account',
                onTap: _logout,
                color: AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About section
          _buildSection(
            title: 'About',
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'NeuralKB',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.code,
                title: 'Built with Flutter',
                subtitle: 'Powered by Gemini Embeddings',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Footer
          Center(
            child: Text(
              'NeuralKB may make mistakes.\nAlways verify important information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildModelOption(Map<String, String> model) {
    final isSelected = _selectedModel == model['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _saveModel(model['id']!),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentBlue.withOpacity(0.1)
                      : AppTheme.surfaceLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model['name']!,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      model['desc']!,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentBlue,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? AppTheme.accentBlue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color ?? AppTheme.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color ?? AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
