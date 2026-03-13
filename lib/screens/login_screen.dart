import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Default password - in production, this should match server
  static const String _correctPassword = 'Mygoalisbe@0265';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn && mounted) {
      _navigateToHome();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final password = _passwordController.text.trim();
    
    if (password.isEmpty) {
      setState(() => _error = 'Please enter password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (password == _correctPassword) {
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      
      if (mounted) {
        _navigateToHome();
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _error = 'Incorrect password';
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentBlue,
                        AppTheme.accentBlueDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'NeuralKB',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Personal AI Knowledge Base',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 48),
                // Password field
                TextField(
                  controller: _passwordController,
                  focusNode: _focusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 24),
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      disabledBackgroundColor: AppTheme.accentBlue.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const Spacer(),
                Text(
                  'NeuralKB may make mistakes',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
