// lib/features/scan/widgets/scan_in_progress_widget.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:safemama/core/theme/app_theme.dart';

class ScanInProgressWidget extends StatefulWidget {
  const ScanInProgressWidget({super.key});

  @override
  State<ScanInProgressWidget> createState() => _ScanInProgressWidgetState();
}

class _ScanInProgressWidgetState extends State<ScanInProgressWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _textTimer;
  int _textIndex = 0;

  final List<String> _loadingMessages = [
    "Identifying your item...",
    "Cross-referencing our safety database...",
    "Checking for allergens and warnings...",
    "Finalizing your personalized report...",
    "Almost there!",
  ];

  @override
  void initState() {
    super.initState();
    
    // This controller will animate from 0.0 to 0.99 over 12 seconds.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // Use a CurvedAnimation to make the progress feel more natural (eases in and out).
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Start the animation.
    _controller.forward();

    // Set up a timer to cycle through the loading messages.
    _textTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_textIndex < _loadingMessages.length - 1) {
        if (mounted) {
          setState(() {
            _textIndex++;
          });
        }
      } else {
        timer.cancel(); // Stop the timer once we've shown all messages.
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The custom animated progress circle.
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  foregroundPainter: ProgressCirclePainter(progress: _animation.value),
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: Center(
                      child: Text(
                        '${(_animation.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // The animated text message.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                _loadingMessages[_textIndex],
                key: ValueKey<int>(_textIndex), // Important for the animation
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This is a custom painter that draws the beautiful progress circle.
class ProgressCirclePainter extends CustomPainter {
  final double progress; // A value from 0.0 to 1.0

  ProgressCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // The background track paint
    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // The progress arc paint with a gradient
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -1.57, // Start at the top
        endAngle: 4.71, // End at the top
        colors: [AppTheme.primaryPurple, AppTheme.accentColor],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Makes the ends of the arc rounded

    // Draw the background track circle
    canvas.drawCircle(center, radius, trackPaint);

    // Draw the progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // Start angle (top)
      progress * 6.28, // Sweep angle (2 * pi)
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}