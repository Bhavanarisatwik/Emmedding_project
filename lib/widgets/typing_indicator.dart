import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with pulse glow
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(_pulseAnimation.value),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: const Icon(
            Icons.auto_awesome,
            size: 16,
            color: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 12),

        // Typing dots bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.aiBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: AppTheme.accentBlue.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  // Stagger each dot by 0.2 of the cycle
                  final raw = (_bounceController.value - index * 0.22) % 1.0;
                  // Sine-based bounce: peaks at raw=0.5
                  final bounce = raw < 0.5
                      ? raw * 2
                      : 2.0 - raw * 2;
                  final opacity = (0.3 + bounce * 0.7).clamp(0.3, 1.0);
                  final yOffset = -(bounce * 4.0);

                  return Transform.translate(
                    offset: Offset(0, yOffset),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
