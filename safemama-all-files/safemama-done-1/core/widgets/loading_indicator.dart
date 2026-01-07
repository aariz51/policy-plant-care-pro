import 'package:flutter/material.dart';
import 'package:safemama/core/theme/app_theme.dart';

class LoadingIndicator extends StatefulWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showText;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 40.0,
    this.color,
    this.showText = true,
  }) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    );

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2.0 * 3.14159,
                child: Transform.scale(
                  scale: 0.8 + (_pulseAnimation.value * 0.3),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color ?? AppTheme.primaryPurple,
                          (widget.color ?? AppTheme.primaryPurple).withOpacity(0.3),
                          widget.color ?? AppTheme.accentColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular((widget.size ?? 40) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.color ?? AppTheme.primaryPurple).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.pregnant_woman,
                      color: Colors.white,
                      size: (widget.size ?? 40) * 0.6,
                    ),
                  ),
                ),
              );
            },
          ),
          
          if (widget.showText) ...[
            const SizedBox(height: 24),
            Text(
              widget.message ?? 'Loading...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// Minimal version for smaller spaces
class SimpleLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const SimpleLoadingIndicator({
    Key? key,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size * 0.1,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.primaryPurple,
        ),
      ),
    );
  }
}

// Full screen loading overlay
class FullScreenLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool dismissible;

  const FullScreenLoadingIndicator({
    Key? key,
    this.message,
    this.dismissible = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => dismissible,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.3),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.scaffoldBackground.withOpacity(0.9),
                Colors.white.withOpacity(0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: LoadingIndicator(
                  message: message ?? 'Please wait...',
                  size: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Loading button state
class LoadingButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;

  const LoadingButton({
    Key? key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryPurple,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isLoading ? 0 : 4,
        ),
        child: isLoading
            ? SimpleLoadingIndicator(
                size: 24,
                color: textColor ?? Colors.white,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Shimmer loading effect for content placeholders
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.isLoading = true,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
