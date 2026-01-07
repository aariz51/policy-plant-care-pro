// lib/core/widgets/custom_button.dart
import 'package:flutter/material.dart';
import 'package:safemama/core/constants/app_colors.dart'; // Import your app colors

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final Widget? icon; // Optional icon
  final bool isLoading; // To show a loading indicator

  const CustomElevatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.textStyle,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle ?? theme.textTheme.labelLarge?.copyWith(color: AppColors.textOnPrimary);
    final effectiveIconColor = effectiveTextStyle?.color ?? AppColors.textOnPrimary;

    return ElevatedButton(
      style: style ??
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Use your primary color
            foregroundColor: AppColors.textOnPrimary, // Text and icon color on the button
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: effectiveTextStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Or your desired shape
            ),
            minimumSize: const Size(88, 44), // Default minimum size
          ),
      onPressed: isLoading ? null : onPressed, // Disable button when loading
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveIconColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min, // So the button doesn't stretch unnecessarily
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: effectiveIconColor, size: effectiveTextStyle?.fontSize),
                    child: icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    );
  }
}

// You might also want a TextButton variant
class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final TextStyle? textStyle;

  const CustomTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      style: style ??
          TextButton.styleFrom(
            foregroundColor: AppColors.primary, // Text color for text button
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: textStyle ?? theme.textTheme.labelLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}