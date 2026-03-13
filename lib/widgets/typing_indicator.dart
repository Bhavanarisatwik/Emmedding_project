import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 16,
            color: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        // Typing dots
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.aiBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final progress = (_controller.value + index * 0.2) % 1.0;
                  final opacity = (progress < 0.5) 
                      ? progress * 2 
                      : 2 - progress * 2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(opacity.clamp(0.3, 1.0)),
                      shape: BoxShape.circle,
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
