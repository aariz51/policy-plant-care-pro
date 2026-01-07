// lib/widgets/responsive_scroll_wrapper.dart
import 'package:flutter/material.dart';

class ResponsiveScrollWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  
  const ResponsiveScrollWrapper({
    Key? key,
    required this.child,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(16.0),
      child: child,
    );
  }
}
