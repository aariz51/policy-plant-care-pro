// lib/core/widgets/rich_animated_loading_widget.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; // For PathMetric

import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // No longer needed
import 'package:safemama/core/constants/app_colors.dart'; // Your app colors
// import 'package:safemama/l10n/app_localizations.dart'; // Not used directly in this widget

class RichAnimatedLoadingWidget extends StatefulWidget {
  final List<String> loadingTexts;
  final String initialText;

  const RichAnimatedLoadingWidget({
    super.key,
    required this.loadingTexts,
    required this.initialText,
  });

  @override
  State<RichAnimatedLoadingWidget> createState() => _RichAnimatedLoadingWidgetState();
}

class _RichAnimatedLoadingWidgetState extends State<RichAnimatedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _heartScaleController;
  late Animation<double> _heartScaleAnimation;

  // EKG Animation
  late AnimationController _ekgSweepController; // Controls the sweep progress 0.0 to 1.0
  late AnimationController _ekgPulseController; // Controls individual pulse opacity/intensity

  Timer? _textChangeTimer;
  int _currentTextIndex = 0;
  late List<String> _actualLoadingTexts;

  // Gradient Colors
  final Color _gradientColor1 = const Color(0xFFF8EBFD);
  final Color _gradientColor2 = const Color(0xFFFDF0E6);
  final Color _gradientColor3 = const Color(0xFFE4E6FC);
  
  late Color _primaryAppColor;
  late Color _textAppColor;
  final double _silhouetteOpacity = 0.15;
  late final Color _silhouetteColor;

  @override
  void initState() {
    super.initState();
    _actualLoadingTexts = widget.loadingTexts.isNotEmpty ? widget.loadingTexts : [widget.initialText];
    if (_actualLoadingTexts.isEmpty) _actualLoadingTexts = ["Loading..."];
    _currentTextIndex = 0;

    _primaryAppColor = AppColors.primary; // Initialize here for painter
    _textAppColor = AppColors.textDarkPurple; // Initialize here
    _silhouetteColor = _primaryAppColor.withOpacity(0.1);

    _heartScaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartScaleController, curve: Curves.easeInOut));

    // EKG Sweep Animation (controls how much of the line is "active")
    _ekgSweepController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1, milliseconds: 600)) // How long one full sweep takes
      ..addListener(() { setState(() {}); }) // Repaint on EKG sweep
      ..repeat();

    // EKG Pulse Animation (controls the "blip" intensity/opacity)
    _ekgPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400)) // Faster pulse for the blip
      ..repeat(reverse: true);

    if (_actualLoadingTexts.length > 1) {
      _startTextAnimation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Colors are already initialized from initState or can be from widget params if needed
  }

  void _startTextAnimation() {
    _textChangeTimer?.cancel();
    _textChangeTimer = Timer.periodic(const Duration(seconds: 2, milliseconds: 300), (timer) {
      if (!mounted || _actualLoadingTexts.length <= 1) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % _actualLoadingTexts.length;
      });
    });
  }

  @override
  void dispose() {
    _heartScaleController.dispose();
    _ekgSweepController.dispose();
    _ekgPulseController.dispose();
    _textChangeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    String currentTextToShow = _actualLoadingTexts.isNotEmpty
        ? _actualLoadingTexts[_currentTextIndex % _actualLoadingTexts.length]
        : "Loading...";

    return Scaffold( // Make RichAnimatedLoadingWidget a Scaffold itself
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientColor1, _gradientColor2, _gradientColor3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack( // Use Stack for background elements
          children: [
            // --- Abstract Silhouette (Coded - VERY SIMPLIFIED) ---
            Positioned(
              right: -screenWidth * 0.15, // Adjust positioning
              bottom: screenHeight * 0.05,
              height: screenHeight * 0.6,
              width: screenWidth * 0.6,
              child: Opacity(
                opacity: _silhouetteOpacity,
                child: CustomPaint(
                  painter: AbstractSilhouettePainter(color: _silhouetteColor),
                ),
              ),
            ),
            // --- Abstract Leafy Accent (Coded - VERY SIMPLIFIED) ---
            Positioned(
              left: -screenWidth * 0.1,
              top: screenHeight * 0.1,
              height: screenHeight * 0.5,
              width: screenWidth * 0.4,
              child: Opacity(
                opacity: 0.08, // More subtle
                child: CustomPaint(
                  painter: AbstractLeafPainter(color: _primaryAppColor.withOpacity(0.4)),
                ),
              ),
            ),
            // --- Main Centered Content ---
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "SafeMama",
                       style: TextStyle(fontSize: screenWidth * 0.1, fontWeight: FontWeight.bold, color: _textAppColor),
                    ),
                    SizedBox(height: screenHeight * 0.08),
                    ScaleTransition(
                      scale: _heartScaleAnimation, // Main heart pulse
                      child: SizedBox(
                        width: screenWidth * 0.3, // Container for heart
                        height: screenWidth * 0.3,
                        child: CustomPaint(
                          painter: HeartEKGPainter(
                            color: _primaryAppColor,
                            ekgSweepAnimation: _ekgSweepController, // Pass sweep animation
                            ekgPulseAnimation: _ekgPulseController, // Pass pulse animation
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.06),
                    AnimatedSwitcher(
                       duration: const Duration(milliseconds: 700),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                              child: child));
                        },
                        child: Text(
                          currentTextToShow,
                          key: ValueKey<int>(_currentTextIndex),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _textAppColor.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                        ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            _actualLoadingTexts.isNotEmpty ? _actualLoadingTexts.length : 1, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350), curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0), height: 9.0,
                            width: _currentTextIndex == index ? 25.0 : 9.0,
                            decoration: BoxDecoration(
                              color: _currentTextIndex == index ? _primaryAppColor : _primaryAppColor.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(5.0),),);
                        }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- UPDATED CustomPainter for the Heart and EKG Line ---
class HeartEKGPainter extends CustomPainter {
  final Color color;
  final Animation<double> ekgSweepAnimation; // Value from 0.0 to 1.0, repeats
  final Animation<double> ekgPulseAnimation; // Value from 0.0 to 1.0, repeats and reverses (for intensity)

  HeartEKGPainter({
    required this.color,
    required this.ekgSweepAnimation,
    required this.ekgPulseAnimation,
  }) : super(repaint: Listenable.merge([ekgSweepAnimation, ekgPulseAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final Paint heartPaint = Paint()..color = color..style = PaintingStyle.fill;
    final Paint ekgLinePaint = Paint()
      ..color = Colors.white // EKG line color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045 // Slightly thicker for visibility
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw Main Heart Shape
    Path mainHeartPath = Path();
    mainHeartPath.moveTo(size.width / 2, size.height * 0.25);
    mainHeartPath.cubicTo(size.width * 0.1, size.height * 0.05, -size.width * 0.15, size.height * 0.5, size.width / 2, size.height * 0.85);
    mainHeartPath.cubicTo(size.width * 1.15, size.height * 0.5, size.width * 0.8, size.height * 0.05, size.width / 2, size.height * 0.25);
    canvas.drawPath(mainHeartPath, heartPaint);

    // --- EKG Line Animation: Simulating a moving trace with varying intensity ---
    double lineY = size.height * 0.52; // Center the EKG line a bit better
    double startX = size.width * 0.15;
    double endX = size.width * 0.85;
    double graphWidth = endX - startX;

    // Define the EKG wave points relative to startX and graphWidth
    // (x_factor from 0 to 1, y_factor relative to center lineY, positive is down)
    List<Offset> wavePoints = [
      const Offset(0.0, 0.0),         // Start flat
      const Offset(0.1, 0.0),         // P wave start
      Offset(0.15, -0.06 * size.height), // P up
      const Offset(0.20, 0.0),        // P down
      const Offset(0.25, 0.0),        // Isoelectric
      Offset(0.28, 0.05 * size.height),  // Q
      Offset(0.38, -0.20 * size.height), // R peak
      Offset(0.48, 0.15 * size.height),  // S
      const Offset(0.55, 0.0),        // Back to baseline
      const Offset(0.65, 0.0),        // T wave start
      Offset(0.70, -0.08 * size.height),// T up
      const Offset(0.75, 0.0),        // T down
      const Offset(1.0, 0.0),         // End flat
    ];

    Path ekgTracePath = Path();
    ekgTracePath.moveTo(startX, lineY);

    for (int i = 0; i < wavePoints.length; i++) {
      ekgTracePath.lineTo(startX + wavePoints[i].dx * graphWidth, lineY + wavePoints[i].dy);
    }

    // Create a "window" or "highlight" that moves along the EKG path
    // Need to handle the case where ekgTracePath might be empty or too short
    var metrics = ekgTracePath.computeMetrics().toList();
    if (metrics.isEmpty) return; // Cannot do anything if there are no metrics

    PathMetric pathMetric = metrics.first;
    double totalLength = pathMetric.length;
    
    if (totalLength == 0) return; // Cannot extract if path has no length

    // Current sweep position along the path (0.0 to 1.0 of totalLength)
    double sweepPos = totalLength * ekgSweepAnimation.value;
    
    // Length of the visible "active" segment of the EKG line
    double activeSegmentLength = graphWidth * 0.3; // Make the bright segment a bit longer

    // Calculate start and end of the visible segment
    double visibleStart = math.max(0, sweepPos - activeSegmentLength);
    double visibleEnd = math.min(totalLength, sweepPos);

    if (visibleEnd > visibleStart) {
      Path segmentToDraw = pathMetric.extractPath(visibleStart, visibleEnd);
      
      // Use ekgPulseAnimation to make the line "glow" or appear brighter
      // The pulse animation goes 0 -> 1 -> 0. We map this to opacity or stroke width.
      double pulseIntensity = 0.6 + (ekgPulseAnimation.value * 0.4); // Varies between 0.6 and 1.0

      ekgLinePaint.color = Colors.white.withOpacity(pulseIntensity);
      ekgLinePaint.strokeWidth = size.width * 0.045 * (0.8 + pulseIntensity * 0.4); // Slightly thicker when intense

      canvas.drawPath(segmentToDraw, ekgLinePaint);
    }
  }

  @override
  bool shouldRepaint(HeartEKGPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.ekgSweepAnimation.value != ekgSweepAnimation.value ||
           oldDelegate.ekgPulseAnimation.value != ekgPulseAnimation.value;
  }
}

// --- Abstract Painters (Keep as is, or refine if desired) ---
class AbstractSilhouettePainter extends CustomPainter {
  final Color color; AbstractSilhouettePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color; Path path = Path();
    path.moveTo(size.width * 0.6, size.height * 0.1); 
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.2, size.width * 0.7, size.height * 0.4); 
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.5, size.width * 0.65, size.height * 0.6); 
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width * 0.5, size.height * 0.95); 
    path.lineTo(size.width * 0.3, size.height); 
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.7, size.width * 0.2, size.height * 0.6); 
    path.quadraticBezierTo(size.width * 0.05, size.height * 0.45, size.width * 0.4, size.height * 0.2); 
    path.close(); canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AbstractLeafPainter extends CustomPainter {
  final Color color; AbstractLeafPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color; Path path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.3, size.width * 0.5, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.3, size.width * 0.5, size.height * 0.1);
    path.close(); canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}